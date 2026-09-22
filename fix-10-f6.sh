#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/modules/conciliacao/dto
mkdir -p src/modules/conciliacao/parsers
mkdir -p src/modules/conciliacao/services
mkdir -p src/modules/conciliacao/testes
mkdir -p src/modules/contas-bancarias/dto

# ============================================================
# 1. PARSER OFX
# ============================================================
cat > src/modules/conciliacao/parsers/ofx.parser.ts <<'OFX_EOF'
import { createHash } from 'crypto';

export interface TransacaoOfx {
  dataMovimento: Date;
  descricao: string;
  documento?: string;
  valor: number;
  tipo: 'D' | 'C';
  hash: string;
}

export interface ExtratoOfx {
  bancoCodigo?: string;
  contaId?: string;
  agencia?: string;
  conta?: string;
  saldoInicial?: number;
  saldoFinal?: number;
  periodoInicio?: Date;
  periodoFim?: Date;
  transacoes: TransacaoOfx[];
}

export class OfxParserError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'OfxParserError';
  }
}

/**
 * Parser OFX (SGML/XML híbrido usado pelos bancos brasileiros).
 * Suporta OFX 1.x (SGML) e OFX 2.x (XML).
 */
export class OfxParser {
  parse(conteudo: string): ExtratoOfx {
    if (!conteudo || conteudo.trim().length < 20) {
      throw new OfxParserError('Arquivo OFX vazio ou muito pequeno');
    }

    // Normalizar quebras de linha
    const texto = conteudo.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    // Detectar banco e conta
    const bancoCodigo = this.extrairTag(texto, 'BANKID');
    const contaId = this.extrairTag(texto, 'ACCTID');
    const agencia = this.extrairTag(texto, 'BRANCHID');

    // Saldos
    const saldoInicial = this.extrairValor(texto, 'BALAMT', 1);
    const saldoFinal = this.extrairValor(texto, 'BALAMT', 2);

    // Período
    const dtInicio = this.extrairTag(texto, 'DTSTART');
    const dtFim = this.extrairTag(texto, 'DTEND');

    // Extrair blocos de transações <STMTTRN>...</STMTTRN>
    const transacoes: TransacaoOfx[] = [];
    const regex = /<STMTTRN>([\s\S]*?)<\/STMTTRN>/gi;
    let match: RegExpExecArray | null;

    while ((match = regex.exec(texto)) !== null) {
      const bloco = match[1];
      try {
        transacoes.push(this.parseTransacao(bloco));
      } catch {
        // Ignora transações malformadas
        continue;
      }
    }

    if (transacoes.length === 0) {
      throw new OfxParserError('Nenhuma transação encontrada no arquivo OFX');
    }

    return {
      bancoCodigo,
      contaId,
      agencia,
      saldoInicial,
      saldoFinal,
      periodoInicio: dtInicio ? this.parseDataOfx(dtInicio) : undefined,
      periodoFim: dtFim ? this.parseDataOfx(dtFim) : undefined,
      transacoes,
    };
  }

  private parseTransacao(bloco: string): TransacaoOfx {
    const tipoRaw = this.extrairTag(bloco, 'TRNTYPE') ?? 'DEBIT';
    const dataRaw = this.extrairTag(bloco, 'DTPOSTED');
    const valorRaw = this.extrairTag(bloco, 'TRNAMT');
    const descricao = this.extrairTag(bloco, 'MEMO') ?? this.extrairTag(bloco, 'NAME') ?? '';
    const documento = this.extrairTag(bloco, 'CHECKNUM') ?? this.extrairTag(bloco, 'REFNUM');

    if (!dataRaw || !valorRaw) {
      throw new OfxParserError('Transação OFX sem data ou valor');
    }

    const valor = parseFloat(valorRaw.replace(',', '.'));
    if (isNaN(valor)) {
      throw new OfxParserError(`Valor inválido: ${valorRaw}`);
    }

    const tipo: 'D' | 'C' = valor >= 0 ? 'C' : 'D';
    const dataMovimento = this.parseDataOfx(dataRaw);

    const hash = this.gerarHash({
      data: dataMovimento.toISOString().slice(0, 10),
      valor: Math.abs(valor).toFixed(2),
      descricao: descricao.trim(),
      documento: documento ?? '',
    });

    return {
      dataMovimento,
      descricao: descricao.trim(),
      documento,
      valor: Math.abs(valor),
      tipo,
      hash,
    };
  }

  private extrairTag(texto: string, tag: string): string | undefined {
    // OFX 1.x: <TAG>valor (sem fechamento)
    // OFX 2.x: <TAG>valor</TAG>
    const regex = new RegExp(`<${tag}>([^<\\n]+)`, 'i');
    const match = regex.exec(texto);
    return match ? match[1].trim() : undefined;
  }

  private extrairValor(texto: string, tag: string, ocorrencia: number): number | undefined {
    const regex = new RegExp(`<${tag}>([^<\\n]+)`, 'gi');
    let match: RegExpExecArray | null;
    let count = 0;
    while ((match = regex.exec(texto)) !== null) {
      count++;
      if (count === ocorrencia) {
        const valor = parseFloat(match[1].replace(',', '.'));
        return isNaN(valor) ? undefined : valor;
      }
    }
    return undefined;
  }

