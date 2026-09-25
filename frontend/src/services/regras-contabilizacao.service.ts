import { api } from '@/lib/axios';
import type { PaginatedResponse } from '@/types';

export type StatusRegra = 'ATIVO' | 'INATIVO';
export type TipoDocumento = 'NFE' | 'NFCE' | 'CTE' | 'NFSE';

export interface CondicaoRegra {
  cfop?: string;
  cfopPrefix?: string;
  ncm?: string;
  ncmPrefix?: string;
  emitenteCnpj?: string;
  destinatarioCnpj?: string;
  tipo?: TipoDocumento;
}

export interface ContaResumo {
  id: string;
  codigo: string;
  nome: string;
}

export interface RegraContabilizacao {
  id: string;
  tenantId: string;
  empresaId: string;
  nome: string;
  prioridade: number;
  condicao: CondicaoRegra;
  contaDebitoId: string;
  contaCreditoId: string;
  historicoTemplate: string | null;
  status: StatusRegra;
  createdAt: string;
  updatedAt?: string;
  contaDebito?: ContaResumo;
  contaCredito?: ContaResumo;
  empresa?: { id: string; razaoSocial: string; cnpj: string };
}

export interface CreateRegraPayload {
  empresaId: string;
  nome: string;
  prioridade: number;
  condicao: CondicaoRegra;
  contaDebitoId: string;
  contaCreditoId: string;
  historicoTemplate?: string;
}

export interface UpdateRegraPayload extends Partial<Omit<CreateRegraPayload, 'empresaId'>> {}

export interface FilterRegras {
  empresaId: string;
  nome?: string;
  status?: StatusRegra;
  cfop?: string;
  ncm?: string;
  page?: number;
  limit?: number;
}

export interface SimulacaoResultado {
  casou: boolean;
  motivo?: string;
  regra?: {
    id: string;
    nome: string;
    prioridade: number;
    historicoTemplate: string | null;
    contaDebito: ContaResumo;
    contaCredito: ContaResumo;
  };
  documento?: {
    tipo: string;
    chaveAcesso: string;
    cfop: string | null;
    ncm: string | null;
    emitenteCnpj: string;
    valorTotal?: number;
    situacao?: string;
  };
  historicoPreview?: string;
}

export const regrasContabilizacaoService = {
  async listar(filtros: FilterRegras): Promise<PaginatedResponse<RegraContabilizacao>> {
    const { data } = await api.get<PaginatedResponse<RegraContabilizacao>>(
      '/regras-contabilizacao',
      {
        params: {
          empresaId: filtros.empresaId,
          nome: filtros.nome || undefined,
          status: filtros.status || undefined,
          cfop: filtros.cfop || undefined,
          ncm: filtros.ncm || undefined,
          page: filtros.page ?? 1,
          limit: filtros.limit ?? 20,
        },
      },
    );
    return data;
  },

  async buscarPorId(id: string): Promise<RegraContabilizacao> {
    const { data } = await api.get<RegraContabilizacao>(`/regras-contabilizacao/${id}`);
    return data;
  },

  async criar(payload: CreateRegraPayload): Promise<RegraContabilizacao> {
    const { data } = await api.post<RegraContabilizacao>('/regras-contabilizacao', payload);
    return data;
  },

  async atualizar(id: string, payload: UpdateRegraPayload): Promise<RegraContabilizacao> {
    const { data } = await api.patch<RegraContabilizacao>(
      `/regras-contabilizacao/${id}`,
      payload,
    );
    return data;
  },

  async inativar(id: string): Promise<RegraContabilizacao> {
    const { data } = await api.patch<RegraContabilizacao>(
      `/regras-contabilizacao/${id}/inativar`,
    );
    return data;
  },

  async reativar(id: string): Promise<RegraContabilizacao> {
    const { data } = await api.patch<RegraContabilizacao>(
      `/regras-contabilizacao/${id}/reativar`,
    );
    return data;
  },

  async excluir(id: string): Promise<{ deleted: boolean }> {
    const { data } = await api.delete<{ deleted: boolean }>(
      `/regras-contabilizacao/${id}`,
    );
    return data;
  },

  async simular(empresaId: string, xml: string): Promise<SimulacaoResultado> {
    const { data } = await api.post<SimulacaoResultado>(
      '/regras-contabilizacao/simular',
      { empresaId, xml },
    );
    return data;
  },
};
