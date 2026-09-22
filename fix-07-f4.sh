#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/modules/plano-contas/dto
mkdir -p src/modules/plano-contas/testes
mkdir -p src/modules/plano-contas/seeds
mkdir -p src/modules/centros-custo/dto
mkdir -p src/modules/centros-custo/testes

# ============================================================
# 1. PLANO PADRÃO (modelo reduzido da RFB)
# ============================================================
cat > src/modules/plano-contas/seeds/plano-padrao.ts <<'SEED_EOF'
export interface ContaPadrao {
  codigo: string;
  nome: string;
  natureza: 'ATIVO' | 'PASSIVO' | 'PATRIMONIO_LIQUIDO' | 'RECEITA' | 'DESPESA' | 'CUSTO';
  tipo: 'SINTETICA' | 'ANALITICA';
  dreLinha?: string;
}

/**
 * Plano de contas padrão brasileiro (versão resumida).
 * Baseado na estrutura da Receita Federal, adaptado para uso em escritórios.
 */
export const PLANO_PADRAO: ContaPadrao[] = [
  // ============ ATIVO ============
  { codigo: '1', nome: 'ATIVO', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1', nome: 'ATIVO CIRCULANTE', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.1', nome: 'DISPONIBILIDADES', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.1.01', nome: 'Caixa', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.1.02', nome: 'Bancos Conta Movimento', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.1.03', nome: 'Aplicações Financeiras', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.1.2', nome: 'CLIENTES', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.2.01', nome: 'Clientes Nacionais', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.2.02', nome: 'Clientes Estrangeiros', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.2.03', nome: '(-) Duplicatas Descontadas', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.1.3', nome: 'ESTOQUES', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.3.01', nome: 'Mercadorias para Revenda', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.3.02', nome: 'Matéria-Prima', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.3.03', nome: 'Produtos Acabados', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.1.4', nome: 'IMPOSTOS A RECUPERAR', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.1.4.01', nome: 'ICMS a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.02', nome: 'PIS a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.03', nome: 'COFINS a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.04', nome: 'IRPJ a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.1.4.05', nome: 'CSLL a Recuperar', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.2', nome: 'ATIVO NÃO CIRCULANTE', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.2.1', nome: 'REALIZÁVEL A LONGO PRAZO', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.2.1.01', nome: 'Aplicações Financeiras LP', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.1.02', nome: 'Depósitos Judiciais', natureza: 'ATIVO', tipo: 'ANALITICA' },

  { codigo: '1.2.2', nome: 'IMOBILIZADO', natureza: 'ATIVO', tipo: 'SINTETICA' },
  { codigo: '1.2.2.01', nome: 'Imóveis', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.02', nome: 'Veículos', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.03', nome: 'Móveis e Utensílios', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.04', nome: 'Máquinas e Equipamentos', natureza: 'ATIVO', tipo: 'ANALITICA' },
  { codigo: '1.2.2.05', nome: '(-) Depreciação Acumulada', natureza: 'ATIVO', tipo: 'ANALITICA' },

  // ============ PASSIVO ============
  { codigo: '2', nome: 'PASSIVO', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1', nome: 'PASSIVO CIRCULANTE', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.1', nome: 'FORNECEDORES', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.1.01', nome: 'Fornecedores Nacionais', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.1.02', nome: 'Fornecedores Estrangeiros', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.1.2', nome: 'OBRIGAÇÕES TRABALHISTAS', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.2.01', nome: 'Salários a Pagar', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.2.02', nome: 'FGTS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.2.03', nome: 'INSS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.2.04', nome: 'IRRF a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.1.3', nome: 'OBRIGAÇÕES TRIBUTÁRIAS', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.3.01', nome: 'ICMS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.02', nome: 'PIS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.03', nome: 'COFINS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.04', nome: 'IRPJ a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.05', nome: 'CSLL a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.06', nome: 'ISS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },
  { codigo: '2.1.3.07', nome: 'DAS a Recolher', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.1.4', nome: 'EMPRÉSTIMOS E FINANCIAMENTOS', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.1.4.01', nome: 'Empréstimos Bancários CP', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  { codigo: '2.2', nome: 'PASSIVO NÃO CIRCULANTE', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.2.1', nome: 'EMPRÉSTIMOS E FINANCIAMENTOS LP', natureza: 'PASSIVO', tipo: 'SINTETICA' },
  { codigo: '2.2.1.01', nome: 'Financiamentos LP', natureza: 'PASSIVO', tipo: 'ANALITICA' },

  // ============ PATRIMÔNIO LÍQUIDO ============
  { codigo: '2.3', nome: 'PATRIMÔNIO LÍQUIDO', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'SINTETICA' },
  { codigo: '2.3.1', nome: 'CAPITAL SOCIAL', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
  { codigo: '2.3.2', nome: 'LUCROS ACUMULADOS', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
  { codigo: '2.3.3', nome: 'PREJUÍZOS ACUMULADOS', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
  { codigo: '2.3.4', nome: 'RESERVAS', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },

  // ============ RECEITAS ============
  { codigo: '3', nome: 'RECEITAS', natureza: 'RECEITA', tipo: 'SINTETICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1', nome: 'RECEITA BRUTA', natureza: 'RECEITA', tipo: 'SINTETICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1.1', nome: 'Vendas de Mercadorias', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1.2', nome: 'Prestação de Serviços', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'RECEITA_BRUTA' },
  { codigo: '3.1.3', nome: 'Receitas Financeiras', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'RECEITA_FINANCEIRA' },
  { codigo: '3.1.4', nome: 'Outras Receitas', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'OUTRAS_RECEITAS' },

  { codigo: '3.2', nome: 'DEDUÇÕES DA RECEITA', natureza: 'RECEITA', tipo: 'SINTETICA', dreLinha: 'DEDUCOES' },
  { codigo: '3.2.1', nome: '(-) Impostos sobre Vendas', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'DEDUCOES' },
  { codigo: '3.2.2', nome: '(-) Devoluções de Vendas', natureza: 'RECEITA', tipo: 'ANALITICA', dreLinha: 'DEDUCOES' },

  // ============ CUSTOS ============
  { codigo: '4', nome: 'CUSTOS', natureza: 'CUSTO', tipo: 'SINTETICA', dreLinha: 'CUSTO_PRODUTOS' },
  { codigo: '4.1', nome: 'CUSTO DAS MERCADORIAS VENDIDAS', natureza: 'CUSTO', tipo: 'ANALITICA', dreLinha: 'CUSTO_PRODUTOS' },
  { codigo: '4.2', nome: 'CUSTO DOS SERVIÇOS PRESTADOS', natureza: 'CUSTO', tipo: 'ANALITICA', dreLinha: 'CUSTO_SERVICOS' },

  // ============ DESPESAS ============
  { codigo: '5', nome: 'DESPESAS', natureza: 'DESPESA', tipo: 'SINTETICA' },
  { codigo: '5.1', nome: 'DESPESAS OPERACIONAIS', natureza: 'DESPESA', tipo: 'SINTETICA' },
  { codigo: '5.1.1', nome: 'Despesas com Pessoal', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_PESSOAL' },
  { codigo: '5.1.2', nome: 'Despesas Administrativas', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_ADMIN' },
  { codigo: '5.1.3', nome: 'Despesas Comerciais', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_COMERCIAIS' },
  { codigo: '5.1.4', nome: 'Despesas Tributárias', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_TRIBUTARIAS' },
  { codigo: '5.1.5', nome: 'Despesas Financeiras', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'DESPESAS_FINANCEIRAS' },

  { codigo: '5.2', nome: 'OUTRAS DESPESAS', natureza: 'DESPESA', tipo: 'SINTETICA' },
  { codigo: '5.2.1', nome: 'Perdas Diversas', natureza: 'DESPESA', tipo: 'ANALITICA', dreLinha: 'OUTRAS_DESPESAS' },

  // ============ APURAÇÃO ============
  { codigo: '6', nome: 'APURAÇÃO DO RESULTADO', natureza: 'RECEITA', tipo: 'SINTETICA' },
  { codigo: '6.1', nome: 'Resultado do Exercício', natureza: 'PATRIMONIO_LIQUIDO', tipo: 'ANALITICA' },
];
SEED_EOF

# ============================================================
# 2. DTOs — PLANO DE CONTAS
# ============================================================
cat > src/modules/plano-contas/dto/create-plano.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreatePlanoDto {
  @ApiProperty({ example: 'Plano 2026' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ description: 'Data de início da vigência (YYYY-MM-DD)' })
  @IsDateString()
  vigenciaInicio: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  vigenciaFim?: string;
}
DTO_EOF

cat > src/modules/plano-contas/dto/create-conta.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export enum NaturezaContaEnum {
  ATIVO = 'ATIVO',
  PASSIVO = 'PASSIVO',
  PATRIMONIO_LIQUIDO = 'PATRIMONIO_LIQUIDO',
  RECEITA = 'RECEITA',
  DESPESA = 'DESPESA',
  CUSTO = 'CUSTO',
}

export enum TipoContaEnum {
  SINTETICA = 'SINTETICA',
  ANALITICA = 'ANALITICA',
}

export class CreateContaDto {
  @ApiProperty({ example: '1.1.1.01' })
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  codigo: string;

  @ApiProperty()
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ enum: NaturezaContaEnum })
  @IsEnum(NaturezaContaEnum)
  natureza: NaturezaContaEnum;

  @ApiProperty({ enum: TipoContaEnum })
  @IsEnum(TipoContaEnum)
  tipo: TipoContaEnum;

  @ApiPropertyOptional({ description: 'ID da conta pai (opcional)' })
  @IsOptional()
  @IsUUID()
  contaPaiId?: string;

  @ApiPropertyOptional({ example: 'RECEITA_BRUTA' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  dreLinha?: string;
}
DTO_EOF

cat > src/modules/plano-contas/dto/update-conta.dto.ts <<'DTO_EOF'
import { PartialType } from '@nestjs/swagger';
import { CreateContaDto } from './create-conta.dto';

export class UpdateContaDto extends PartialType(CreateContaDto) {}
DTO_EOF

# ============================================================
# 3. SERVICE — PLANO DE CONTAS
# ============================================================
cat > src/modules/plano-contas/plano-contas.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreatePlanoDto } from './dto/create-plano.dto';
import { CreateContaDto } from './dto/create-conta.dto';
import { UpdateContaDto } from './dto/update-conta.dto';
import { PLANO_PADRAO } from './seeds/plano-padrao';

@Injectable()
export class PlanoContasService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Lista os planos de conta da empresa.
   */
  async listarPlanos(tenantId: string, empresaId: string) {
    await this.validarEmpresa(tenantId, empresaId);

    return this.prisma.planoContas.findMany({
      where: { tenantId, empresaId },
      orderBy: { versao: 'desc' },
      include: { _count: { select: { contas: true } } },
    });
  }

  /**
   * Cria um plano de contas vazio para a empresa, com a próxima versão.
   */
  async criarPlano(tenantId: string, empresaId: string, dto: CreatePlanoDto) {
    await this.validarEmpresa(tenantId, empresaId);

    const ultimo = await this.prisma.planoContas.findFirst({
      where: { empresaId },
      orderBy: { versao: 'desc' },
    });
    const proximaVersao = (ultimo?.versao ?? 0) + 1;

    return this.prisma.planoContas.create({
      data: {
        tenantId,
        empresaId,
        nome: dto.nome,
        versao: proximaVersao,
        vigenciaInicio: new Date(dto.vigenciaInicio),
        vigenciaFim: dto.vigenciaFim ? new Date(dto.vigenciaFim) : undefined,
      },
    });
  }

  /**
   * Cria um plano já populado com o plano padrão brasileiro.
   */
  async criarPlanoPadrao(tenantId: string, empresaId: string, nome = 'Plano Padrão RFB') {
    await this.validarEmpresa(tenantId, empresaId);

    const ultimo = await this.prisma.planoContas.findFirst({
      where: { empresaId },
      orderBy: { versao: 'desc' },
    });
    const proximaVersao = (ultimo?.versao ?? 0) + 1;

    return this.prisma.$transaction(async (tx) => {
      const plano = await tx.planoContas.create({
        data: {
          tenantId,
          empresaId,
          nome,
          versao: proximaVersao,
          vigenciaInicio: new Date(),
        },
      });

      // Mapa de código → id para resolver contaPai
      const mapa: Record<string, string> = {};

      // Ordena por quantidade de pontos (pai antes de filho)
      const ordenado = [...PLANO_PADRAO].sort(
        (a, b) => a.codigo.split('.').length - b.codigo.split('.').length,
      );

      for (const contaPadrao of ordenado) {
        const partes = contaPadrao.codigo.split('.');
        const codigoPai = partes.length > 1 ? partes.slice(0, -1).join('.') : null;
        const contaPaiId = codigoPai ? mapa[codigoPai] ?? null : null;

        const conta = await tx.conta.create({
          data: {
            tenantId,
            planoContasId: plano.id,
            contaPaiId,
            codigo: contaPadrao.codigo,
            nome: contaPadrao.nome,
            natureza: contaPadrao.natureza,
            tipo: contaPadrao.tipo,
            grau: partes.length,
            aceitaLancamento: contaPadrao.tipo === 'ANALITICA',
            dreLinha: contaPadrao.dreLinha,
          },
        });
        mapa[contaPadrao.codigo] = conta.id;
      }

      return plano;
    });
  }

  /**
   * Lista todas as contas de um plano, em ordem hierárquica.
   */
  async listarContas(tenantId: string, planoId: string) {
    const plano = await this.prisma.planoContas.findFirst({
      where: { id: planoId, tenantId },
    });
    if (!plano) throw new NotFoundException('Plano de contas não encontrado');

    const contas = await this.prisma.conta.findMany({
      where: { planoContasId: planoId, tenantId },
      orderBy: { codigo: 'asc' },
    });

    return this.montarArvore(contas);
  }

  /**
   * Monta uma árvore hierárquica de contas.
   */
  private montarArvore(contas: any[]) {
    const mapa = new Map<string, any>();
    const raizes: any[] = [];

    for (const c of contas) {
      mapa.set(c.id, { ...c, filhas: [] });
    }

    for (const c of contas) {
      const node = mapa.get(c.id);
      if (c.contaPaiId && mapa.has(c.contaPaiId)) {
        mapa.get(c.contaPaiId).filhas.push(node);
      } else {
        raizes.push(node);
      }
    }

    return raizes;
  }

  /**
   * Cria uma nova conta dentro de um plano.
   */
  async criarConta(tenantId: string, planoId: string, dto: CreateContaDto) {
    const plano = await this.prisma.planoContas.findFirst({
      where: { id: planoId, tenantId },
    });
    if (!plano) throw new NotFoundException('Plano de contas não encontrado');

    const existente = await this.prisma.conta.findFirst({
      where: { planoContasId: planoId, codigo: dto.codigo },
    });
    if (existente) throw new ConflictException('Já existe uma conta com esse código');

    let grau = dto.codigo.split('.').length;

    if (dto.contaPaiId) {
      const pai = await this.prisma.conta.findFirst({
        where: { id: dto.contaPaiId, planoContasId: planoId, tenantId },
      });
      if (!pai) throw new NotFoundException('Conta pai não encontrada');
      if (pai.tipo === 'ANALITICA') {
        throw new BadRequestException('Conta analítica não pode ter filhas');
      }
      grau = pai.grau + 1;

      // Valida que o código da filha começa com o código do pai + "."
      if (!dto.codigo.startsWith(`${pai.codigo}.`)) {
        throw new BadRequestException(
          `O código da conta filha deve começar com "${pai.codigo}."`,
        );
      }
    }

    return this.prisma.conta.create({
      data: {
        tenantId,
        planoContasId: planoId,
        contaPaiId: dto.contaPaiId,
        codigo: dto.codigo,
        nome: dto.nome,
        natureza: dto.natureza,
        tipo: dto.tipo,
        grau,
        aceitaLancamento: dto.tipo === 'ANALITICA',
        dreLinha: dto.dreLinha,
      },
    });
  }

  /**
   * Atualiza uma conta existente.
   */
  async atualizarConta(tenantId: string, contaId: string, dto: UpdateContaDto) {
    const conta = await this.prisma.conta.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta não encontrada');

    if (dto.codigo && dto.codigo !== conta.codigo) {
      const existente = await this.prisma.conta.findFirst({
        where: { planoContasId: conta.planoContasId, codigo: dto.codigo, NOT: { id: contaId } },
      });
      if (existente) throw new ConflictException('Já existe conta com esse código');
    }

    if (dto.tipo === 'SINTETICA' && conta.tipo === 'ANALITICA') {
      const filhas = await this.prisma.conta.count({ where: { contaPaiId: contaId } });
      const partidas = await this.prisma.partida.count({ where: { contaId } });
      if (partidas > 0) {
        throw new BadRequestException(
          'Não é possível tornar sintética uma conta que já possui lançamentos',
        );
      }
      if (filhas === 0 && dto.tipo === 'SINTETICA') {
        // ok, apenas avisa
      }
    }

    return this.prisma.conta.update({
      where: { id: contaId },
      data: {
        codigo: dto.codigo,
        nome: dto.nome,
        natureza: dto.natureza,
        tipo: dto.tipo,
        aceitaLancamento: dto.tipo ? dto.tipo === 'ANALITICA' : undefined,
        dreLinha: dto.dreLinha,
      },
    });
  }

  /**
   * Remove uma conta — bloqueado se tiver filhas ou lançamentos.
   */
  async removerConta(tenantId: string, contaId: string) {
    const conta = await this.prisma.conta.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta não encontrada');

    const filhas = await this.prisma.conta.count({ where: { contaPaiId: contaId } });
    if (filhas > 0) throw new BadRequestException('Conta possui contas filhas');

    const partidas = await this.prisma.partida.count({ where: { contaId } });
    if (partidas > 0) {
      throw new BadRequestException('Conta possui lançamentos vinculados');
    }

    await this.prisma.conta.delete({ where: { id: contaId } });
    return { message: 'Conta removida' };
  }

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }
}
SERVICE_EOF

# ============================================================
# 4. CONTROLLER — PLANO DE CONTAS
# ============================================================
cat > src/modules/plano-contas/plano-contas.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PlanoContasService } from './plano-contas.service';
import { CreatePlanoDto } from './dto/create-plano.dto';
import { CreateContaDto } from './dto/create-conta.dto';
import { UpdateContaDto } from './dto/update-conta.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('plano-contas')
@ApiBearerAuth()
@Controller('empresas/:empresaId/plano-contas')
export class PlanoContasController {
  constructor(private readonly service: PlanoContasService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.PLANO_VER)
  @ApiOperation({ summary: 'Lista planos de conta da empresa' })
  listarPlanos(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
  ) {
    return this.service.listarPlanos(t, empresaId);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  @ApiOperation({ summary: 'Cria plano de contas vazio' })
  criarPlano(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
    @Body() dto: CreatePlanoDto,
  ) {
    return this.service.criarPlano(t, empresaId, dto);
  }

  @Post('padrao')
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  @ApiOperation({ summary: 'Cria plano com contas padrão brasileiras' })
  criarPlanoPadrao(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
    @Query('nome') nome?: string,
  ) {
    return this.service.criarPlanoPadrao(t, empresaId, nome);
  }
}

@ApiTags('plano-contas')
@ApiBearerAuth()
@Controller('planos')
export class ContasController {
  constructor(private readonly service: PlanoContasService) {}

  @Get(':planoId/contas')
  @RequirePermissions(PERMISSIONS.PLANO_VER)
  @ApiOperation({ summary: 'Lista contas em árvore hierárquica' })
  listarContas(
    @CurrentTenant() t: string,
    @Param('planoId', ParseUUIDPipe) planoId: string,
  ) {
    return this.service.listarContas(t, planoId);
  }

  @Post(':planoId/contas')
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  @ApiOperation({ summary: 'Cria nova conta dentro do plano' })
  criarConta(
    @CurrentTenant() t: string,
    @Param('planoId', ParseUUIDPipe) planoId: string,
    @Body() dto: CreateContaDto,
  ) {
    return this.service.criarConta(t, planoId, dto);
  }

  @Patch('contas/:id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  atualizarConta(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateContaDto,
  ) {
    return this.service.atualizarConta(t, id, dto);
  }

  @Delete('contas/:id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  removerConta(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.removerConta(t, id);
  }
}
CTRL_EOF

cat > src/modules/plano-contas/plano-contas.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { ContasController, PlanoContasController } from './plano-contas.controller';
import { PlanoContasService } from './plano-contas.service';

@Module({
  controllers: [PlanoContasController, ContasController],
  providers: [PlanoContasService],
  exports: [PlanoContasService],
})
export class PlanoContasModule {}
MOD_EOF

# ============================================================
# 5. CENTROS DE CUSTO — DTOs, SERVICE, CONTROLLER
# ============================================================
cat > src/modules/centros-custo/dto/create-centro.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class CreateCentroCustoDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ example: 'ADM' })
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  codigo: string;

  @ApiProperty({ example: 'Administrativo' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  nome: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  descricao?: string;
}
DTO_EOF

cat > src/modules/centros-custo/dto/update-centro.dto.ts <<'DTO_EOF'
import { PartialType } from '@nestjs/swagger';
import { CreateCentroCustoDto } from './create-centro.dto';

export class UpdateCentroCustoDto extends PartialType(CreateCentroCustoDto) {}
DTO_EOF

cat > src/modules/centros-custo/centros-custo.service.ts <<'SERVICE_EOF'
import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateCentroCustoDto } from './dto/create-centro.dto';
import { UpdateCentroCustoDto } from './dto/update-centro.dto';

@Injectable()
export class CentrosCustoService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string, empresaId: string) {
    await this.validarEmpresa(tenantId, empresaId);

    return this.prisma.centroCusto.findMany({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { codigo: 'asc' },
    });
  }

  async criar(tenantId: string, dto: CreateCentroCustoDto) {
    await this.validarEmpresa(tenantId, dto.empresaId);

    const existente = await this.prisma.centroCusto.findFirst({
      where: { empresaId: dto.empresaId, codigo: dto.codigo },
    });
    if (existente) throw new ConflictException('Já existe um centro de custo com esse código');

    return this.prisma.centroCusto.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        codigo: dto.codigo,
        nome: dto.nome,
      },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateCentroCustoDto) {
    const cc = await this.prisma.centroCusto.findFirst({ where: { id, tenantId } });
    if (!cc) throw new NotFoundException('Centro de custo não encontrado');

    return this.prisma.centroCusto.update({
      where: { id },
      data: { codigo: dto.codigo, nome: dto.nome },
    });
  }

  async remover(tenantId: string, id: string) {
    const cc = await this.prisma.centroCusto.findFirst({ where: { id, tenantId } });
    if (!cc) throw new NotFoundException('Centro de custo não encontrado');

    await this.prisma.centroCusto.update({
      where: { id },
      data: { status: 'INATIVO' },
    });
    return { message: 'Centro de custo desativado' };
  }

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }
}
SERVICE_EOF

cat > src/modules/centros-custo/centros-custo.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { CentrosCustoService } from './centros-custo.service';
import { CreateCentroCustoDto } from './dto/create-centro.dto';
import { UpdateCentroCustoDto } from './dto/update-centro.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('centros-custo')
@ApiBearerAuth()
@Controller('centros-custo')
export class CentrosCustoController {
  constructor(private readonly service: CentrosCustoService) {}

  @Get('empresa/:empresaId')
  @RequirePermissions(PERMISSIONS.PLANO_VER)
  @ApiOperation({ summary: 'Lista centros de custo da empresa' })
  listar(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
  ) {
    return this.service.listar(t, empresaId);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.PLANO_CRIAR)
  criar(@CurrentTenant() t: string, @Body() dto: CreateCentroCustoDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateCentroCustoDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.PLANO_EDITAR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
CTRL_EOF

cat > src/modules/centros-custo/centros-custo.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { CentrosCustoController } from './centros-custo.controller';
import { CentrosCustoService } from './centros-custo.service';

@Module({
  controllers: [CentrosCustoController],
  providers: [CentrosCustoService],
  exports: [CentrosCustoService],
})
export class CentrosCustoModule {}
MOD_EOF

# ============================================================
# 6. TESTES
# ============================================================
cat > src/modules/plano-contas/testes/plano-contas.service.spec.ts <<'TEST_EOF'
import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { PlanoContasService } from '../plano-contas.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { NaturezaContaEnum, TipoContaEnum } from '../dto/create-conta.dto';

describe('PlanoContasService', () => {
  let service: PlanoContasService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      empresa: { findFirst: jest.fn().mockResolvedValue({ id: 'e1' }) },
      planoContas: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
      },
      conta: {
        findFirst: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn(),
        count: jest.fn().mockResolvedValue(0),
        delete: jest.fn(),
        update: jest.fn(),
      },
      partida: { count: jest.fn().mockResolvedValue(0) },
      $transaction: jest.fn(async (fn: any) => fn(prisma)),
    };

    const module = await Test.createTestingModule({
      providers: [PlanoContasService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(PlanoContasService);
  });

  it('cria plano vazio com versão incremental', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ versao: 2 });
    prisma.planoContas.create.mockResolvedValue({ id: 'p3', versao: 3 });

    const r = await service.criarPlano('t1', 'e1', {
      nome: 'Plano 2026',
      vigenciaInicio: '2026-01-01',
    });
    expect(r.versao).toBe(3);
  });

  it('rejeita empresa inexistente', async () => {
    prisma.empresa.findFirst.mockResolvedValue(null);
    await expect(
      service.criarPlano('t1', 'inexistente', {
        nome: 'Plano',
        vigenciaInicio: '2026-01-01',
      }),
    ).rejects.toThrow(NotFoundException);
  });

  it('rejeita código duplicado ao criar conta', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findFirst.mockResolvedValue({ id: 'existente' });

    await expect(
      service.criarConta('t1', 'p1', {
        codigo: '1.1.1.01',
        nome: 'Caixa',
        natureza: NaturezaContaEnum.ATIVO,
        tipo: TipoContaEnum.ANALITICA,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('rejeita conta filha cujo código não começa com o do pai', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findFirst
      .mockResolvedValueOnce(null) // existe código?
      .mockResolvedValueOnce({ id: 'pai', codigo: '1.1', tipo: 'SINTETICA', grau: 2 });

    await expect(
      service.criarConta('t1', 'p1', {
        codigo: '2.1.1',
        nome: 'Errado',
        natureza: NaturezaContaEnum.ATIVO,
        tipo: TipoContaEnum.ANALITICA,
        contaPaiId: 'pai',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita conta filha de conta analítica', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findFirst
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'pai', codigo: '1.1', tipo: 'ANALITICA', grau: 2 });

    await expect(
      service.criarConta('t1', 'p1', {
        codigo: '1.1.1',
        nome: 'Errado',
        natureza: NaturezaContaEnum.ATIVO,
        tipo: TipoContaEnum.ANALITICA,
        contaPaiId: 'pai',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('não remove conta com filhas', async () => {
    prisma.conta.findFirst.mockResolvedValue({ id: 'c1' });
    prisma.conta.count.mockResolvedValue(2);

    await expect(service.removerConta('t1', 'c1')).rejects.toThrow(BadRequestException);
  });

  it('não remove conta com partidas', async () => {
    prisma.conta.findFirst.mockResolvedValue({ id: 'c1' });
    prisma.conta.count.mockResolvedValue(0);
    prisma.partida.count.mockResolvedValue(5);

    await expect(service.removerConta('t1', 'c1')).rejects.toThrow(BadRequestException);
  });
});
TEST_EOF

# ============================================================
# 7. REGISTRAR MÓDULOS NO APP.MODULE
# ============================================================
python3 <<'PYEOF'
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'PlanoContasModule' not in content:
    content = content.replace(
        "import { SociosModule } from './modules/socios/socios.module';",
        "import { SociosModule } from './modules/socios/socios.module';\n"
        "import { PlanoContasModule } from './modules/plano-contas/plano-contas.module';\n"
        "import { CentrosCustoModule } from './modules/centros-custo/centros-custo.module';"
    )
    content = content.replace(
        "    SociosModule,\n    HealthModule,",
        "    SociosModule,\n    PlanoContasModule,\n    CentrosCustoModule,\n    HealthModule,"
    )
    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado")
else:
    print("ℹ️  AppModule já contém PlanoContasModule")
PYEOF

echo ""
echo "✅ Pacote F4 instalado!"
echo ""
echo "Próximos passos:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"