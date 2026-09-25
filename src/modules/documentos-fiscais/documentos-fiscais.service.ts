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

  async importarLote(
    tenantId: string,
    empresaId: string,
    xmls: string[],
  ): Promise<{
    total: number;
    sucesso: number;
    falhas: Array<{ erro: string; motivo: string }>;
  }> {
    let sucesso = 0;
    const falhas: Array<{ erro: string; motivo: string }> = [];

    for (const xml of xmls) {
      try {
        await this.importacao.importarXml(tenantId, {
          empresaId,
          xml,
        } as ImportarXmlDto);
        sucesso++;
      } catch (err) {
        falhas.push({
          erro: (err as Error).name,
          motivo: (err as Error).message,
        });
      }
    }

    return { total: xmls.length, sucesso, falhas };
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
