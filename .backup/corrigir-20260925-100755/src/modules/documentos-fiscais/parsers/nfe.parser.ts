cat > src/modules/documentos-fiscais/parsers/nfe.parser.ts <<'EOF'
import { parseStringPromise } from 'xml2js';
import {
  DocumentoFiscalParseado,
  ItemDocumentoParseado,
  SituacaoDocumento,
  XmlMalformadoError,
  CamposObrigatoriosError,
} from './interfaces';

export class NfeParser {
  async parse(xml: string): Promise<DocumentoFiscalParseado> {
    const raw: any = await parseStringPromise(xml, {
      explicitArray: false,
      mergeAttrs: true,
      trim: true,
    }).catch(() => {
      throw new XmlMalformadoError('XML inválido');
    });

    const infNFe = raw?.nfeProc?.NFe?.infNFe ?? raw?.NFe?.infNFe;
    if (!infNFe) throw new XmlMalformadoError('Estrutura NFe ausente');

    const chave = (infNFe.Id ?? '').replace(/^NFe/i, '').trim();
    if (!chave) throw new CamposObrigatoriosError(['chaveAcesso']);

    const ide = infNFe.ide ?? {};
    const emit = infNFe.emit ?? {};
    const dest = infNFe.dest ?? {};
    const total = infNFe.total?.ICMSTot ?? {};

    if (!emit.CNPJ) throw new CamposObrigatoriosError(['emitenteCnpj']);
    if (!ide.nNF) throw new CamposObrigatoriosError(['numero']);

    const det = Array.isArray(infNFe.det)
      ? infNFe.det
      : [infNFe.det].filter(Boolean);

    // Detectar situação via cStat do protocolo
    const cStat = String(
      raw?.nfeProc?.protNFe?.infProt?.cStat ??
        raw?.protNFe?.infProt?.cStat ??
        '100',
    );

    return {
      tipo: 'NFE',
      chaveAcesso: chave,
      numero: String(ide.nNF),
      serie: String(ide.serie ?? '1'),
      modelo: String(ide.mod ?? '55'),
      emitenteCnpj: emit.CNPJ,
      emitenteNome: emit.xNome ?? '',
      destinatarioCnpj: dest.CNPJ ?? dest.CPF,
      destinatarioNome: dest.xNome,
      dataEmissao: new Date(ide.dhEmi ?? ide.dEmi ?? Date.now()),
      valorTotal: this.toNumber(total.vNF),
      valorIcms: this.toNumber(total.vICMS),
      valorPis: this.toNumber(total.vPIS),
      valorCofins: this.toNumber(total.vCOFINS),
      cfopPrincipal: det[0]?.prod?.CFOP,
      ncmPrincipal: det[0]?.prod?.NCM,
      situacao: this.mapearSituacao(cStat),
      itens: det.map((d: any) => this.parseItem(d)),
      xmlRaw: xml,
    };
  }

  private parseItem(d: any): ItemDocumentoParseado {
    const prod = d.prod ?? {};
    const imposto = d.imposto ?? {};

    const icmsGroup = imposto.ICMS ?? {};
    const icmsKey = Object.keys(icmsGroup).find((k) => k.startsWith('ICMS'));
    const icms = icmsKey ? icmsGroup[icmsKey] : {};

    const pis = imposto.PIS?.PISAliq ?? imposto.PIS?.PISOutr ?? {};
    const cofins =
      imposto.COFINS?.COFINSAliq ?? imposto.COFINS?.COFINSOutr ?? {};

    return {
      numeroItem: parseInt(d.attr?.nItem ?? '0', 10),
      codigoProduto: prod.cProd,
      descricao: prod.xProd,
      ncm: prod.NCM,
      cfop: prod.CFOP,
      quantidade: this.toNumber(prod.qCom),
      valorUnitario: this.toNumber(prod.vUnCom),
      valorTotal: this.toNumber(prod.vProd),
      valorIcms: this.toNumber(icms.vICMS),
      aliquotaIcms: this.toNumber(icms.pICMS),
      valorPis: this.toNumber(pis.vPIS),
      valorCofins: this.toNumber(cofins.vCOFINS),
    };
  }

  private mapearSituacao(cStat: string): SituacaoDocumento {
    switch (cStat) {
      case '100':
      case '150':
        return 'AUTORIZADA';
      case '101':
      case '102':
      case '135':
      case '151':
      case '155':
        return 'CANCELADA';
      case '110':
      case '301':
      case '302':
      case '303':
        return 'DENEGADA';
      default:
        return 'AUTORIZADA';
    }
  }

  private toNumber(value: any): number {
    if (value === undefined || value === null || value === '') return 0;
    const n = parseFloat(String(value).replace(',', '.'));
    return isNaN(n) ? 0 : n;
  }
}
EOF

echo "✅ Patch 2 aplicado"