  private parseDataOfx(raw: string): Date {
    // Formato: YYYYMMDDHHMMSS[.XXX][-03:BRT]
    const limpo = raw.replace(/\[.*\]/, '').trim();
    const ano = parseInt(limpo.slice(0, 4), 10);
    const mes = parseInt(limpo.slice(4, 6), 10) - 1;
    const dia = parseInt(limpo.slice(6, 8), 10);
    return new Date(ano, mes, dia);
  }

  private gerarHash(dados: Record<string, string>): string {
    const conteudo = Object.values(dados).join('|');
    return createHash('sha256').update(conteudo).digest('hex');
  }
}
OFX_EOF

# ============================================================
# 2. PARSER CSV
# ============================================================
cat > src/modules/conciliacao/parsers/csv.parser.ts <<'CSV_EOF'
import { createHash } from 'crypto';

export interface MapeamentoCsv {
  separador?: string;
  data: string;
  descricao: string;
  valor: string;
  documento?: string;
  formatoData?: 'DD/MM/YYYY' | 'YYYY-MM-DD' | 'DD-MM-YYYY';
  decimalVirgula?: boolean;
  linhaCabecalho?: number;
}

export interface TransacaoCsv {
  dataMovimento: Date;
  descricao: string;
  documento?: string;
  valor: number;
  tipo: 'D' | 'C';
  hash: string;
}

export class CsvParserError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CsvParserError';
  }
}

export class CsvParser {
  parse(conteudo: string, mapeamento: MapeamentoCsv): TransacaoCsv[] {
    if (!conteudo) throw new CsvParserError('Arquivo vazio');

    const sep = mapeamento.separador ?? this.detectarSeparador(conteudo);
    const linhas = conteudo.split(/\r?\n/).filter((l) => l.trim().length > 0);

    if (linhas.length < 2) {
      throw new CsvParserError('CSV precisa ter cabeçalho + pelo menos 1 linha');
    }

    const linhaCabecalho = mapeamento.linhaCabecalho ?? 0;
    const header = this.parseLinha(linhas[linhaCabecalho], sep);
    const idxData = this.indiceColuna(header, mapeamento.data);
    const idxDesc = this.indiceColuna(header, mapeamento.descricao);
    const idxVal = this.indiceColuna(header, mapeamento.valor);
    const idxDoc = mapeamento.documento
      ? this.indiceColunaOpcional(header, mapeamento.documento)
      : -1;

    if (idxData === -1) throw new CsvParserError(`Coluna "${mapeamento.data}" não encontrada`);
    if (idxDesc === -1) throw new CsvParserError(`Coluna "${mapeamento.descricao}" não encontrada`);
    if (idxVal === -1) throw new CsvParserError(`Coluna "${mapeamento.valor}" não encontrada`);

    const transacoes: TransacaoCsv[] = [];

    for (let i = linhaCabecalho + 1; i < linhas.length; i++) {
      const linha = linhas[i];
      try {
        const cols = this.parseLinha(linha, sep);
        if (cols.length < Math.max(idxData, idxDesc, idxVal) + 1) continue;

        const dataMovimento = this.parseData(cols[idxData], mapeamento.formatoData);
        const descricao = cols[idxDesc].trim();
        const valorStr = cols[idxVal].trim();
        const valor = this.parseValor(valorStr, mapeamento.decimalVirgula);

        if (isNaN(valor) || !descricao) continue;

        const tipo: 'D' | 'C' = valor >= 0 ? 'C' : 'D';
        const documento = idxDoc >= 0 ? cols[idxDoc]?.trim() : undefined;

        const hash = createHash('sha256')
          .update(`${dataMovimento.toISOString().slice(0, 10)}|${Math.abs(valor).toFixed(2)}|${descricao}|${documento ?? ''}`)
          .digest('hex');

        transacoes.push({
          dataMovimento,
          descricao,
          documento,
          valor: Math.abs(valor),
          tipo,
          hash,
        });
      } catch {
        continue;
      }
    }

    if (transacoes.length === 0) {
      throw new CsvParserError('Nenhuma transação válida encontrada no CSV');
    }

    return transacoes;
  }

  private detectarSeparador(conteudo: string): string {
    const primeiraLinha = conteudo.split(/\r?\n/)[0] ?? '';
    const contagem = {
      ',': (primeiraLinha.match(/,/g) ?? []).length,
      ';': (primeiraLinha.match(/;/g) ?? []).length,
      '\t': (primeiraLinha.match(/\t/g) ?? []).length,
    };
    return Object.entries(contagem).sort((a, b) => b[1] - a[1])[0][0];
  }

  private parseLinha(linha: string, sep: string): string[] {
    // Parser simples — não trata aspas com separador interno
    return linha.split(sep).map((c) => c.replace(/^"|"$/g, '').trim());
  }

  private indiceColuna(header: string[], nome: string): number {
    const idx = header.findIndex(
      (h) => h.toLowerCase() === nome.toLowerCase() || h.toLowerCase().includes(nome.toLowerCase()),
    );
    return idx;
  }

  private indiceColunaOpcional(header: string[], nome: string): number {
    return this.indiceColuna(header, nome);
  }

