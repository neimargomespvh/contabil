import { api } from '@/lib/axios';
import type { CentroCusto } from '@/types';

export const centrosCustoService = {
  async listarPorEmpresa(empresaId: string): Promise<CentroCusto[]> {
    const { data } = await api.get<CentroCusto[]>(`/centros-custo/empresa/${empresaId}`);
    return data;
  },
};
