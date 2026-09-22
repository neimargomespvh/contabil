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
