import { parseStringPromise } from 'xml2js';
import { DocumentoFiscalParseado, XmlMalformadoError } from './interfaces';
export class CteParser {
  async parse(xml: string): Promise<DocumentoFiscalParseado> {
    const raw: any = await parseStringPromise(xml, { explicitArray: false, mergeAttrs: true })
      .catch(() => { throw new XmlMalformadoError('XML CT-e inválido'); });
    const infCte = raw?.cteProc?.CTe?.infCte ?? raw?.CTe?.infCte;
    if (!infCte) throw new XmlMalformadoError('Estrutura CT-e ausente');
    return {
      tipo: 'CTE', chaveAcesso: (infCte.Id ?? '').replace('CTe',''),
      numero: infCte.ide.nCT, serie: infCte.ide.serie, modelo: '57',
      emitenteCnpj: infCte.emit.CNPJ, emitenteNome: infCte.emit.xNome,
      dataEmissao: new Date(infCte.ide.dhEmi),
      valorTotal: parseFloat(infCte.vPrest?.vTPrest ?? '0'), itens: [], xmlRaw: xml,
    };
  }
}
