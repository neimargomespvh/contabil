import { api } from '@/lib/axios';
import type { ContaArvore, PlanoContas } from '@/types';

export interface CreateContaPayload {
  codigo: string;
  nome: string;
  natureza: 'ATIVO' | 'PASSIVO' | 'PATRIMONIO_LIQUIDO' | 'RECEITA' | 'DESPESA' | 'CUSTO';
  tipo: 'SINTETICA' | 'ANALITICA';
  contaPaiId?: string | null;
  dreLinha?: string | null;
}

export interface UpdateContaPayload extends Partial<CreateContaPayload> {}

export const planoContasService = {
  async listarPlanos(empresaId: string): Promise<PlanoContas[]> {
    const { data } = await api.get<PlanoContas[]>(
      `/empresas/${empresaId}/plano-contas`,
    );
    return data;
  },

  async buscarPlano(id: string): Promise<PlanoContas> {
    const { data } = await api.get<PlanoContas>(`/planos/${id}`);
    return data;
  },

  async listarContas(planoId: string): Promise<ContaArvore[]> {
    const { data } = await api.get<ContaArvore[]>(`/planos/${planoId}/contas`);
    return data;
  },

  async criarPlanoPadrao(empresaId: string, nome?: string): Promise<PlanoContas> {
    const { data } = await api.post<PlanoContas>(
      `/empresas/${empresaId}/plano-contas/padrao`,
      {},
      { params: nome ? { nome } : {} },
    );
    return data;
  },

  async criarConta(planoId: string, payload: CreateContaPayload): Promise<ContaArvore> {
    const { data } = await api.post<ContaArvore>(
      `/planos/${planoId}/contas`,
      payload,
    );
    return data;
  },

  async atualizarConta(id: string, payload: UpdateContaPayload): Promise<ContaArvore> {
    const { data } = await api.patch<ContaArvore>(`/planos/contas/${id}`, payload);
    return data;
  },

  async excluirConta(id: string): Promise<{ deleted: boolean }> {
    const { data } = await api.delete<{ deleted: boolean }>(`/planos/contas/${id}`);
    return data;
  },
};
