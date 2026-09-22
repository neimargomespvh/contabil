#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/modules/documentos-fiscais/dto
mkdir -p src/modules/documentos-fiscais/services
mkdir -p src/modules/documentos-fiscais/testes

# ============================================================
# 1. DTOs
# ============================================================
cat > src/modules/documentos-fiscais/dto/importar-xml.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsBoolean, IsOptional, IsString, IsUUID, MinLength } from 'class-validator';

export class ImportarXmlDto {
  @ApiProperty({ description: 'ID da empresa à qual o documento pertence' })
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Conteúdo do XML como string' })
  @IsString()
  @MinLength(50)
  xml: string;

  @ApiPropertyOptional({
    description: 'Se true, contabiliza automaticamente ao importar',
    default: true,
  })
  @IsOptional()
  @IsBoolean()
  contabilizarAutomaticamente?: boolean = true;

  @ApiPropertyOptional({
    description: 'Se true, importa mesmo se já existir (atualiza)',
    default: false,
  })
  @IsOptional()
  @IsBoolean()
  sobrescrever?: boolean = false;
}
DTO_EOF

cat > src/modules/documentos-fiscais/dto/filter-documento.dto.ts <<'DTO_EOF'
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export enum TipoDocumentoFiscalEnum {
  NFE = 'NFE',
  NFCE = 'NFCE',
  CTE = 'CTE',
  NFSE = 'NFSE',
}

export enum SituacaoDocumentoFiscalEnum {
  AUTORIZADA = 'AUTORIZADA',
  CANCELADA = 'CANCELADA',
  DENEGADA = 'DENEGADA',
  INUTILIZADA = 'INUTILIZADA',
}

