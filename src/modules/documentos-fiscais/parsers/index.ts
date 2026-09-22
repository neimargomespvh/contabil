import { NfeParser } from './nfe.parser';
import { NfceParser } from './nfce.parser';
import { CteParser } from './cte.parser';
import { NfseParser } from './nfse.parser';
import { XmlMalformadoError } from './interfaces';
export * from './interfaces';
export class DocumentoFiscalParser {
  private nfe = new NfeParser(); private nfce = new NfceParser();
  private cte = new CteParser(); private nfse = new NfseParser();
  async parse(xml: string) {
    if (xml.includes('<nfeProc') || xml.includes('<NFe')) {
      return xml.includes('<mod>65</mod>') || xml.includes('mod="65"')
        ? this.nfce.parse(xml) : this.nfe.parse(xml);
    }
    if (xml.includes('<cteProc') || xml.includes('<CTe')) return this.cte.parse(xml);
    if (xml.includes('<CompNfse')) return this.nfse.parse(xml);
    throw new XmlMalformadoError('Tipo não reconhecido');
  }
}