  private parseData(raw: string, formato?: MapeamentoCsv['formatoData']): Date {
    const limpo = raw.trim().split(' ')[0]; // remove hora se houver

    if (formato === 'YYYY-MM-DD') {
      const [a, m, d] = limpo.split('-').map(Number);
      return new Date(a, m - 1, d);
    }

    if (formato === 'DD-MM-YYYY') {
      const [d, m, a] = limpo.split('-').map(Number);
      return new Date(a, m - 1, d);
    }

    // Padrão: DD/MM/YYYY
    const [d, m, a] = limpo.split('/').map(Number);
    if (isNaN(d) || isNaN(m) || isNaN(a)) {
      // Tentar ISO
      const iso = new Date(limpo);
      if (!isNaN(iso.getTime())) return iso;
      throw new CsvParserError(`Data inválida: ${raw}`);
    }
    return new Date(a, m - 1, d);
  }

  private parseValor(raw: string, decimalVirgula?: boolean): number {
    let limpo = raw.replace(/[R$\s]/g, '').trim();

    if (decimalVirgula !== false) {
      // Formato brasileiro: 1.234,56 → 1234.56
      if (limpo.includes(',')) {
        limpo = limpo.replace(/\./g, '').replace(',', '.');
      }
    }

    // Tratar parênteses como negativo (alguns bancos usam)
    const negativo = limpo.startsWith('(') && limpo.endsWith(')');
    limpo = limpo.replace(/[()]/g, '');

    const valor = parseFloat(limpo);
    return negativo ? -valor : valor;
  }
}
CSV_EOF

# ============================================================
# 3. DTOs — CONTAS BANCÁRIAS
# ============================================================
cat > src/modules/contas-bancarias/dto/create-conta-bancaria.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export enum TipoContaBancariaEnum {
  CORRENTE = 'CORRENTE',
  POUPANCA = 'POUPANCA',
  INVESTIMENTO = 'INVESTIMENTO',
}

export class CreateContaBancariaDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Código COMPE do banco (ex: 341)' })
  @IsString()
  @MaxLength(10)
  bancoCodigo: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(20)
  agencia?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(30)
  numeroConta?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(5)
  digito?: string;

  @ApiPropertyOptional({ enum: TipoContaBancariaEnum, default: 'CORRENTE' })
  @IsOptional()
  @IsEnum(TipoContaBancariaEnum)
  tipo?: TipoContaBancariaEnum;

  @ApiPropertyOptional({ description: 'ID da conta contábil vinculada' })
  @IsOptional()
  @IsUUID()
  contaContabilId?: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  saldoInicial?: number;
}
DTO_EOF

cat > src/modules/contas-bancarias/dto/update-conta-bancaria.dto.ts <<'DTO_EOF'
import { PartialType } from '@nestjs/swagger';
import { CreateContaBancariaDto } from './create-conta-bancaria.dto';

export class UpdateContaBancariaDto extends PartialType(CreateContaBancariaDto) {}
DTO_EOF

# ============================================================
# 4. DTOs — CONCILIAÇÃO
# ============================================================
cat > src/modules/conciliacao/dto/importar-ofx.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID, MinLength } from 'class-validator';

export class ImportarOfxDto {
  @ApiProperty()
  @IsUUID()
  contaBancariaId: string;

  @ApiProperty({ description: 'Conteúdo do arquivo OFX' })
  @IsString()
  @MinLength(20)
  conteudo: string;

  @ApiPropertyOptional({ description: 'Tentar conciliar automaticamente' })
  @IsOptional()
  @IsString()
  conciliarAutomatico?: string;
}
DTO_EOF

cat > src/modules/conciliacao/dto/importar-csv.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean, IsEnum, IsOptional, IsString, IsUUID, MinLength, ValidateNested,
} from 'class-validator';

export enum FormatoDataEnum {
  DDMMYYYY = 'DD/MM/YYYY',
  YYYYMMDD = 'YYYY-MM-DD',
  DDMMYYYY_HIFEN = 'DD-MM-YYYY',
}

export class MapeamentoCsvDto {
  @ApiPropertyOptional({ default: ';' })
  @IsOptional()
  @IsString()
  separador?: string;

  @ApiProperty({ example: 'Data' })
  @IsString()
  data: string;

  @ApiProperty({ example: 'Descrição' })
  @IsString()
  descricao: string;

  @ApiProperty({ example: 'Valor' })
  @IsString()
  valor: string;

  @ApiPropertyOptional({ example: 'Documento' })
  @IsOptional()
  @IsString()
  documento?: string;

  @ApiPropertyOptional({ enum: FormatoDataEnum, default: FormatoDataEnum.DDMMYYYY })
  @IsOptional()
  @IsEnum(FormatoDataEnum)
  formatoData?: FormatoDataEnum;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  decimalVirgula?: boolean;
}

export class ImportarCsvDto {
  @ApiProperty()
  @IsUUID()
  contaBancariaId: string;

  @ApiProperty({ description: 'Conteúdo do arquivo CSV' })
  @IsString()
  @MinLength(10)
  conteudo: string;

  @ApiProperty({ type: MapeamentoCsvDto })
  @ValidateNested()
  @Type(() => MapeamentoCsvDto)
  mapeamento: MapeamentoCsvDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  conciliarAutomatico?: string;
}
DTO_EOF

cat > src/modules/conciliacao/dto/conciliar-manual.dto.ts <<'DTO_EOF'
import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class ConciliarManualDto {
  @ApiProperty({ description: 'ID do lançamento a vincular' })
  @IsUUID()
  lancamentoId: string;
}
DTO_EOF