export class FilterDocumentoDto extends PaginationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  empresaId?: string;

  @ApiPropertyOptional({ enum: TipoDocumentoFiscalEnum })
  @IsOptional()
  @IsEnum(TipoDocumentoFiscalEnum)
  tipo?: TipoDocumentoFiscalEnum;

  @ApiPropertyOptional({ enum: SituacaoDocumentoFiscalEnum })
  @IsOptional()
  @IsEnum(SituacaoDocumentoFiscalEnum)
  situacao?: SituacaoDocumentoFiscalEnum;

  @ApiPropertyOptional({ description: 'Chave de acesso (44 dígitos)' })
  @IsOptional()
  @IsString()
  chaveAcesso?: string;

  @ApiPropertyOptional({ description: 'CNPJ do emitente' })
  @IsOptional()
  @IsString()
  emitenteCnpj?: string;

  @ApiPropertyOptional({ description: 'Data inicial de emissão (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataInicio?: string;

  @ApiPropertyOptional({ description: 'Data final de emissão (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataFim?: string;

  @ApiPropertyOptional({
    description: 'Filtrar apenas documentos sem contabilização',
  })
  @IsOptional()
  @IsString()
  semContabilizacao?: string;
}
DTO_EOF

cat > src/modules/documentos-fiscais/dto/cancelar-documento.dto.ts <<'DTO_EOF'
import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CancelarDocumentoDto {
  @ApiProperty({ description: 'Motivo do cancelamento' })
  @IsString()
  @MinLength(5)
  motivo: string;
}
DTO_EOF

# ============================================================
# 2. SERVICO DE CONTABILIZACAO AUTOMATICA
# ============================================================
cat > src/modules/documentos-fiscais/services/contabilizacao.service.ts <<'SERVICE_EOF'
import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { DocumentoFiscalParseado } from '../parsers/interfaces';

interface RegraAplicavel {
  id: string;
  nome: string;
  prioridade: number;
  condicao: any;
  contaDebitoId: string;
  contaCreditoId: string;
  historicoTemplate: string | null;
}

/**
 * Serviço responsável por gerar lançamentos contábeis
 * a partir de documentos fiscais (XML).
 */
@Injectable()
export class ContabilizacaoService {
  private readonly logger = new Logger(ContabilizacaoService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Contabiliza um documento fiscal recém-importado.
   * Retorna o ID do lançamento criado, ou null se não conseguiu contabilizar.
   */
  async contabilizar(
    tenantId: string,
    empresaId: string,
    documentoId: string,
    doc: DocumentoFiscalParseado,
  ): Promise<string | null> {
    // 1. Localizar regra aplicável
    const regra = await this.encontrarRegra(tenantId, empresaId, doc);

    if (!regra) {
      this.logger.warn(
        `Sem regra de contabilização para doc ${doc.chaveAcesso}. ` +
        `Deixe pendente para contabilização manual.`,
      );
      return null;
    }

    // 2. Montar partidas
    const historico = this.montarHistorico(regra.historicoTemplate, doc);

    // 3. Criar lançamento + partidas + vincular ao documento
    const resultado = await this.prisma.$transaction(async (tx) => {
      const lancamento = await tx.lancamento.create({
        data: {
          tenantId,
          empresaId,
          dataLancamento: doc.dataEmissao,
          competencia: this.primeiroDiaMes(doc.dataEmissao),
          historico,
          documentoRef: doc.chaveAcesso,
          valorTotal: doc.valorTotal,
          partidas: {
            create: [
              {
                tenantId,
                contaId: regra.contaDebitoId,
                tipo: 'D',
                valor: doc.valorTotal,
              },
              {
                tenantId,
                contaId: regra.contaCreditoId,
                tipo: 'C',
                valor: doc.valorTotal,
              },
            ],
          },
        },
      });

      await tx.documentoFiscal.update({
        where: { id: documentoId },
        data: { lancamentoId: lancamento.id },
      });

      return lancamento;
    });

    this.logger.log(
      `Doc ${doc.chaveAcesso} contabilizado → lançamento ${resultado.id}`,
    );
    return resultado.id;
  }

  /**
   * Encontra a regra de contabilização aplicável ao documento.
   * Ordena por prioridade (menor número = maior prioridade).
   */
  private async encontrarRegra(
    tenantId: string,
    empresaId: string,
    doc: DocumentoFiscalParseado,
  ): Promise<RegraAplicavel | null> {
    const regras = await this.prisma.regraContabilizacao.findMany({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { prioridade: 'asc' },
    });

    for (const regra of regras) {
      if (this.regraCasa(regra.condicao, doc)) {
        return regra as RegraAplicavel;
      }
    }

    return null;
  }

  /**
   * Verifica se a condição (JSON) da regra bate com o documento.
   * Formato esperado do condicao:
   *   { "tipo": "NFE", "cfop": ["5102","6102"], "emitenteCnpj": "..." }
   * Todos os campos são opcionais e funcionam em AND.
   */
  private regraCasa(condicao: any, doc: DocumentoFiscalParseado): boolean {
    if (!condicao || typeof condicao !== 'object') return true;

    if (condicao.tipo && condicao.tipo !== doc.tipo) return false;

    if (condicao.cfop) {
      const lista = Array.isArray(condicao.cfop) ? condicao.cfop : [condicao.cfop];
      if (doc.cfopPrincipal && !lista.includes(doc.cfopPrincipal)) return false;
    }

    if (condicao.ncm) {
      const lista = Array.isArray(condicao.ncm) ? condicao.ncm : [condicao.ncm];
      if (doc.ncmPrincipal && !lista.includes(doc.ncmPrincipal)) return false;
    }

    if (condicao.emitenteCnpj && condicao.emitenteCnpj !== doc.emitenteCnpj) {
      return false;
    }

    if (condicao.destinatarioCnpj && condicao.destinatarioCnpj !== doc.destinatarioCnpj) {
      return false;
    }

    if (condicao.valorMinimo && doc.valorTotal < Number(condicao.valorMinimo)) {
      return false;
    }

    if (condicao.valorMaximo && doc.valorTotal > Number(condicao.valorMaximo)) {
      return false;
    }

    return true;
  }

  private montarHistorico(template: string | null, doc: DocumentoFiscalParseado): string {
    const base = `Importação ${doc.tipo} ${doc.numero}/${doc.serie} - ${doc.emitenteNome}`;
    if (!template) return base;

    return template
      .replace(/{numero}/g, doc.numero ?? '')
      .replace(/{serie}/g, doc.serie ?? '')
      .replace(/{emitente}/g, doc.emitenteNome ?? '')
      .replace(/{emitenteCnpj}/g, doc.emitenteCnpj ?? '')
      .replace(/{chave}/g, doc.chaveAcesso ?? '')
      .replace(/{valor}/g, String(doc.valorTotal));
  }

  private primeiroDiaMes(data: Date): Date {
    return new Date(data.getFullYear(), data.getMonth(), 1);
  }
}
SERVICE_EOF

# ============================================================
# 3. SERVICO DE IMPORTACAO
# ============================================================
cat > src/modules/documentos-fiscais/services/importacao.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { createHash } from 'crypto';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { S3Service } from '../../../infra/s3/s3.service';
import { DocumentoFiscalParser } from '../parsers';
import {
  DocumentoFiscalParseado,
  DocumentoDuplicadoError,
  XmlMalformadoError,
} from '../parsers/interfaces';
import { ContabilizacaoService } from './contabilizacao.service';
import { ImportarXmlDto } from '../dto/importar-xml.dto';

@Injectable()
export class ImportacaoService {
  private readonly logger = new Logger(ImportacaoService.name);
  private readonly parser = new DocumentoFiscalParser();

  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
    private readonly contabilizacao: ContabilizacaoService,
  ) {}

  async importarXml(tenantId: string, dto: ImportarXmlDto) {
    // 1. Validar empresa
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: dto.empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    // 2. Parsear o XML
    let doc: DocumentoFiscalParseado;
    try {
      doc = await this.parser.parse(dto.xml);
    } catch (err) {
      if (err instanceof XmlMalformadoError) {
        throw new BadRequestException(`XML inválido: ${err.message}`);
      }
      throw new BadRequestException(`Erro ao processar XML: ${(err as Error).message}`);
    }

    // 3. Verificar duplicidade
    const existente = await this.prisma.documentoFiscal.findFirst({
      where: { tenantId, chaveAcesso: doc.chaveAcesso },
    });
    if (existente && !dto.sobrescrever) {
      throw new ConflictException(
        `Documento já importado (chave ${doc.chaveAcesso}). Use sobrescrever=true para atualizar.`,
      );
    }

    // 4. Calcular hash e fazer upload no S3
    const hash = createHash('sha256').update(dto.xml).digest('hex');
    const s3Key = this.montarS3Key(tenantId, dto.empresaId, doc, hash);
    await this.s3.upload(s3Key, dto.xml, 'application/xml');

    // 5. Persistir no banco
    const documento = await this.prisma.$transaction(async (tx) => {
      if (existente && dto.sobrescrever) {
        return tx.documentoFiscal.update({
          where: { id: existente.id },
          data: this.montarDataAtualizacao(doc, s3Key, hash),
        });
      }

      return tx.documentoFiscal.create({
        data: {
          tenantId,
          empresaId: dto.empresaId,
          tipo: doc.tipo,
          chaveAcesso: doc.chaveAcesso,
          numero: doc.numero,
          serie: doc.serie,
          modelo: doc.modelo,
          emitenteCnpj: doc.emitenteCnpj,
          emitenteNome: doc.emitenteNome,
          destinatarioCnpj: doc.destinatarioCnpj,
          destinatarioNome: doc.destinatarioNome,
          dataEmissao: doc.dataEmissao,
          valorTotal: doc.valorTotal,
          valorIcms: doc.valorIcms,
          valorPis: doc.valorPis,
          valorCofins: doc.valorCofins,
          valorIss: doc.valorIss,
          cfopPrincipal: doc.cfopPrincipal,
          ncmPrincipal: doc.ncmPrincipal,
          situacao: 'AUTORIZADA',
          xmlS3Key: s3Key,
          xmlHash: hash,
          itens: doc.itens?.length
            ? {
                create: doc.itens.map((item) => ({
                  tenantId,
                  numeroItem: item.numeroItem,
                  codigoProduto: item.codigoProduto,
                  descricao: item.descricao,
                  ncm: item.ncm,
                  cfop: item.cfop,
                  quantidade: item.quantidade,
                  valorUnitario: item.valorUnitario,
                  valorTotal: item.valorTotal,
                  valorIcms: item.valorIcms,
                  aliquotaIcms: item.aliquotaIcms,
                  valorPis: item.valorPis,
                  valorCofins: item.valorCofins,
                })),
              }
            : undefined,
        },
        include: { itens: true },
      });
    });

    // 6. Contabilizar automaticamente (se solicitado)
    let lancamentoId: string | null = null;
    if (dto.contabilizarAutomaticamente !== false) {
      try {
        lancamentoId = await this.contabilizacao.contabilizar(
          tenantId,
          dto.empresaId,
          documento.id,
          doc,
        );
      } catch (err) {
        this.logger.warn(
          `Falha ao contabilizar doc ${doc.chaveAcesso}: ${(err as Error).message}`,
        );
      }
    }

    return {
      ...documento,
      lancamentoId,
      contabilizado: Boolean(lancamentoId),
    };
  }

  private montarS3Key(
    tenantId: string,
    empresaId: string,
    doc: DocumentoFiscalParseado,
    hash: string,
  ): string {
    const ano = doc.dataEmissao.getFullYear();
    const mes = String(doc.dataEmissao.getMonth() + 1).padStart(2, '0');
    return `tenants/${tenantId}/empresas/${empresaId}/xmls/${ano}/${mes}/${doc.tipo}-${doc.chaveAcesso}-${hash.slice(0, 8)}.xml`;
  }

  private montarDataAtualizacao(
    doc: DocumentoFiscalParseado,
    s3Key: string,
    hash: string,
  ) {
    return {
      numero: doc.numero,
      serie: doc.serie,
      modelo: doc.modelo,
      emitenteCnpj: doc.emitenteCnpj,
      emitenteNome: doc.emitenteNome,
      destinatarioCnpj: doc.destinatarioCnpj,
      destinatarioNome: doc.destinatarioNome,
      dataEmissao: doc.dataEmissao,
      valorTotal: doc.valorTotal,
      valorIcms: doc.valorIcms,
      valorPis: doc.valorPis,
      valorCofins: doc.valorCofins,
      valorIss: doc.valorIss,
      cfopPrincipal: doc.cfopPrincipal,
      ncmPrincipal: doc.ncmPrincipal,
      xmlS3Key: s3Key,
      xmlHash: hash,
    };
  }
}
SERVICE_EOF

# ============================================================
# 4. SERVICO PRINCIPAL DE DOCUMENTOS
# ============================================================
cat > src/modules/documentos-fiscais/documentos-fiscais.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { S3Service } from '../../infra/s3/s3.service';
import { ImportacaoService } from './services/importacao.service';
import { ImportarXmlDto } from './dto/importar-xml.dto';
import { FilterDocumentoDto } from './dto/filter-documento.dto';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class DocumentosFiscaisService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
    private readonly importacao: ImportacaoService,
  ) {}

  async importarXml(tenantId: string, dto: ImportarXmlDto) {
    return this.importacao.importarXml(tenantId, dto);
  }

  async listar(tenantId: string, filtros: FilterDocumentoDto) {
    const where: Prisma.DocumentoFiscalWhereInput = { tenantId };

    if (filtros.empresaId) where.empresaId = filtros.empresaId;
    if (filtros.tipo) where.tipo = filtros.tipo as any;
    if (filtros.situacao) where.situacao = filtros.situacao as any;
    if (filtros.chaveAcesso) where.chaveAcesso = filtros.chaveAcesso;
    if (filtros.emitenteCnpj) where.emitenteCnpj = filtros.emitenteCnpj;

    if (filtros.dataInicio || filtros.dataFim) {
      where.dataEmissao = {};
      if (filtros.dataInicio) (where.dataEmissao as any).gte = new Date(filtros.dataInicio);
      if (filtros.dataFim) (where.dataEmissao as any).lte = new Date(filtros.dataFim);
    }

    if (filtros.semContabilizacao === 'true') {
      where.lancamentoId = null;
    }

    const [total, documentos] = await Promise.all([
      this.prisma.documentoFiscal.count({ where }),
      this.prisma.documentoFiscal.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { [filtros.orderBy ?? 'dataEmissao']: filtros.order },
        include: { _count: { select: { itens: true } } },
      }),
    ]);

    return paginar(documentos, total, filtros.page, filtros.limit);
  }

  async buscarPorId(tenantId: string, id: string) {
    const doc = await this.prisma.documentoFiscal.findFirst({
      where: { id, tenantId },
      include: {
        itens: { orderBy: { numeroItem: 'asc' } },
        empresa: { select: { id: true, razaoSocial: true, cnpj: true } },
      },
    });
    if (!doc) throw new NotFoundException('Documento fiscal não encontrado');
    return doc;
  }

  async cancelar(tenantId: string, id: string, motivo: string) {
    const doc = await this.prisma.documentoFiscal.findFirst({
      where: { id, tenantId },
    });
    if (!doc) throw new NotFoundException('Documento não encontrado');

    if (doc.situacao === 'CANCELADA') {
      throw new BadRequestException('Documento já está cancelado');
    }

    return this.prisma.documentoFiscal.update({
      where: { id },
      data: { situacao: 'CANCELADA' },
    });
  }

  async gerarUrlXml(tenantId: string, id: string): Promise<{ url: string }> {
    const doc = await this.prisma.documentoFiscal.findFirst({
      where: { id, tenantId },
    });
    if (!doc || !doc.xmlS3Key) {
      throw new NotFoundException('XML não encontrado');
    }

    const url = await this.s3.presignedUrl(doc.xmlS3Key, 3600);
    return { url };
  }

  async estatisticas(tenantId: string, empresaId?: string) {
    const where: Prisma.DocumentoFiscalWhereInput = { tenantId };
    if (empresaId) where.empresaId = empresaId;

    const [total, autorizadas, canceladas, semContabilizacao] = await Promise.all([
      this.prisma.documentoFiscal.count({ where }),
      this.prisma.documentoFiscal.count({ where: { ...where, situacao: 'AUTORIZADA' } }),
      this.prisma.documentoFiscal.count({ where: { ...where, situacao: 'CANCELADA' } }),
      this.prisma.documentoFiscal.count({ where: { ...where, lancamentoId: null } }),
    ]);

    const somaValores = await this.prisma.documentoFiscal.aggregate({
      where: { ...where, situacao: 'AUTORIZADA' },
      _sum: { valorTotal: true },
    });

    return {
      total,
      autorizadas,
      canceladas,
      semContabilizacao,
      valorTotalAutorizadas: Number(somaValores._sum.valorTotal ?? 0),
    };
  }
}
SERVICE_EOF

