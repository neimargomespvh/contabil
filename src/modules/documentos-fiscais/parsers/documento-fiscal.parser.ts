import { NfeParser } from './nfe.parser';
import { NfceParser } from './nfce.parser';
import { CteParser } from './cte.parser';
import { NfseParser } from './nfse.parser';
import { DocumentoFiscalParseado, XmlMalformadoError } from './interfaces';

export class DocumentoFiscalParser {
  private readonly nfe = new NfeParser();
  private readonly nfce = new NfceParser();
  private readonly cte = new CteParser();
  private readonly nfse = new NfseParser();

  async parse(xml: string): Promise<DocumentoFiscalParseado> {
    const trimmed = xml.trim();

    if (trimmed.includes('<CompNfse')) return this.nfse.parse(trimmed);
    if (trimmed.includes('<cteProc') || trimmed.includes('<CTe'))
      return this.cte.parse(trimmed);

    if (trimmed.includes('<nfeProc') || trimmed.includes('<NFe')) {
      if (trimmed.includes('<mod>65</mod>') || trimmed.includes('mod="65"')) {
        return this.nfce.parse(trimmed);
      }
      return this.nfe.parse(trimmed);
    }

    throw new XmlMalformadoError('Tipo de documento não reconhecido');
  }
}