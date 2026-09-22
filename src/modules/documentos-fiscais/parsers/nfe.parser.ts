import { parseStringPromise } from 'xml2js';
import { DocumentoFiscalParseado, XmlMalformadoError, CamposObrigatoriosError } from './interfaces';
export class NfeParser {
  async parse(xml: string): Promise<DocumentoFiscalParseado> {
    const raw: any = await parseStringPromise(xml, { explicitArray: false, mergeAttrs: true })
      .catch(() => { throw new XmlMalformadoError('XML inválido'); });
    const infNFe = raw?.nfeProc?.NFe?.infNFe ?? raw?.NFe?.infNFe;
    if (!infNFe) throw new XmlMalformadoError('Estrutura NFe ausente');
    const chave = (infNFe.Id ?? '').replace('NFe','');
    if (!chave) throw new CamposObrigatoriosError(['chaveAcesso']);
    const ide = infNFe.ide, emit = infNFe.emit, dest = infNFe.dest, total = infNFe.total?.ICMSTot;
    const det = Array.isArray(infNFe.det) ? infNFe.det : [infNFe.det].filter(Boolean);
    return {
      tipo: 'NFE', chaveAcesso: chave, numero: ide.nNF, serie: ide.serie, modelo: ide.mod ?? '55',
      emitenteCnpj: emit.CNPJ, emitenteNome: emit.xNome,
      destinatarioCnpj: dest?.CNPJ ?? dest?.CPF, destinatarioNome: dest?.xNome,
      dataEmissao: new Date(ide.dhEmi ?? ide.dEmi), valorTotal: parseFloat(total?.vNF ?? '0'),
      valorIcms: parseFloat(total?.vICMS ?? '0'), valorPis: parseFloat(total?.vPIS ?? '0'),
      valorCofins: parseFloat(total?.vCOFINS ?? '0'),
      itens: det.map((d: any) => ({
        numeroItem: parseInt(d.attr?.nItem ?? '0', 10),
        codigoProduto: d.prod?.cProd, descricao: d.prod?.xProd, ncm: d.prod?.NCM, cfop: d.prod?.CFOP,
        quantidade: parseFloat(d.prod?.qCom ?? '0'), valorUnitario: parseFloat(d.prod?.vUnCom ?? '0'),
        valorTotal: parseFloat(d.prod?.vProd ?? '0'),
      })),
      xmlRaw: xml,
    };
  }
}