# ============================================================
# 5. CONTROLLER
# ============================================================
cat > src/modules/documentos-fiscais/documentos-fiscais.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Get, Param, ParseUUIDPipe, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { DocumentosFiscaisService } from './documentos-fiscais.service';
import { ImportarXmlDto } from './dto/importar-xml.dto';
import { FilterDocumentoDto } from './dto/filter-documento.dto';
import { CancelarDocumentoDto } from './dto/cancelar-documento.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('documentos-fiscais')
@ApiBearerAuth()
@Controller('documentos-fiscais')
export class DocumentosFiscaisController {
  constructor(private readonly service: DocumentosFiscaisService) {}

  @Post('importar')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_IMPORTAR)
  @ApiOperation({ summary: 'Importa XML de documento fiscal (NFe/NFCe/CT-e/NFS-e)' })
  importar(@CurrentTenant() t: string, @Body() dto: ImportarXmlDto) {
    return this.service.importarXml(t, dto);
  }

  @Get()
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  @ApiOperation({ summary: 'Lista documentos com filtros e paginação' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterDocumentoDto) {
    return this.service.listar(t, filtros);
  }

  @Get('estatisticas')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  @ApiOperation({ summary: 'Estatísticas de documentos' })
  estatisticas(
    @CurrentTenant() t: string,
    @Query('empresaId') empresaId?: string,
  ) {
    return this.service.estatisticas(t, empresaId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Get(':id/xml')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_VER)
  @ApiOperation({ summary: 'URL assinada para download do XML (1h)' })
  urlXml(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.gerarUrlXml(t, id);
  }

  @Post(':id/cancelar')
  @RequirePermissions(PERMISSIONS.DOCUMENTO_EXCLUIR)
  @ApiOperation({ summary: 'Marca documento como cancelado' })
  cancelar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: CancelarDocumentoDto,
  ) {
    return this.service.cancelar(t, id, dto.motivo);
  }
}
CTRL_EOF