cat > src/modules/conciliacao/dto/filter-extrato.dto.ts <<'DTO_EOF'
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBooleanString, IsDateString, IsOptional, IsUUID } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export class FilterExtratoDto extends PaginationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  contaBancariaId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataInicio?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataFim?: string;

  @ApiPropertyOptional({ description: 'Filtrar por status de conciliação (true/false)' })
  @IsOptional()
  @IsBooleanString()
  conciliado?: string;
}
DTO_EOF

# ============================================================
# 5. SERVIÇO — CONTAS BANCÁRIAS
# ============================================================
cat > src/modules/contas-bancarias/contas-bancarias.service.ts <<'SERVICE_EOF'
import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateContaBancariaDto } from './dto/create-conta-bancaria.dto';
import { UpdateContaBancariaDto } from './dto/update-conta-bancaria.dto';

@Injectable()
export class ContasBancariasService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string, empresaId?: string) {
    const where: any = { tenantId, status: 'ATIVO' };
    if (empresaId) where.empresaId = empresaId;

    return this.prisma.contaBancaria.findMany({
      where,
      include: {
        banco: { select: { codigo: true, nome: true } },
        contaContabil: { select: { id: true, codigo: true, nome: true } },
        empresa: { select: { id: true, razaoSocial: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async buscarPorId(tenantId: string, id: string) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id, tenantId },
      include: {
        banco: true,
        contaContabil: true,
        empresa: { select: { id: true, razaoSocial: true } },
      },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');
    return conta;
  }

  async criar(tenantId: string, dto: CreateContaBancariaDto) {
    // Validar empresa
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: dto.empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    // Validar banco
    const banco = await this.prisma.banco.findUnique({
      where: { codigo: dto.bancoCodigo },
    });
    if (!banco) throw new NotFoundException(`Banco ${dto.bancoCodigo} não cadastrado`);

    // Verificar duplicidade (mesma agência + conta)
    if (dto.agencia && dto.numeroConta) {
      const existente = await this.prisma.contaBancaria.findFirst({
        where: {
          tenantId,
          empresaId: dto.empresaId,
          bancoId: banco.id,
          agencia: dto.agencia,
          numeroConta: dto.numeroConta,
        },
      });
      if (existente) {
        throw new ConflictException('Conta bancária já cadastrada');
      }
    }

    return this.prisma.contaBancaria.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        bancoId: banco.id,
        agencia: dto.agencia,
        numeroConta: dto.numeroConta,
        digito: dto.digito,
        tipo: dto.tipo ?? 'CORRENTE',
        contaContabilId: dto.contaContabilId,
        saldoInicial: dto.saldoInicial ?? 0,
      },
      include: { banco: true },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateContaBancariaDto) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');

    let bancoId = conta.bancoId;
    if (dto.bancoCodigo) {
      const banco = await this.prisma.banco.findUnique({
        where: { codigo: dto.bancoCodigo },
      });
      if (!banco) throw new NotFoundException(`Banco ${dto.bancoCodigo} não cadastrado`);
      bancoId = banco.id;
    }

    return this.prisma.contaBancaria.update({
      where: { id },
      data: {
        bancoId,
        agencia: dto.agencia,
        numeroConta: dto.numeroConta,
        digito: dto.digito,
        tipo: dto.tipo,
        contaContabilId: dto.contaContabilId,
        saldoInicial: dto.saldoInicial,
      },
      include: { banco: true },
    });
  }

  async remover(tenantId: string, id: string) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');

    const extratos = await this.prisma.extratoBancario.count({
      where: { contaBancariaId: id },
    });
    if (extratos > 0) {
      // Soft delete se tiver extrato
      await this.prisma.contaBancaria.update({
        where: { id },
        data: { status: 'INATIVO' },
      });
      return { message: 'Conta desativada (possui extratos vinculados)' };
    }

    await this.prisma.contaBancaria.delete({ where: { id } });
    return { message: 'Conta removida' };
  }
}
SERVICE_EOF

