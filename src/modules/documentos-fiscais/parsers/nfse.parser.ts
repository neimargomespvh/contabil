import { parseStringPromise } from 'xml2js';
import { DocumentoFiscalParseado, XmlMalformadoError } from './interfaces';
export class NfseParser {
  async parse(xml: string): Promise<DocumentoFiscalParseado> {
    const raw: any = await parseStringPromise(xml, { explicitArray: false, mergeAttrs: true })
      .catch(() => { throw new XmlMalformadoError('XML NFS-e inválido'); });
    const inf = raw?.CompNfse?.Nfse?.InfNfse;
    if (!inf) throw new XmlMalformadoError('Estrutura NFS-e ausente');
    return {
      tipo: 'NFSE', chaveAcesso: inf.Numero, numero: inf.Numero, serie: '',
      modelo: 'NFSE', emitenteCnpj: inf.PrestadorServico.IdentificacaoPrestador.Cnpj,
      emitenteNome: inf.PrestadorServico.RazaoSocial,
      dataEmissao: new Date(inf.DataEmissao),
      valorTotal: parseFloat(inf.Servico?.Valores?.ValorServicos ?? '0'),
      itens: [], xmlRaw: xml,
    };
  }
}