cat > src/modules/documentos-fiscais/documentos-fiscais.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { DocumentosFiscaisController } from './documentos-fiscais.controller';
import { DocumentosFiscaisService } from './documentos-fiscais.service';
import { ImportacaoService } from './services/importacao.service';
import { ContabilizacaoService } from './services/contabilizacao.service';

@Module({
  controllers: [DocumentosFiscaisController],
  providers: [DocumentosFiscaisService, ImportacaoService, ContabilizacaoService],
  exports: [DocumentosFiscaisService, ContabilizacaoService],
})
export class DocumentosFiscaisModule {}
MOD_EOF

# ============================================================
# 6. TESTES
# ============================================================
cat > src/modules/documentos-fiscais/testes/contabilizacao.service.spec.ts <<'TEST_EOF'
import { Test } from '@nestjs/testing';
import { ContabilizacaoService } from '../services/contabilizacao.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('ContabilizacaoService', () => {
  let service: ContabilizacaoService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      regraContabilizacao: { findMany: jest.fn() },
      lancamento: { create: jest.fn() },
      documentoFiscal: { update: jest.fn() },
      $transaction: jest.fn(async (fn: any) => fn(prisma)),
    };

    const module = await Test.createTestingModule({
      providers: [ContabilizacaoService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(ContabilizacaoService);
  });

  const docFake = {
    tipo: 'NFE' as const,
    chaveAcesso: '35240612345678901234550010000001231234567890',
    numero: '123',
    serie: '1',
    modelo: '55',
    emitenteCnpj: '12345678901234',
    emitenteNome: 'Fornecedor X',
    dataEmissao: new Date('2026-09-15'),
    valorTotal: 1000,
    cfopPrincipal: '5102',
    ncmPrincipal: '12345678',
    itens: [],
    xmlRaw: '',
  };

  it('retorna null quando não há regra aplicável', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([]);
    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);
    expect(r).toBeNull();
  });

  it('contabiliza com regra por CFOP', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'Compra mercadoria',
        prioridade: 1,
        condicao: { tipo: 'NFE', cfop: ['5102', '6102'] },
        contaDebitoId: 'c-estoque',
        contaCreditoId: 'c-fornecedor',
        historicoTemplate: 'NF {numero}/{serie} - {emitente}',
      },
    ]);
    prisma.lancamento.create.mockResolvedValue({ id: 'l1' });
    prisma.documentoFiscal.update.mockResolvedValue({});

    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);

    expect(r).toBe('l1');
    const chamada = prisma.lancamento.create.mock.calls[0][0];
    expect(chamada.data.historico).toContain('123/1');
    expect(chamada.data.historico).toContain('Fornecedor X');
    expect(chamada.data.partidas.create).toHaveLength(2);
  });

  it('não contabiliza se CFOP do doc não bate com a regra', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'Serviço',
        prioridade: 1,
        condicao: { tipo: 'NFE', cfop: ['5933'] },
        contaDebitoId: 'c1',
        contaCreditoId: 'c2',
        historicoTemplate: null,
      },
    ]);

    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);
    expect(r).toBeNull();
  });

  it('aplica regra por tipo mesmo sem CFOP', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'NFE genérica',
        prioridade: 10,
        condicao: { tipo: 'NFE' },
        contaDebitoId: 'c1',
        contaCreditoId: 'c2',
        historicoTemplate: null,
      },
    ]);
    prisma.lancamento.create.mockResolvedValue({ id: 'l2' });
    prisma.documentoFiscal.update.mockResolvedValue({});

    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);
    expect(r).toBe('l2');
  });

  it('usa competência = primeiro dia do mês da emissão', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'X',
        prioridade: 1,
        condicao: {},
        contaDebitoId: 'c1',
        contaCreditoId: 'c2',
        historicoTemplate: null,
      },
    ]);
    prisma.lancamento.create.mockResolvedValue({ id: 'l3' });
    prisma.documentoFiscal.update.mockResolvedValue({});

    await service.contabilizar('t1', 'e1', 'doc1', docFake);

    const chamada = prisma.lancamento.create.mock.calls[0][0];
    const competencia = chamada.data.competencia as Date;
    expect(competencia.getDate()).toBe(1);
    expect(competencia.getMonth()).toBe(8); // setembro (0-indexed)
  });
});
TEST_EOF

# ============================================================
# 7. REGISTRAR MODULO NO APP.MODULE
# ============================================================
python3 <<'PYEOF'
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'DocumentosFiscaisModule' not in content:
    content = content.replace(
        "import { CentrosCustoModule } from './modules/centros-custo/centros-custo.module';",
        "import { CentrosCustoModule } from './modules/centros-custo/centros-custo.module';\n"
        "import { DocumentosFiscaisModule } from './modules/documentos-fiscais/documentos-fiscais.module';"
    )
    content = content.replace(
        "    CentrosCustoModule,\n    HealthModule,",
        "    CentrosCustoModule,\n    DocumentosFiscaisModule,\n    HealthModule,"
    )
    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado com DocumentosFiscaisModule")
else:
    print("ℹ️  AppModule já está atualizado")
PYEOF

echo ""
echo "✅ Pacote F5 instalado!"
echo ""
echo "Rode agora:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"