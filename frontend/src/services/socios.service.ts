import { api } from '@/lib/axios';
import type {
  Socio,
  CreateSocioPayload,
  UpdateSocioPayload,
  SociosResponse,
} from '@/types';

export const sociosService = {
  async listarPorEmpresa(empresaId: string): Promise<SociosResponse> {
    const { data } = await api.get<SociosResponse>(`/socios/empresa/${empresaId}`);
    return data;
  },

  async criar(payload: CreateSocioPayload): Promise<Socio> {
    const { data } = await api.post<Socio>('/socios', payload);
    return data;
  },

  async atualizar(id: string, payload: UpdateSocioPayload): Promise<Socio> {
    const { data } = await api.patch<Socio>(`/socios/${id}`, payload);
    return data;
  },

  async remover(id: string): Promise<{ message: string }> {
    const { data } = await api.delete<{ message: string }>(`/socios/${id}`);
    return data;
  },
};
