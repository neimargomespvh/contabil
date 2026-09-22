import { CsvParser, CsvParserError } from '../parsers/csv.parser';

describe('CsvParser', () => {
  const parser = new CsvParser();

  const CSV_VALIDO = `Data;Descrição;Valor;Documento
15/09/2026;PAGAMENTO FORNECEDOR;-150,50;DOC123
20/09/2026;RECEBIMENTO CLIENTE;1000,00;DOC124
25/09/2026;TARIFA BANCÁRIA;-15,00;`;

  const MAPEAMENTO = {
    separador: ';',
    data: 'Data',
    descricao: 'Descrição',
    valor: 'Valor',
    documento: 'Documento',
    formatoData: 'DD/MM/YYYY' as const,
    decimalVirgula: true,
  };

  it('faz parse de CSV válido', () => {
    const transacoes = parser.parse(CSV_VALIDO, MAPEAMENTO);
    expect(transacoes).toHaveLength(3);
  });

  it('interpreta valores com vírgula decimal', () => {
    const transacoes = parser.parse(CSV_VALIDO, MAPEAMENTO);
    const credito = transacoes.find((t) => t.tipo === 'C');
    const debito = transacoes.find((t) => t.tipo === 'D');
    expect(credito?.valor).toBe(1000);
    expect(debito?.valor).toBe(150.5);
  });

  it('interpreta datas corretamente', () => {
    const transacoes = parser.parse(CSV_VALIDO, MAPEAMENTO);
    const primeira = transacoes[0];
    expect(primeira.dataMovimento.getDate()).toBe(15);
    expect(primeira.dataMovimento.getMonth()).toBe(8); // setembro
    expect(primeira.dataMovimento.getFullYear()).toBe(2026);
  });

  it('detecta separador automaticamente', () => {
    const csv = CSV_VALIDO.replace(/;/g, ',');
    const semSeparador = { ...MAPEAMENTO, separador: undefined };
    const transacoes = parser.parse(csv, semSeparador);
    expect(transacoes).toHaveLength(3);
  });

  it('rejeita CSV vazio', () => {
    expect(() => parser.parse('', MAPEAMENTO)).toThrow(CsvParserError);
  });

  it('rejeita CSV sem colunas obrigatórias', () => {
    const invalido = `A;B\n1;2`;
    expect(() => parser.parse(invalido, MAPEAMENTO)).toThrow(CsvParserError);
  });

  it('gera hash determinístico', () => {
    const a = parser.parse(CSV_VALIDO, MAPEAMENTO);
    const b = parser.parse(CSV_VALIDO, MAPEAMENTO);
    expect(a.map((t) => t.hash)).toEqual(b.map((t) => t.hash));
  });
});
