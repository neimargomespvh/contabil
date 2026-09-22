import { create } from 'zustand';
import type { User } from '@/types';

interface AuthState {
  user: User | null;
  token: string | null;
  isAuthenticated: boolean;
  setAuth: (user: User, token: string, refreshToken: string) => void;
  clearAuth: () => void;
  hasPermission: (permission: string) => boolean;
}

export const useAuthStore = create<AuthState>((set, get) => {
  // Carregar do localStorage ao iniciar
  const storedUser = localStorage.getItem('@contabil:user');
  const storedToken = localStorage.getItem('@contabil:token');

  return {
    user: storedUser ? JSON.parse(storedUser) : null,
    token: storedToken,
    isAuthenticated: Boolean(storedToken),

    setAuth: (user, token, refreshToken) => {
      localStorage.setItem('@contabil:user', JSON.stringify(user));
      localStorage.setItem('@contabil:token', token);
      localStorage.setItem('@contabil:refreshToken', refreshToken);
      set({ user, token, isAuthenticated: true });
    },

    clearAuth: () => {
      localStorage.removeItem('@contabil:user');
      localStorage.removeItem('@contabil:token');
      localStorage.removeItem('@contabil:refreshToken');
      set({ user: null, token: null, isAuthenticated: false });
    },

    hasPermission: (permission: string) => {
      const { user } = get();
      if (!user) return false;
      if (user.permissions.includes('*')) return true;
      return user.permissions.some((p) => {
        if (p === permission) return true;
        if (p.endsWith('.*')) return permission.startsWith(p.slice(0, -1));
        return false;
      });
    },
  };
});
