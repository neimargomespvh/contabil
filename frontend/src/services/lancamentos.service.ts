import { api } from '@/lib/axios';
import type {
  Lancamento,
  CreateLancamentoPayload,
  FilterLancamentos,
} from '@/types';

interface LancamentosResponse {
  data: Lancamento[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export const lancamentosService = {
  async listar(filtros: FilterLancamentos): Promise<LancamentosResponse> {
    const { data } = await api.get<LancamentosResponse>('/lancamentos', {
      params: {
        empresaId: filtros.empresaId,
        competencia: filtros.competencia,
        page: filtros.page ?? 1,
        limit: filtros.limit ?? 30,
      },
    });
    return data;
  },

  async buscarPorId(id: string): Promise<Lancamento> {
    const { data } = await api.get<Lancamento>(`/lancamentos/${id}`);
    return data;
  },

  async criar(payload: CreateLancamentoPayload): Promise<Lancamento> {
    const { data } = await api.post<Lancamento>('/lancamentos', payload);
    return data;
  },

  async estornar(id: string, motivo: string): Promise<Lancamento> {
    const { data } = await api.post<Lancamento>(`/lancamentos/${id}/estornar`, { motivo });
    return data;
  },
};
