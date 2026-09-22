export interface LinhaBalancete {
  contaId: string;
  codigo: string;
  nome: string;
  natureza: string;
  grau: number;
  saldoAnterior: number;
  debitos: number;
  creditos: number;
  saldoAtual: number;
}

export interface LinhaBalanco {
  grupo: string;
  subgrupo?: string;
  contaId?: string;
  codigo?: string;
  nome: string;
  valor: number;
  nivel: number;
}

export interface LinhaDre {
  linha: string;
  descricao: string;
  valor: number;
  percentualReceita: number;
  destaque?: 'total' | 'subtotal' | 'negrito';
}

export interface LinhaRazao {
  data: Date;
  lancamentoId: string;
  historico: string;
  documentoRef?: string;
  debito: number;
  credito: number;
  saldoAcumulado: number;
}

export interface LinhaLivroDiario {
  numero: number;
  data: Date;
  historico: string;
  documentoRef?: string;
  partidas: Array<{
    conta: string;
    nomeConta: string;
    tipo: 'D' | 'C';
    valor: number;
  }>;
  valorTotal: number;
}

export interface LinhaFluxoCaixa {
  data: Date;
  descricao: string;
  entrada: number;
  saida: number;
  saldoAcumulado: number;
}
