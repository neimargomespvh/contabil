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
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: dto.empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    let doc: DocumentoFiscalParseado;
    try {
      doc = await this.parser.parse(dto.xml);
    } catch (err) {
      if (err instanceof XmlMalformadoError) {
        throw new BadRequestException(`XML inválido: ${err.message}`);
      }
      throw new BadRequestException(
        `Erro ao processar XML: ${(err as Error).message}`,
      );
    }

    const existente = await this.prisma.documentoFiscal.findFirst({
      where: { tenantId, chaveAcesso: doc.chaveAcesso },
    });
    if (existente && !dto.sobrescrever) {
      throw new ConflictException(
        `Documento já importado (chave ${doc.chaveAcesso}). Use sobrescrever=true para atualizar.`,
      );
    }

    const hash = createHash('sha256').update(dto.xml).digest('hex');
    const s3Key = this.montarS3Key(tenantId, dto.empresaId, doc, hash);
    await this.s3.upload(s3Key, dto.xml, 'application/xml');

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
          situacao: doc.situacao,
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

    let lancamentoId: string | null = null;
    const deveContabilizar =
      dto.contabilizarAutomaticamente !== false &&
      doc.situacao === 'AUTORIZADA';

    if (deveContabilizar) {
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
      situacao: doc.situacao,
      xmlS3Key: s3Key,
      xmlHash: hash,
    };
  }
}