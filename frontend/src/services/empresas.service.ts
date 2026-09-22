import { api } from '@/lib/axios';
import type {
  Empresa,
  CreateEmpresaPayload,
  FilterEmpresas,
  PaginatedResponse,
} from '@/types';

export const empresasService = {
  async listar(filtros: FilterEmpresas = {}): Promise<PaginatedResponse<Empresa>> {
    const { data } = await api.get<PaginatedResponse<Empresa>>('/empresas', {
      params: {
        page: filtros.page ?? 1,
        limit: filtros.limit ?? 20,
        busca: filtros.busca || undefined,
        regimeTributario: filtros.regimeTributario || undefined,
        status: filtros.status || undefined,
      },
    });
    return data;
  },

  async buscarPorId(id: string): Promise<Empresa> {
    const { data } = await api.get<Empresa>(`/empresas/${id}`);
    return data;
  },

  async criar(payload: CreateEmpresaPayload): Promise<Empresa> {
    const { data } = await api.post<Empresa>('/empresas', payload);
    return data;
  },

  async atualizar(id: string, payload: Partial<CreateEmpresaPayload>): Promise<Empresa> {
    const { data } = await api.patch<Empresa>(`/empresas/${id}`, payload);
    return data;
  },

  async remover(id: string): Promise<{ message: string }> {
    const { data } = await api.delete<{ message: string }>(`/empresas/${id}`);
    return data;
  },
};
