import { createHash } from 'crypto';

export interface MapeamentoCsv {
  separador?: string;
  data: string;
  descricao: string;
  valor: string;
  documento?: string;
  formatoData?: 'DD/MM/YYYY' | 'YYYY-MM-DD' | 'DD-MM-YYYY';
  decimalVirgula?: boolean;
  linhaCabecalho?: number;
}

export interface TransacaoCsv {
  dataMovimento: Date;
  descricao: string;
  documento?: string;
  valor: number;
  tipo: 'D' | 'C';
  hash: string;
}

export class CsvParserError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'CsvParserError';
  }
}

export class CsvParser {
  parse(conteudo: string, mapeamento: MapeamentoCsv): TransacaoCsv[] {
    if (!conteudo) throw new CsvParserError('Arquivo vazio');

    const sep = mapeamento.separador ?? this.detectarSeparador(conteudo);
    const linhas = conteudo.split(/\r?\n/).filter((l) => l.trim().length > 0);

    if (linhas.length < 2) {
      throw new CsvParserError('CSV precisa ter cabeçalho + pelo menos 1 linha');
    }

    const linhaCabecalho = mapeamento.linhaCabecalho ?? 0;
    const header = this.parseLinha(linhas[linhaCabecalho], sep);
    const idxData = this.indiceColuna(header, mapeamento.data);
    const idxDesc = this.indiceColuna(header, mapeamento.descricao);
    const idxVal = this.indiceColuna(header, mapeamento.valor);
    const idxDoc = mapeamento.documento
      ? this.indiceColunaOpcional(header, mapeamento.documento)
      : -1;

    if (idxData === -1) throw new CsvParserError(`Coluna "${mapeamento.data}" não encontrada`);
    if (idxDesc === -1) throw new CsvParserError(`Coluna "${mapeamento.descricao}" não encontrada`);
    if (idxVal === -1) throw new CsvParserError(`Coluna "${mapeamento.valor}" não encontrada`);

    const transacoes: TransacaoCsv[] = [];

    for (let i = linhaCabecalho + 1; i < linhas.length; i++) {
      const linha = linhas[i];
      try {
        const cols = this.parseLinha(linha, sep);
        if (cols.length < Math.max(idxData, idxDesc, idxVal) + 1) continue;

        const dataMovimento = this.parseData(cols[idxData], mapeamento.formatoData);
        const descricao = cols[idxDesc].trim();
        const valorStr = cols[idxVal].trim();
        const valor = this.parseValor(valorStr, mapeamento.decimalVirgula);

        if (isNaN(valor) || !descricao) continue;

        const tipo: 'D' | 'C' = valor >= 0 ? 'C' : 'D';
        const documento = idxDoc >= 0 ? cols[idxDoc]?.trim() : undefined;

        const hash = createHash('sha256')
          .update(`${dataMovimento.toISOString().slice(0, 10)}|${Math.abs(valor).toFixed(2)}|${descricao}|${documento ?? ''}`)
          .digest('hex');

        transacoes.push({
          dataMovimento,
          descricao,
          documento,
          valor: Math.abs(valor),
          tipo,
          hash,
        });
      } catch {
        continue;
      }
    }

    if (transacoes.length === 0) {
      throw new CsvParserError('Nenhuma transação válida encontrada no CSV');
    }

    return transacoes;
  }

  private detectarSeparador(conteudo: string): string {
    const primeiraLinha = conteudo.split(/\r?\n/)[0] ?? '';
    const contagem = {
      ',': (primeiraLinha.match(/,/g) ?? []).length,
      ';': (primeiraLinha.match(/;/g) ?? []).length,
      '\t': (primeiraLinha.match(/\t/g) ?? []).length,
    };
    return Object.entries(contagem).sort((a, b) => b[1] - a[1])[0][0];
  }

  private parseLinha(linha: string, sep: string): string[] {
    // Parser simples — não trata aspas com separador interno
    return linha.split(sep).map((c) => c.replace(/^"|"$/g, '').trim());
  }

  private indiceColuna(header: string[], nome: string): number {
    const idx = header.findIndex(
      (h) => h.toLowerCase() === nome.toLowerCase() || h.toLowerCase().includes(nome.toLowerCase()),
    );
    return idx;
  }

  private indiceColunaOpcional(header: string[], nome: string): number {
    return this.indiceColuna(header, nome);
  }

  private parseData(raw: string, formato?: MapeamentoCsv['formatoData']): Date {
    const limpo = raw.trim().split(' ')[0]; // remove hora se houver

    if (formato === 'YYYY-MM-DD') {
      const [a, m, d] = limpo.split('-').map(Number);
      return new Date(a, m - 1, d);
    }

    if (formato === 'DD-MM-YYYY') {
      const [d, m, a] = limpo.split('-').map(Number);
      return new Date(a, m - 1, d);
    }

    // Padrão: DD/MM/YYYY
    const [d, m, a] = limpo.split('/').map(Number);
    if (isNaN(d) || isNaN(m) || isNaN(a)) {
      // Tentar ISO
      const iso = new Date(limpo);
      if (!isNaN(iso.getTime())) return iso;
      throw new CsvParserError(`Data inválida: ${raw}`);
    }
    return new Date(a, m - 1, d);
  }

  private parseValor(raw: string, decimalVirgula?: boolean): number {
    let limpo = raw.replace(/[R$\s]/g, '').trim();

    if (decimalVirgula !== false) {
      // Formato brasileiro: 1.234,56 → 1234.56
      if (limpo.includes(',')) {
        limpo = limpo.replace(/\./g, '').replace(',', '.');
      }
    }

    // Tratar parênteses como negativo (alguns bancos usam)
    const negativo = limpo.startsWith('(') && limpo.endsWith(')');
    limpo = limpo.replace(/[()]/g, '');

    const valor = parseFloat(limpo);
    return negativo ? -valor : valor;
  }
}