cat > src/modules/contas-bancarias/contas-bancarias.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ContasBancariasService } from './contas-bancarias.service';
import { CreateContaBancariaDto } from './dto/create-conta-bancaria.dto';
import { UpdateContaBancariaDto } from './dto/update-conta-bancaria.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('contas-bancarias')
@ApiBearerAuth()
@Controller('contas-bancarias')
export class ContasBancariasController {
  constructor(private readonly service: ContasBancariasService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  @ApiOperation({ summary: 'Lista contas bancárias' })
  listar(
    @CurrentTenant() t: string,
    @Query('empresaId') empresaId?: string,
  ) {
    return this.service.listar(t, empresaId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  criar(@CurrentTenant() t: string, @Body() dto: CreateContaBancariaDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateContaBancariaDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
CTRL_EOF

cat > src/modules/contas-bancarias/contas-bancarias.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { ContasBancariasController } from './contas-bancarias.controller';
import { ContasBancariasService } from './contas-bancarias.service';

@Module({
  controllers: [ContasBancariasController],
  providers: [ContasBancariasService],
  exports: [ContasBancariasService],
})
export class ContasBancariasModule {}
MOD_EOF

# ============================================================
# 6. SERVIÇO — MATCH (conciliação automática)
# ============================================================
cat > src/modules/conciliacao/services/match.service.ts <<'MATCH_EOF'
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';

const TOLERANCIA_VALOR = 0.01; // 1 centavo
const TOLERANCIA_DIAS = 3;

@Injectable()
export class MatchService {
  private readonly logger = new Logger(MatchService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Tenta conciliar extratos pendentes com lançamentos contábeis.
   * Retorna quantos foram conciliados.
   */
  async conciliarAutomaticamente(tenantId: string, contaBancariaId: string): Promise<number> {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id: contaBancariaId, tenantId },
    });
    if (!conta) return 0;

    // Buscar extratos não conciliados
    const extratos = await this.prisma.extratoBancario.findMany({
      where: { tenantId, contaBancariaId, conciliado: false },
      orderBy: { dataMovimento: 'asc' },
    });

    if (extratos.length === 0) return 0;

    // Buscar lançamentos candidatos (últimos 90 dias)
    const dataMin = extratos[0].dataMovimento;
    dataMin.setDate(dataMin.getDate() - 90);

    const lancamentos = await this.prisma.lancamento.findMany({
      where: {
        tenantId,
        empresaId: conta.empresaId,
        status: 'ATIVO',
        dataLancamento: { gte: dataMin },
      },
      include: { partidas: true },
    });

    const usados = new Set<string>();
    let conciliados = 0;

    for (const extrato of extratos) {
      const candidato = this.encontrarCandidato(extrato, lancamentos, usados);
      if (!candidato) continue;

      await this.prisma.extratoBancario.update({
        where: { id: extrato.id },
        data: { conciliado: true, lancamentoId: candidato.id },
      });
      usados.add(candidato.id);
      conciliados++;
    }

    this.logger.log(
      `Conciliação automática: ${conciliados}/${extratos.length} extratos vinculados`,
    );
    return conciliados;
  }

  private encontrarCandidato(
    extrato: any,
    lancamentos: any[],
    usados: Set<string>,
  ): any | null {
    const valorExtrato = Math.abs(Number(extrato.valor));

    let melhorCandidato: any = null;
    let menorDiferenca = Infinity;

    for (const lanc of lancamentos) {
      if (usados.has(lanc.id)) continue;

      const valorLanc = Math.abs(Number(lanc.valorTotal));
      const difValor = Math.abs(valorLanc - valorExtrato);

      if (difValor > TOLERANCIA_VALOR) continue;

      const difDias = Math.abs(
        (lanc.dataLancamento.getTime() - extrato.dataMovimento.getTime()) /
          (1000 * 60 * 60 * 24),
      );

      if (difDias > TOLERANCIA_DIAS) continue;

      // Preferir candidatos com menor diferença de dias
      const score = difDias + difValor * 100;
      if (score < menorDiferenca) {
        menorDiferenca = score;
        melhorCandidato = lanc;
      }
    }

    return melhorCandidato;
  }
}
MATCH_EOF

# ============================================================
# 7. SERVIÇO PRINCIPAL DE CONCILIAÇÃO
# ============================================================
cat > src/modules/conciliacao/conciliacao.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { OfxParser } from './parsers/ofx.parser';
import { CsvParser } from './parsers/csv.parser';
import { MatchService } from './services/match.service';
import { ImportarOfxDto } from './dto/importar-ofx.dto';
import { ImportarCsvDto } from './dto/importar-csv.dto';
import { ConciliarManualDto } from './dto/conciliar-manual.dto';
import { FilterExtratoDto } from './dto/filter-extrato.dto';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class ConciliacaoService {
  private readonly logger = new Logger(ConciliacaoService.name);
  private readonly ofxParser = new OfxParser();
  private readonly csvParser = new CsvParser();

  constructor(
    private readonly prisma: PrismaService,
    private readonly match: MatchService,
  ) {}

  async importarOfx(tenantId: string, dto: ImportarOfxDto) {
    const conta = await this.validarConta(tenantId, dto.contaBancariaId);

    let extrato;
    try {
      extrato = this.ofxParser.parse(dto.conteudo);
    } catch (err) {
      throw new BadRequestException(`Erro ao processar OFX: ${(err as Error).message}`);
    }

    return this.persistirExtrato(tenantId, conta, extrato.transacoes, 'OFX', dto.conciliarAutomatico);
  }

  async importarCsv(tenantId: string, dto: ImportarCsvDto) {
    const conta = await this.validarConta(tenantId, dto.contaBancariaId);

    let transacoes;
    try {
      transacoes = this.csvParser.parse(dto.conteudo, {
        separador: dto.mapeamento.separador,
        data: dto.mapeamento.data,
        descricao: dto.mapeamento.descricao,
        valor: dto.mapeamento.valor,
        documento: dto.mapeamento.documento,
        formatoData: dto.mapeamento.formatoData as any,
        decimalVirgula: dto.mapeamento.decimalVirgula,
      });
    } catch (err) {
      throw new BadRequestException(`Erro ao processar CSV: ${(err as Error).message}`);
    }

    return this.persistirExtrato(tenantId, conta, transacoes, 'CSV', dto.conciliarAutomatico);
  }

  private async persistirExtrato(
    tenantId: string,
    conta: any,
    transacoes: any[],
    origem: 'OFX' | 'CSV',
    conciliarAuto?: string,
  ) {
    // 1. Filtrar duplicadas pelo hash
    const hashes = transacoes.map((t) => t.hash);
    const existentes = await this.prisma.extratoBancario.findMany({
      where: { hashUnico: { in: hashes } },
      select: { hashUnico: true },
    });
    const hashesExistentes = new Set(existentes.map((e) => e.hashUnico));

    const novas = transacoes.filter((t) => !hashesExistentes.has(t.hash));
    const duplicadas = transacoes.length - novas.length;

    if (novas.length === 0) {
      return {
        importadas: 0,
        duplicadas,
        total: transacoes.length,
        conciliadas: 0,
      };
    }

    // 2. Inserir em transação
    await this.prisma.$transaction(async (tx) => {
      await tx.extratoBancario.createMany({
        data: novas.map((t) => ({
          tenantId,
          contaBancariaId: conta.id,
          dataMovimento: t.dataMovimento,
          descricao: t.descricao,
          documento: t.documento,
          valor: t.tipo === 'C' ? t.valor : -t.valor,
          tipo: t.tipo,
          origemImportacao: origem,
          hashUnico: t.hash,
          conciliado: false,
        })),
      });
    });

    // 3. Conciliação automática (se solicitada)
    let conciliadas = 0;
    if (conciliarAuto !== 'false') {
      conciliadas = await this.match.conciliarAutomaticamente(tenantId, conta.id);
    }

    return {
      importadas: novas.length,
      duplicadas,
      total: transacoes.length,
      conciliadas,
    };
  }

  async listar(tenantId: string, filtros: FilterExtratoDto) {
    const where: Prisma.ExtratoBancarioWhereInput = { tenantId };

    if (filtros.contaBancariaId) where.contaBancariaId = filtros.contaBancariaId;
    if (filtros.conciliado !== undefined) {
      where.conciliado = filtros.conciliado === 'true';
    }
    if (filtros.dataInicio || filtros.dataFim) {
      where.dataMovimento = {};
      if (filtros.dataInicio) (where.dataMovimento as any).gte = new Date(filtros.dataInicio);
      if (filtros.dataFim) (where.dataMovimento as any).lte = new Date(filtros.dataFim);
    }

    const [total, data] = await Promise.all([
      this.prisma.extratoBancario.count({ where }),
      this.prisma.extratoBancario.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { dataMovimento: filtros.order },
        include: {
          contaBancaria: {
            include: { banco: { select: { codigo: true, nome: true } } },
          },
        },
      }),
    ]);

    return paginar(data, total, filtros.page, filtros.limit);
  }

  async conciliarManual(tenantId: string, extratoId: string, dto: ConciliarManualDto) {
    const extrato = await this.prisma.extratoBancario.findFirst({
      where: { id: extratoId, tenantId },
    });
    if (!extrato) throw new NotFoundException('Extrato não encontrado');
    if (extrato.conciliado) throw new ConflictException('Extrato já está conciliado');

    const lancamento = await this.prisma.lancamento.findFirst({
      where: { id: dto.lancamentoId, tenantId },
    });
    if (!lancamento) throw new NotFoundException('Lançamento não encontrado');

    // Validar valores compatíveis
    const dif = Math.abs(Math.abs(Number(extrato.valor)) - Math.abs(Number(lancamento.valorTotal)));
    if (dif > 0.01) {
      throw new BadRequestException(
        `Valores diferentes: extrato R$ ${extrato.valor}, lançamento R$ ${lancamento.valorTotal}`,
      );
    }

    return this.prisma.extratoBancario.update({
      where: { id: extratoId },
      data: { conciliado: true, lancamentoId: dto.lancamentoId },
    });
  }

  async desconciliar(tenantId: string, extratoId: string) {
    const extrato = await this.prisma.extratoBancario.findFirst({
      where: { id: extratoId, tenantId },
    });
    if (!extrato) throw new NotFoundException('Extrato não encontrado');

    return this.prisma.extratoBancario.update({
      where: { id: extratoId },
      data: { conciliado: false, lancamentoId: null },
    });
  }

  async conciliarLote(tenantId: string, contaBancariaId: string) {
    await this.validarConta(tenantId, contaBancariaId);
    const conciliadas = await this.match.conciliarAutomaticamente(tenantId, contaBancariaId);
    return { conciliadas };
  }

  async dashboard(tenantId: string, contaBancariaId?: string) {
    const where: any = { tenantId };
    if (contaBancariaId) where.contaBancariaId = contaBancariaId;

    const [total, conciliados, pendentes] = await Promise.all([
      this.prisma.extratoBancario.count({ where }),
      this.prisma.extratoBancario.count({ where: { ...where, conciliado: true } }),
      this.prisma.extratoBancario.count({ where: { ...where, conciliado: false } }),
    ]);

    const somaPendentes = await this.prisma.extratoBancario.aggregate({
      where: { ...where, conciliado: false },
      _sum: { valor: true },
    });

    return {
      total,
      conciliados,
      pendentes,
      percentualConciliado: total > 0 ? Number(((conciliados / total) * 100).toFixed(2)) : 0,
      valorPendente: Number(somaPendentes._sum.valor ?? 0),
    };
  }

  private async validarConta(tenantId: string, contaId: string) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');
    return conta;
  }
}
SERVICE_EOF

