import { createHash } from 'crypto';

export interface TransacaoOfx {
  dataMovimento: Date;
  descricao: string;
  documento?: string;
  valor: number;
  tipo: 'D' | 'C';
  hash: string;
}

export interface ExtratoOfx {
  bancoCodigo?: string;
  contaId?: string;
  agencia?: string;
  conta?: string;
  saldoInicial?: number;
  saldoFinal?: number;
  periodoInicio?: Date;
  periodoFim?: Date;
  transacoes: TransacaoOfx[];
}

export class OfxParserError extends Error {
  constructor(message: string) {
    super(message);
    this.name = 'OfxParserError';
  }
}

/**
 * Parser OFX (SGML/XML híbrido usado pelos bancos brasileiros).
 * Suporta OFX 1.x (SGML) e OFX 2.x (XML).
 */
export class OfxParser {
  parse(conteudo: string): ExtratoOfx {
    if (!conteudo || conteudo.trim().length < 20) {
      throw new OfxParserError('Arquivo OFX vazio ou muito pequeno');
    }

    // Normalizar quebras de linha
    const texto = conteudo.replace(/\r\n/g, '\n').replace(/\r/g, '\n');

    // Detectar banco e conta
    const bancoCodigo = this.extrairTag(texto, 'BANKID');
    const contaId = this.extrairTag(texto, 'ACCTID');
    const agencia = this.extrairTag(texto, 'BRANCHID');

    // Saldos
    const saldoInicial = this.extrairValor(texto, 'BALAMT', 1);
    const saldoFinal = this.extrairValor(texto, 'BALAMT', 2);

    // Período
    const dtInicio = this.extrairTag(texto, 'DTSTART');
    const dtFim = this.extrairTag(texto, 'DTEND');

    // Extrair blocos de transações <STMTTRN>...</STMTTRN>
    const transacoes: TransacaoOfx[] = [];
    const regex = /<STMTTRN>([\s\S]*?)<\/STMTTRN>/gi;
    let match: RegExpExecArray | null;

    while ((match = regex.exec(texto)) !== null) {
      const bloco = match[1];
      try {
        transacoes.push(this.parseTransacao(bloco));
      } catch {
        // Ignora transações malformadas
        continue;
      }
    }

    if (transacoes.length === 0) {
      throw new OfxParserError('Nenhuma transação encontrada no arquivo OFX');
    }

    return {
      bancoCodigo,
      contaId,
      agencia,
      saldoInicial,
      saldoFinal,
      periodoInicio: dtInicio ? this.parseDataOfx(dtInicio) : undefined,
      periodoFim: dtFim ? this.parseDataOfx(dtFim) : undefined,
      transacoes,
    };
  }

  private parseTransacao(bloco: string): TransacaoOfx {
    const tipoRaw = this.extrairTag(bloco, 'TRNTYPE') ?? 'DEBIT';
    const dataRaw = this.extrairTag(bloco, 'DTPOSTED');
    const valorRaw = this.extrairTag(bloco, 'TRNAMT');
    const descricao = this.extrairTag(bloco, 'MEMO') ?? this.extrairTag(bloco, 'NAME') ?? '';
    const documento = this.extrairTag(bloco, 'CHECKNUM') ?? this.extrairTag(bloco, 'REFNUM');

    if (!dataRaw || !valorRaw) {
      throw new OfxParserError('Transação OFX sem data ou valor');
    }

    const valor = parseFloat(valorRaw.replace(',', '.'));
    if (isNaN(valor)) {
      throw new OfxParserError(`Valor inválido: ${valorRaw}`);
    }

    const tipo: 'D' | 'C' = valor >= 0 ? 'C' : 'D';
    const dataMovimento = this.parseDataOfx(dataRaw);

    const hash = this.gerarHash({
      data: dataMovimento.toISOString().slice(0, 10),
      valor: Math.abs(valor).toFixed(2),
      descricao: descricao.trim(),
      documento: documento ?? '',
    });

    return {
      dataMovimento,
      descricao: descricao.trim(),
      documento,
      valor: Math.abs(valor),
      tipo,
      hash,
    };
  }

  private extrairTag(texto: string, tag: string): string | undefined {
    // OFX 1.x: <TAG>valor (sem fechamento)
    // OFX 2.x: <TAG>valor</TAG>
    const regex = new RegExp(`<${tag}>([^<\\n]+)`, 'i');
    const match = regex.exec(texto);
    return match ? match[1].trim() : undefined;
  }

  private extrairValor(texto: string, tag: string, ocorrencia: number): number | undefined {
    const regex = new RegExp(`<${tag}>([^<\\n]+)`, 'gi');
    let match: RegExpExecArray | null;
    let count = 0;
    while ((match = regex.exec(texto)) !== null) {
      count++;
      if (count === ocorrencia) {
        const valor = parseFloat(match[1].replace(',', '.'));
        return isNaN(valor) ? undefined : valor;
      }
    }
    return undefined;
  }

  private parseDataOfx(raw: string): Date {
    // Formato: YYYYMMDDHHMMSS[.XXX][-03:BRT]
    const limpo = raw.replace(/\[.*\]/, '').trim();
    const ano = parseInt(limpo.slice(0, 4), 10);
    const mes = parseInt(limpo.slice(4, 6), 10) - 1;
    const dia = parseInt(limpo.slice(6, 8), 10);
    return new Date(ano, mes, dia);
  }

  private gerarHash(dados: Record<string, string>): string {
    const conteudo = Object.values(dados).join('|');
    return createHash('sha256').update(conteudo).digest('hex');
  }
}
