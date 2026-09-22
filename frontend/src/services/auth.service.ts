import { api } from '@/lib/axios';
import type { LoginResponse } from '@/types';

export const authService = {
  async login(email: string, senha: string): Promise<LoginResponse> {
    const { data } = await api.post<LoginResponse>('/auth/login', { email, senha });
    return data;
  },

  async register(payload: {
    nome: string;
    email: string;
    senha: string;
    nomeTenant: string;
    cnpjTenant: string;
  }) {
    const { data } = await api.post('/auth/register', payload);
    return data;
  },

  async refresh(refreshToken: string) {
    const { data } = await api.post('/auth/refresh', { refreshToken });
    return data;
  },
};
