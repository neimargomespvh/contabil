import { api } from '@/lib/axios';

interface Fechamento {
  id: string;
  empresaId: string;
  competencia: string;
  status: 'ABERTO' | 'FECHADO';
  fechadoEm?: string;
}

export const fechamentoService = {
  async buscar(empresaId: string, competencia: string): Promise<Fechamento | null> {
    try {
      const { data } = await api.get(`/fechamento`, {
        params: { empresaId, competencia },
      });
      return data;
    } catch {
      return null;
    }
  },

  async fechar(empresaId: string, competencia: string): Promise<Fechamento> {
    const { data } = await api.post('/fechamento/fechar', { empresaId, competencia });
    return data;
  },

  async reabrir(empresaId: string, competencia: string, motivo: string): Promise<Fechamento> {
    const { data } = await api.post('/fechamento/reabrir', {
      empresaId,
      competencia,
      motivo,
    });
    return data;
  },
};
