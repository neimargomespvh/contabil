import { NfeParser } from '../nfe.parser';
import { XmlMalformadoError } from '../interfaces';
describe('NfeParser', () => {
  const p = new NfeParser();
  it('rejeita XML malformado', async () => {
    await expect(p.parse('<invalid')).rejects.toThrow(XmlMalformadoError);
  });
});