# ============================================================
# 8. CONTROLLER — CONCILIAÇÃO
# ============================================================
cat > src/modules/conciliacao/conciliacao.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Get, Param, ParseUUIDPipe, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ConciliacaoService } from './conciliacao.service';
import { ImportarOfxDto } from './dto/importar-ofx.dto';
import { ImportarCsvDto } from './dto/importar-csv.dto';
import { ConciliarManualDto } from './dto/conciliar-manual.dto';
import { FilterExtratoDto } from './dto/filter-extrato.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('conciliacao')
@ApiBearerAuth()
@Controller('conciliacao')
export class ConciliacaoController {
  constructor(private readonly service: ConciliacaoService) {}

  @Post('importar-ofx')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Importa extrato no formato OFX' })
  importarOfx(@CurrentTenant() t: string, @Body() dto: ImportarOfxDto) {
    return this.service.importarOfx(t, dto);
  }

  @Post('importar-csv')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Importa extrato no formato CSV (com mapeamento)' })
  importarCsv(@CurrentTenant() t: string, @Body() dto: ImportarCsvDto) {
    return this.service.importarCsv(t, dto);
  }

  @Get('extratos')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  @ApiOperation({ summary: 'Lista extratos com filtros' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterExtratoDto) {
    return this.service.listar(t, filtros);
  }

  @Post('extratos/:id/conciliar')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Conciliação manual (vincular a lançamento)' })
  conciliarManual(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: ConciliarManualDto,
  ) {
    return this.service.conciliarManual(t, id, dto);
  }

  @Post('extratos/:id/desconciliar')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Remove vínculo de conciliação' })
  desconciliar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.desconciliar(t, id);
  }

