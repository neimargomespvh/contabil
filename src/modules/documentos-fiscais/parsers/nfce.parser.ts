import { NfeParser } from './nfe.parser';
import { DocumentoFiscalParseado } from './interfaces';
export class NfceParser {
  private nfe = new NfeParser();
  async parse(xml: string): Promise<DocumentoFiscalParseado> {
    return { ...(await this.nfe.parse(xml)), tipo: 'NFCE', modelo: '65' };
  }
}
