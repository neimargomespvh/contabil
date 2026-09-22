export interface User {
  id: string;
  nome: string;
  email: string;
  tenantId: string;
  tenantNome: string;
  permissions: string[];
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}

// ============ EMPRESA ============
export type RegimeTributario = 'SIMPLES' | 'PRESUMIDO' | 'REAL' | 'MEI';
export type AnexoSimples = 'I' | 'II' | 'III' | 'IV' | 'V';
export type EmpresaStatus = 'ATIVA' | 'INATIVA' | 'BAIXADA';

export interface Endereco {
  logradouro?: string;
  numero?: string;
  complemento?: string;
  bairro?: string;
  cidade?: string;
  uf?: string;
  cep?: string;
}

export interface Empresa {
  id: string;
  razaoSocial: string;
  nomeFantasia?: string;
  cnpj: string;
  inscricaoEstadual?: string;
  inscricaoMunicipal?: string;
  regimeTributario: RegimeTributario;
  anexoSimples?: AnexoSimples;
  cnaePrincipal?: string;
  cnaesSecundarios?: string[];
  dataAbertura?: string;
  dataRegimeAtual?: string;
  endereco?: Endereco;
  email?: string;
  telefone?: string;
  responsavelNome?: string;
  responsavelCpf?: string;
  status: EmpresaStatus;
  observacoes?: string;
  createdAt: string;
  updatedAt: string;
  _count?: {
    socios: number;
    lancamentos: number;
  };
}

export interface CreateEmpresaPayload {
  razaoSocial: string;
  nomeFantasia?: string;
  cnpj: string;
  inscricaoEstadual?: string;
  inscricaoMunicipal?: string;
  regimeTributario: RegimeTributario;
  anexoSimples?: AnexoSimples;
  cnaePrincipal?: string;
  dataAbertura?: string;
  dataRegimeAtual?: string;
  endereco?: Endereco;
  email?: string;
  telefone?: string;
  responsavelNome?: string;
  responsavelCpf?: string;
  observacoes?: string;
}

export interface FilterEmpresas {
  busca?: string;
  regimeTributario?: RegimeTributario;
  status?: EmpresaStatus;
  page?: number;
  limit?: number;
}

// ============ SÓCIO ============
export interface Socio {
  id: string;
  empresaId: string;
  nome: string;
  cpf: string;
  participacao: number;
  proLabore?: number;
  dataEntrada?: string;
  dataSaida?: string;
  status: string;
  createdAt: string;
}

export interface CreateSocioPayload {
  empresaId: string;
  nome: string;
  cpf: string;
  participacao: number;
  proLabore?: number;
  dataEntrada?: string;
}

export interface UpdateSocioPayload {
  nome?: string;
  cpf?: string;
  participacao?: number;
  proLabore?: number;
  dataEntrada?: string;
  dataSaida?: string;
}

export interface SociosResponse {
  data: Socio[];
  resumo: {
    total: number;
    participacaoTotal: number;
    participacaoCompleta: boolean;
  };
}

// ============ PAGINAÇÃO ============
export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

// ============ PLANO DE CONTAS ============
export type NaturezaConta = 'ATIVO' | 'PASSIVO' | 'PATRIMONIO_LIQUIDO' | 'RECEITA' | 'DESPESA' | 'CUSTO';
export type TipoConta = 'SINTETICA' | 'ANALITICA';

export interface Conta {
  id: string;
  planoContasId: string;
  contaPaiId?: string;
  codigo: string;
  nome: string;
  natureza: NaturezaConta;
  tipo: TipoConta;
  grau: number;
  aceitaLancamento: boolean;
  dreLinha?: string;
  status: 'ATIVO' | 'INATIVO';
}

export interface ContaArvore extends Conta {
  filhas: ContaArvore[];
}

export interface PlanoContas {
  id: string;
  empresaId: string;
  nome: string;
  versao: number;
  vigenciaInicio: string;
  vigenciaFim?: string;
  status: 'ATIVO' | 'INATIVO';
}

// ============ CENTRO DE CUSTO ============
export interface CentroCusto {
  id: string;
  empresaId: string;
  codigo: string;
  nome: string;
  status: 'ATIVO' | 'INATIVO';
}

// ============ LANÇAMENTO ============
export type TipoPartida = 'D' | 'C';
export type StatusLancamento = 'ATIVO' | 'ESTORNADO';

export interface Partida {
  id: string;
  lancamentoId: string;
  contaId: string;
  centroCustoId?: string;
  tipo: TipoPartida;
  valor: number | string;
  conta?: Conta;
  centroCusto?: CentroCusto;
}

export interface Lancamento {
  id: string;
  empresaId: string;
  loteId?: string;
  numero: number;
  dataLancamento: string;
  competencia: string;
  historico: string;
  documentoRef?: string;
  valorTotal: number | string;
  status: StatusLancamento;
  estornoDeId?: string;
  createdAt: string;
  partidas?: Partida[];
  empresa?: { razaoSocial: string; cnpj: string };
}

export interface CreatePartidaPayload {
  contaId: string;
  centroCustoId?: string;
  tipo: TipoPartida;
  valor: number;
}

export interface CreateLancamentoPayload {
  empresaId: string;
  loteId?: string;
  dataLancamento: string;
  competencia: string;
  historico: string;
  documentoRef?: string;
  partidas: CreatePartidaPayload[];
}

export interface FilterLancamentos {
  empresaId?: string;
  competencia?: string;
  page?: number;
  limit?: number;
}

// ============ FECHAMENTO ============
export type StatusFechamento = 'ABERTO' | 'FECHADO';

export interface FechamentoPeriodo {
  id: string;
  empresaId: string;
  competencia: string;
  status: StatusFechamento;
  fechadoPor?: string;
  fechadoEm?: string;
}