  @Post('conciliar-lote/:contaBancariaId')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_EXECUTAR)
  @ApiOperation({ summary: 'Executa conciliação automática em lote' })
  conciliarLote(
    @CurrentTenant() t: string,
    @Param('contaBancariaId', ParseUUIDPipe) contaBancariaId: string,
  ) {
    return this.service.conciliarLote(t, contaBancariaId);
  }

  @Get('dashboard')
  @RequirePermissions(PERMISSIONS.CONCILIACAO_VER)
  @ApiOperation({ summary: 'Dashboard de conciliação' })
  dashboard(
    @CurrentTenant() t: string,
    @Query('contaBancariaId') contaBancariaId?: string,
  ) {
    return this.service.dashboard(t, contaBancariaId);
  }
}
CTRL_EOF

cat > src/modules/conciliacao/conciliacao.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { ConciliacaoController } from './conciliacao.controller';
import { ConciliacaoService } from './conciliacao.service';
import { MatchService } from './services/match.service';
import { ContasBancariasModule } from '../contas-bancarias/contas-bancarias.module';

@Module({
  imports: [ContasBancariasModule],
  controllers: [ConciliacaoController],
  providers: [ConciliacaoService, MatchService],
  exports: [ConciliacaoService],
})
export class ConciliacaoModule {}
MOD_EOF

# ============================================================
# 9. TESTES
# ============================================================
cat > src/modules/conciliacao/testes/ofx.parser.spec.ts <<'TEST_EOF'
import { OfxParser, OfxParserError } from '../parsers/ofx.parser';

describe('OfxParser', () => {
  const parser = new OfxParser();

  const OFX_VALIDO = `
OFXHEADER:100
DATA:OFXSGML
VERSION:102

<OFX>
<BANKMSGSRSV1>
<STMTTRNRS>
<STMTRS>
<BANKACCTFROM>
<BANKID>341
<ACCTID>12345-6
<BRANCHID>1234
</BANKACCTFROM>
<BANKTRANLIST>
<DTSTART>20260901
<DTEND>20260930
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260915
<TRNAMT>-150.50
<MEMO>PAGAMENTO FORNECEDOR ABC
</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260920
<TRNAMT>1000.00
<MEMO>RECEBIMENTO CLIENTE XYZ
</STMTTRN>
</BANKTRANLIST>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>
</OFX>
  `.trim();

  it('faz parse de OFX válido', () => {
    const extrato = parser.parse(OFX_VALIDO);
    expect(extrato.bancoCodigo).toBe('341');
    expect(extrato.contaId).toBe('12345-6');
    expect(extrato.transacoes).toHaveLength(2);
  });

  it('interpreta débito e crédito corretamente', () => {
    const extrato = parser.parse(OFX_VALIDO);
    const debito = extrato.transacoes.find((t) => t.tipo === 'D');
    const credito = extrato.transacoes.find((t) => t.tipo === 'C');

    expect(debito?.valor).toBe(150.5);
    expect(credito?.valor).toBe(1000);
  });

  it('gera hash único por transação', () => {
    const extrato = parser.parse(OFX_VALIDO);
    const hashes = extrato.transacoes.map((t) => t.hash);
    expect(new Set(hashes).size).toBe(hashes.length);
  });

  it('rejeita conteúdo vazio', () => {
    expect(() => parser.parse('')).toThrow(OfxParserError);
  });

  it('rejeita OFX sem transações', () => {
    const vazio = OFX_VALIDO.replace(/<STMTTRN>[\s\S]*?<\/STMTTRN>/g, '');
    expect(() => parser.parse(vazio)).toThrow(OfxParserError);
  });
});
TEST_EOF

cat > src/modules/conciliacao/testes/csv.parser.spec.ts <<'TEST_EOF'
import { CsvParser, CsvParserError } from '../parsers/csv.parser';

