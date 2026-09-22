import { api } from '@/lib/axios';
import type { ContaArvore, PlanoContas } from '@/types';

export const planoContasService = {
  async listarPlanos(empresaId: string): Promise<PlanoContas[]> {
    const { data } = await api.get<PlanoContas[]>(`/empresas/${empresaId}/plano-contas`);
    return data;
  },

  async listarContas(planoId: string): Promise<ContaArvore[]> {
    const { data } = await api.get<ContaArvore[]>(`/planos/${planoId}/contas`);
    return data;
  },

  async criarPlanoPadrao(empresaId: string, nome?: string): Promise<PlanoContas> {
    const { data } = await api.post<PlanoContas>(
      `/empresas/${empresaId}/plano-contas/padrao`,
      null,
      { params: nome ? { nome } : {} },
    );
    return data;
  },
};
