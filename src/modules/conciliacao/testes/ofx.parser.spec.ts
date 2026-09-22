import { OfxParser, OfxParserError } from '../parsers/ofx.parser';

describe('OfxParser', () => {
  const parser = new OfxParser();

  const OFX_VALIDO = `
OFXHEADER:100
DATA:OFXSGML
VERSION:102

<OFX>
<BANKMSGSRSV1>
<STMTTRNRS>
<STMTRS>
<BANKACCTFROM>
<BANKID>341
<ACCTID>12345-6
<BRANCHID>1234
</BANKACCTFROM>
<BANKTRANLIST>
<DTSTART>20260901
<DTEND>20260930
<STMTTRN>
<TRNTYPE>DEBIT
<DTPOSTED>20260915
<TRNAMT>-150.50
<MEMO>PAGAMENTO FORNECEDOR ABC
</STMTTRN>
<STMTTRN>
<TRNTYPE>CREDIT
<DTPOSTED>20260920
<TRNAMT>1000.00
<MEMO>RECEBIMENTO CLIENTE XYZ
</STMTTRN>
</BANKTRANLIST>
</STMTRS>
</STMTTRNRS>
</BANKMSGSRSV1>
</OFX>
  `.trim();

  it('faz parse de OFX válido', () => {
    const extrato = parser.parse(OFX_VALIDO);
    expect(extrato.bancoCodigo).toBe('341');
    expect(extrato.contaId).toBe('12345-6');
    expect(extrato.transacoes).toHaveLength(2);
  });

  it('interpreta débito e crédito corretamente', () => {
    const extrato = parser.parse(OFX_VALIDO);
    const debito = extrato.transacoes.find((t) => t.tipo === 'D');
    const credito = extrato.transacoes.find((t) => t.tipo === 'C');

    expect(debito?.valor).toBe(150.5);
    expect(credito?.valor).toBe(1000);
  });

  it('gera hash único por transação', () => {
    const extrato = parser.parse(OFX_VALIDO);
    const hashes = extrato.transacoes.map((t) => t.hash);
    expect(new Set(hashes).size).toBe(hashes.length);
  });

  it('rejeita conteúdo vazio', () => {
    expect(() => parser.parse('')).toThrow(OfxParserError);
  });

  it('rejeita OFX sem transações', () => {
    const vazio = OFX_VALIDO.replace(/<STMTTRN>[\s\S]*?<\/STMTTRN>/g, '');
    expect(() => parser.parse(vazio)).toThrow(OfxParserError);
  });
});