describe('CsvParser', () => {
  const parser = new CsvParser();

  const CSV_VALIDO = `Data;Descrição;Valor;Documento
15/09/2026;PAGAMENTO FORNECEDOR;-150,50;DOC123
20/09/2026;RECEBIMENTO CLIENTE;1000,00;DOC124
25/09/2026;TARIFA BANCÁRIA;-15,00;`;

  const MAPEAMENTO = {
    separador: ';',
    data: 'Data',
    descricao: 'Descrição',
    valor: 'Valor',
    documento: 'Documento',
    formatoData: 'DD/MM/YYYY' as const,
    decimalVirgula: true,
  };

  it('faz parse de CSV válido', () => {
    const transacoes = parser.parse(CSV_VALIDO, MAPEAMENTO);
    expect(transacoes).toHaveLength(3);
  });

  it('interpreta valores com vírgula decimal', () => {
    const transacoes = parser.parse(CSV_VALIDO, MAPEAMENTO);
    const credito = transacoes.find((t) => t.tipo === 'C');
    const debito = transacoes.find((t) => t.tipo === 'D');
    expect(credito?.valor).toBe(1000);
    expect(debito?.valor).toBe(150.5);
  });

  it('interpreta datas corretamente', () => {
    const transacoes = parser.parse(CSV_VALIDO, MAPEAMENTO);
    const primeira = transacoes[0];
    expect(primeira.dataMovimento.getDate()).toBe(15);
    expect(primeira.dataMovimento.getMonth()).toBe(8); // setembro
    expect(primeira.dataMovimento.getFullYear()).toBe(2026);
  });

  it('detecta separador automaticamente', () => {
    const csv = CSV_VALIDO.replace(/;/g, ',');
    const semSeparador = { ...MAPEAMENTO, separador: undefined };
    const transacoes = parser.parse(csv, semSeparador);
    expect(transacoes).toHaveLength(3);
  });

  it('rejeita CSV vazio', () => {
    expect(() => parser.parse('', MAPEAMENTO)).toThrow(CsvParserError);
  });

  it('rejeita CSV sem colunas obrigatórias', () => {
    const invalido = `A;B\n1;2`;
    expect(() => parser.parse(invalido, MAPEAMENTO)).toThrow(CsvParserError);
  });

  it('gera hash determinístico', () => {
    const a = parser.parse(CSV_VALIDO, MAPEAMENTO);
    const b = parser.parse(CSV_VALIDO, MAPEAMENTO);
    expect(a.map((t) => t.hash)).toEqual(b.map((t) => t.hash));
  });
});
TEST_EOF

cat > src/modules/conciliacao/testes/match.service.spec.ts <<'TEST_EOF'
import { Test } from '@nestjs/testing';
import { MatchService } from '../services/match.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('MatchService', () => {
  let service: MatchService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      contaBancaria: { findFirst: jest.fn().mockResolvedValue({ id: 'cb1', empresaId: 'e1' }) },
      extratoBancario: {
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn(),
      },
      lancamento: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const module = await Test.createTestingModule({
      providers: [MatchService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(MatchService);
  });

  it('retorna 0 quando não há extratos pendentes', async () => {
    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(0);
  });

  it('concilia quando valor e data batem', async () => {
    const data = new Date('2026-09-15');
    prisma.extratoBancario.findMany.mockResolvedValue([
      { id: 'ex1', valor: 100, dataMovimento: data, conciliado: false, descricao: 'X' },
    ]);
    prisma.lancamento.findMany.mockResolvedValue([
      { id: 'l1', valorTotal: 100, dataLancamento: data },
    ]);
    prisma.extratoBancario.update.mockResolvedValue({});

    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(1);
  });

  it('não concilia valores diferentes', async () => {
    const data = new Date('2026-09-15');
    prisma.extratoBancario.findMany.mockResolvedValue([
      { id: 'ex1', valor: 100, dataMovimento: data, conciliado: false, descricao: 'X' },
    ]);
    prisma.lancamento.findMany.mockResolvedValue([
      { id: 'l1', valorTotal: 200, dataLancamento: data },
    ]);

    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(0);
  });

  it('não concilia datas distantes (>3 dias)', async () => {
    const extratoData = new Date('2026-09-15');
    const lancData = new Date('2026-09-25');
    prisma.extratoBancario.findMany.mockResolvedValue([
      { id: 'ex1', valor: 100, dataMovimento: extratoData, conciliado: false, descricao: 'X' },
    ]);
    prisma.lancamento.findMany.mockResolvedValue([
      { id: 'l1', valorTotal: 100, dataLancamento: lancData },
    ]);

    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(0);
  });
});
TEST_EOF

# ============================================================
# 10. REGISTRAR NO APP.MODULE
# ============================================================
python3 <<'PYEOF'
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'ConciliacaoModule' not in content:
    content = content.replace(
        "import { DocumentosFiscaisModule } from './modules/documentos-fiscais/documentos-fiscais.module';",
        "import { DocumentosFiscaisModule } from './modules/documentos-fiscais/documentos-fiscais.module';\n"
        "import { ContasBancariasModule } from './modules/contas-bancarias/contas-bancarias.module';\n"
        "import { ConciliacaoModule } from './modules/conciliacao/conciliacao.module';"
    )
    content = content.replace(
        "    DocumentosFiscaisModule,\n    HealthModule,",
        "    DocumentosFiscaisModule,\n    ContasBancariasModule,\n    ConciliacaoModule,\n    HealthModule,"
    )
    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado")
else:
    print("ℹ️  AppModule já contém ConciliacaoModule")
PYEOF

echo ""
echo "✅ Pacote F6 instalado!"
echo ""
echo "Próximos passos:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"