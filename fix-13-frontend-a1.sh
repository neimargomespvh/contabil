#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

FRONTEND_DIR="frontend"

echo "🎨 Criando frontend em ./$FRONTEND_DIR..."
mkdir -p "$FRONTEND_DIR"
cd "$FRONTEND_DIR"

# ============================================================
# 1. PACKAGE.JSON
# ============================================================
cat > package.json <<'PKG_EOF'
{
  "name": "contabil-frontend",
  "private": true,
  "version": "0.1.0",
  "type": "module",
  "scripts": {
    "dev": "vite",
    "build": "tsc -b && vite build",
    "preview": "vite preview",
    "lint": "eslint . --ext ts,tsx"
  },
  "dependencies": {
    "@hookform/resolvers": "^3.9.0",
    "@tanstack/react-query": "^5.59.0",
    "axios": "^1.7.7",
    "clsx": "^2.1.1",
    "lucide-react": "^0.451.0",
    "react": "^18.3.1",
    "react-dom": "^18.3.1",
    "react-hook-form": "^7.53.0",
    "react-router-dom": "^6.27.0",
    "tailwind-merge": "^2.5.4",
    "zod": "^3.23.8",
    "zustand": "^5.0.0"
  },
  "devDependencies": {
    "@types/node": "^22.7.4",
    "@types/react": "^18.3.11",
    "@types/react-dom": "^18.3.1",
    "@vitejs/plugin-react": "^4.3.2",
    "autoprefixer": "^10.4.20",
    "postcss": "^8.4.47",
    "tailwindcss": "^3.4.13",
    "typescript": "^5.6.3",
    "vite": "^5.4.8"
  }
}
PKG_EOF

# ============================================================
# 2. VITE + TSCONFIG + TAILWIND
# ============================================================
cat > vite.config.ts <<'VITE_EOF'
import { defineConfig } from 'vite';
import react from '@vitejs/plugin-react';
import path from 'path';

export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      '@': path.resolve(__dirname, './src'),
    },
  },
  server: {
    port: 5173,
    host: '0.0.0.0',
  },
});
VITE_EOF

cat > tsconfig.json <<'TSCONF_EOF'
{
  "files": [],
  "references": [
    { "path": "./tsconfig.app.json" },
    { "path": "./tsconfig.node.json" }
  ]
}
TSCONF_EOF

cat > tsconfig.app.json <<'TSCONF_EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "useDefineForClassFields": true,
    "lib": ["ES2022", "DOM", "DOM.Iterable"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowImportingTsExtensions": true,
    "resolveJsonModule": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "jsx": "react-jsx",
    "strict": true,
    "noUnusedLocals": false,
    "noUnusedParameters": false,
    "noFallthroughCasesInSwitch": true,
    "baseUrl": ".",
    "paths": {
      "@/*": ["./src/*"]
    }
  },
  "include": ["src"]
}
TSCONF_EOF

cat > tsconfig.node.json <<'TSCONF_EOF'
{
  "compilerOptions": {
    "target": "ES2022",
    "lib": ["ES2023"],
    "module": "ESNext",
    "skipLibCheck": true,
    "moduleResolution": "bundler",
    "allowSyntheticDefaultImports": true,
    "isolatedModules": true,
    "moduleDetection": "force",
    "noEmit": true,
    "strict": true
  },
  "include": ["vite.config.ts"]
}
TSCONF_EOF

cat > tailwind.config.js <<'TW_EOF'
/** @type {import('tailwindcss').Config} */
export default {
  content: ['./index.html', './src/**/*.{js,ts,jsx,tsx}'],
  theme: {
    extend: {
      colors: {
        brand: {
          50: '#eff6ff',
          100: '#dbeafe',
          500: '#3b82f6',
          600: '#2563eb',
          700: '#1d4ed8',
          800: '#1e40af',
          900: '#1e3a8a',
        },
      },
    },
  },
  plugins: [],
};
TW_EOF

cat > postcss.config.js <<'POSTCSS_EOF'
export default {
  plugins: {
    tailwindcss: {},
    autoprefixer: {},
  },
};
POSTCSS_EOF

# ============================================================
# 3. HTML BASE
# ============================================================
cat > index.html <<'HTML_EOF'
<!doctype html>
<html lang="pt-BR">
  <head>
    <meta charset="UTF-8" />
    <link rel="icon" type="image/svg+xml" href="/favicon.svg" />
    <meta name="viewport" content="width=device-width, initial-scale=1.0" />
    <title>Sistema Contábil</title>
  </head>
  <body>
    <div id="root"></div>
    <script type="module" src="/src/main.tsx"></script>
  </body>
</html>
HTML_EOF

cat > .env <<'ENV_EOF'
VITE_API_URL=http://localhost:3000/api/v1
ENV_EOF

cat > .env.example <<'ENV_EOF'
VITE_API_URL=http://localhost:3000/api/v1
ENV_EOF

# ============================================================
# 4. ESTRUTURA DE PASTAS
# ============================================================
mkdir -p src/{lib,stores,hooks,components/ui,pages,services,types}

# ============================================================
# 5. CSS GLOBAL
# ============================================================
cat > src/index.css <<'CSS_EOF'
@tailwind base;
@tailwind components;
@tailwind utilities;

@layer base {
  * { @apply border-gray-200; }
  body {
    @apply bg-gray-50 text-gray-900 antialiased;
    font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
  }
}

@layer components {
  .btn-base {
    @apply inline-flex items-center justify-center gap-2 rounded-md px-4 py-2 text-sm font-medium transition-colors focus:outline-none focus:ring-2 focus:ring-offset-2 disabled:pointer-events-none disabled:opacity-50;
  }
  .input-base {
    @apply flex h-10 w-full rounded-md border border-gray-300 bg-white px-3 py-2 text-sm placeholder:text-gray-400 focus:outline-none focus:ring-2 focus:ring-brand-500 focus:border-transparent disabled:cursor-not-allowed disabled:opacity-50;
  }
  .card-base {
    @apply rounded-lg border border-gray-200 bg-white shadow-sm;
  }
}
CSS_EOF

# ============================================================
# 6. UTILITÁRIOS
# ============================================================
cat > src/lib/utils.ts <<'UTILS_EOF'
import { clsx, type ClassValue } from 'clsx';
import { twMerge } from 'tailwind-merge';

export function cn(...inputs: ClassValue[]) {
  return twMerge(clsx(inputs));
}
UTILS_EOF

cat > src/lib/format.ts <<'FORMAT_EOF'
export function formatCurrency(value: number | string): string {
  const n = typeof value === 'string' ? parseFloat(value) : value;
  if (isNaN(n)) return 'R$ 0,00';
  return n.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
}

export function formatDate(date: string | Date): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('pt-BR');
}

export function formatCnpj(cnpj: string): string {
  const limpo = cnpj.replace(/\D/g, '');
  return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
}

export function formatCpf(cpf: string): string {
  const limpo = cpf.replace(/\D/g, '');
  return limpo.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, '$1.$2.$3-$4');
}
FORMAT_EOF

# ============================================================
# 7. AXIOS CLIENT
# ============================================================
cat > src/lib/axios.ts <<'AXIOS_EOF'
import axios from 'axios';

const API_URL = import.meta.env.VITE_API_URL || 'http://localhost:3000/api/v1';

export const api = axios.create({
  baseURL: API_URL,
  headers: { 'Content-Type': 'application/json' },
});

// Interceptor de request — adiciona o token
api.interceptors.request.use((config) => {
  const token = localStorage.getItem('@contabil:token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

// Interceptor de response — trata 401 e refresh automático
let isRefreshing = false;
let failedQueue: Array<{ resolve: (v: any) => void; reject: (e: any) => void }> = [];

const processQueue = (error: any, token: string | null = null) => {
  failedQueue.forEach((p) => (error ? p.reject(error) : p.resolve(token)));
  failedQueue = [];
};

api.interceptors.response.use(
  (response) => response,
  async (error) => {
    const original = error.config;

    if (error.response?.status === 401 && !original._retry && !original.url?.includes('/auth/')) {
      if (isRefreshing) {
        return new Promise((resolve, reject) => {
          failedQueue.push({ resolve, reject });
        }).then((token) => {
          original.headers.Authorization = `Bearer ${token}`;
          return api(original);
        });
      }

      original._retry = true;
      isRefreshing = true;

      const refreshToken = localStorage.getItem('@contabil:refreshToken');
      if (!refreshToken) {
        localStorage.clear();
        window.location.href = '/login';
        return Promise.reject(error);
      }

      try {
        const { data } = await axios.post(`${API_URL}/auth/refresh`, { refreshToken });
        const newToken = data.accessToken;
        localStorage.setItem('@contabil:token', newToken);
        api.defaults.headers.Authorization = `Bearer ${newToken}`;
        processQueue(null, newToken);
        original.headers.Authorization = `Bearer ${newToken}`;
        return api(original);
      } catch (refreshError) {
        processQueue(refreshError, null);
        localStorage.clear();
        window.location.href = '/login';
        return Promise.reject(refreshError);
      } finally {
        isRefreshing = false;
      }
    }

    return Promise.reject(error);
  },
);

export function getApiError(error: any): string {
  if (error?.response?.data?.message) {
    const msg = error.response.data.message;
    return Array.isArray(msg) ? msg.join(', ') : msg;
  }
  if (error?.message) return error.message;
  return 'Erro inesperado';
}
AXIOS_EOF

# ============================================================
# 8. TIPOS
# ============================================================
cat > src/types/index.ts <<'TYPES_EOF'
export interface User {
  id: string;
  nome: string;
  email: string;
  tenantId: string;
  tenantNome: string;
  permissions: string[];
}

export interface LoginResponse {
  accessToken: string;
  refreshToken: string;
  user: User;
}
TYPES_EOF

# ============================================================
# 9. AUTH STORE (Zustand)
# ============================================================
cat > src/stores/auth.store.ts <<'STORE_EOF'
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
STORE_EOF

# ============================================================
# 10. AUTH SERVICE
# ============================================================
cat > src/services/auth.service.ts <<'SVC_EOF'
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
SVC_EOF

# ============================================================
# 11. COMPONENTES UI
# ============================================================
cat > src/components/ui/Button.tsx <<'BTN_EOF'
import { forwardRef, type ButtonHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface ButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  variant?: 'primary' | 'secondary' | 'outline' | 'ghost' | 'danger';
  size?: 'sm' | 'md' | 'lg';
  loading?: boolean;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(
  ({ className, variant = 'primary', size = 'md', loading, children, disabled, ...props }, ref) => {
    const variants = {
      primary: 'bg-brand-600 text-white hover:bg-brand-700 focus:ring-brand-500',
      secondary: 'bg-gray-100 text-gray-900 hover:bg-gray-200 focus:ring-gray-400',
      outline: 'border border-gray-300 bg-white text-gray-700 hover:bg-gray-50 focus:ring-brand-500',
      ghost: 'text-gray-700 hover:bg-gray-100 focus:ring-gray-400',
      danger: 'bg-red-600 text-white hover:bg-red-700 focus:ring-red-500',
    };

    const sizes = {
      sm: 'h-8 px-3 text-xs',
      md: 'h-10 px-4 text-sm',
      lg: 'h-12 px-6 text-base',
    };

    return (
      <button
        ref={ref}
        className={cn('btn-base', variants[variant], sizes[size], className)}
        disabled={disabled || loading}
        {...props}
      >
        {loading && (
          <svg className="h-4 w-4 animate-spin" viewBox="0 0 24 24" fill="none">
            <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" className="opacity-25" />
            <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" className="opacity-75" />
          </svg>
        )}
        {children}
      </button>
    );
  },
);

Button.displayName = 'Button';
BTN_EOF

cat > src/components/ui/Input.tsx <<'INPUT_EOF'
import { forwardRef, type InputHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

interface InputProps extends InputHTMLAttributes<HTMLInputElement> {
  error?: string;
}

export const Input = forwardRef<HTMLInputElement, InputProps>(
  ({ className, error, ...props }, ref) => {
    return (
      <div className="w-full">
        <input
          ref={ref}
          className={cn('input-base', error && 'border-red-500 focus:ring-red-500', className)}
          {...props}
        />
        {error && <p className="mt-1 text-xs text-red-600">{error}</p>}
      </div>
    );
  },
);

Input.displayName = 'Input';
INPUT_EOF

cat > src/components/ui/Label.tsx <<'LBL_EOF'
import type { LabelHTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

export function Label({ className, children, ...props }: LabelHTMLAttributes<HTMLLabelElement>) {
  return (
    <label className={cn('mb-1 block text-sm font-medium text-gray-700', className)} {...props}>
      {children}
    </label>
  );
}
LBL_EOF

cat > src/components/ui/Card.tsx <<'CARD_EOF'
import type { HTMLAttributes } from 'react';
import { cn } from '@/lib/utils';

export function Card({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('card-base', className)} {...props} />;
}

export function CardHeader({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('border-b border-gray-200 px-6 py-4', className)} {...props} />;
}

export function CardTitle({ className, ...props }: HTMLAttributes<HTMLHeadingElement>) {
  return <h3 className={cn('text-lg font-semibold text-gray-900', className)} {...props} />;
}

export function CardContent({ className, ...props }: HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('p-6', className)} {...props} />;
}
CARD_EOF

cat > src/components/ui/Spinner.tsx <<'SPIN_EOF'
export function Spinner({ size = 'md' }: { size?: 'sm' | 'md' | 'lg' }) {
  const sizes = { sm: 'h-4 w-4', md: 'h-8 w-8', lg: 'h-12 w-12' };
  return (
    <svg className={`${sizes[size]} animate-spin text-brand-600`} viewBox="0 0 24 24" fill="none">
      <circle cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" className="opacity-25" />
      <path fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" className="opacity-75" />
    </svg>
  );
}
SPIN_EOF

cat > src/components/ui/Toast.tsx <<'TOAST_EOF'
import { create } from 'zustand';
import { useEffect } from 'react';
import { CheckCircle, XCircle, Info, X } from 'lucide-react';
import { cn } from '@/lib/utils';

type ToastType = 'success' | 'error' | 'info';

interface ToastItem {
  id: string;
  type: ToastType;
  message: string;
}

interface ToastStore {
  toasts: ToastItem[];
  add: (type: ToastType, message: string) => void;
  remove: (id: string) => void;
}

const useToastStore = create<ToastStore>((set) => ({
  toasts: [],
  add: (type, message) => {
    const id = Math.random().toString(36).slice(2);
    set((s) => ({ toasts: [...s.toasts, { id, type, message }] }));
    setTimeout(() => {
      set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) }));
    }, 5000);
  },
  remove: (id) => set((s) => ({ toasts: s.toasts.filter((t) => t.id !== id) })),
}));

export const toast = {
  success: (msg: string) => useToastStore.getState().add('success', msg),
  error: (msg: string) => useToastStore.getState().add('error', msg),
  info: (msg: string) => useToastStore.getState().add('info', msg),
};

export function ToastContainer() {
  const { toasts, remove } = useToastStore();

  useEffect(() => {}, [toasts]);

  if (toasts.length === 0) return null;

  const icons = {
    success: <CheckCircle className="h-5 w-5 text-green-600" />,
    error: <XCircle className="h-5 w-5 text-red-600" />,
    info: <Info className="h-5 w-5 text-blue-600" />,
  };

  return (
    <div className="fixed top-4 right-4 z-50 flex flex-col gap-2">
      {toasts.map((t) => (
        <div
          key={t.id}
          className={cn(
            'flex items-start gap-3 rounded-lg border bg-white p-4 shadow-lg',
            'animate-in slide-in-from-top-2 duration-200',
            t.type === 'success' && 'border-green-200',
            t.type === 'error' && 'border-red-200',
            t.type === 'info' && 'border-blue-200',
          )}
          style={{ minWidth: '320px', maxWidth: '480px' }}
        >
          {icons[t.type]}
          <p className="flex-1 text-sm text-gray-800">{t.message}</p>
          <button onClick={() => remove(t.id)} className="text-gray-400 hover:text-gray-600">
            <X className="h-4 w-4" />
          </button>
        </div>
      ))}
    </div>
  );
}
TOAST_EOF

# ============================================================
# 12. COMPONENTES DE LAYOUT
# ============================================================
cat > src/components/ProtectedRoute.tsx <<'PROT_EOF'
import { Navigate, Outlet, useLocation } from 'react-router-dom';
import { useAuthStore } from '@/stores/auth.store';

export function ProtectedRoute() {
  const isAuthenticated = useAuthStore((s) => s.isAuthenticated);
  const location = useLocation();

  if (!isAuthenticated) {
    return <Navigate to="/login" state={{ from: location }} replace />;
  }

  return <Outlet />;
}
PROT_EOF

cat > src/components/Sidebar.tsx <<'SIDE_EOF'
import { NavLink } from 'react-router-dom';
import {
  LayoutDashboard, Building2, BookOpen, FileText, Receipt,
  Landmark, Calculator, BarChart3, Users, Shield, Settings, X,
} from 'lucide-react';
import { cn } from '@/lib/utils';
import { useAuthStore } from '@/stores/auth.store';

interface SidebarProps {
  isOpen: boolean;
  onClose: () => void;
}

const NAV_ITEMS = [
  { to: '/', label: 'Dashboard', icon: LayoutDashboard, permission: null },
  { to: '/empresas', label: 'Empresas', icon: Building2, permission: 'empresa.ver' },
  { to: '/plano-contas', label: 'Plano de Contas', icon: BookOpen, permission: 'plano.ver' },
  { to: '/lancamentos', label: 'Lançamentos', icon: FileText, permission: 'lancamento.ver' },
  { to: '/documentos-fiscais', label: 'Documentos Fiscais', icon: Receipt, permission: 'documento.ver' },
  { to: '/conciliacao', label: 'Conciliação', icon: Landmark, permission: 'conciliacao.ver' },
  { to: '/apuracoes', label: 'Apurações', icon: Calculator, permission: 'apuracao.ver' },
  { to: '/relatorios', label: 'Relatórios', icon: BarChart3, permission: 'relatorio.ver' },
];

const ADMIN_ITEMS = [
  { to: '/usuarios', label: 'Usuários', icon: Users, permission: 'usuario.ver' },
  { to: '/perfis', label: 'Perfis', icon: Shield, permission: 'role.ver' },
];

export function Sidebar({ isOpen, onClose }: SidebarProps) {
  const hasPermission = useAuthStore((s) => s.hasPermission);

  const renderItems = (items: typeof NAV_ITEMS) =>
    items
      .filter((item) => !item.permission || hasPermission(item.permission))
      .map((item) => {
        const Icon = item.icon;
        return (
          <NavLink
            key={item.to}
            to={item.to}
            end={item.to === '/'}
            onClick={onClose}
            className={({ isActive }) =>
              cn(
                'flex items-center gap-3 rounded-md px-3 py-2 text-sm font-medium transition-colors',
                isActive
                  ? 'bg-brand-600 text-white'
                  : 'text-gray-700 hover:bg-gray-100',
              )
            }
          >
            <Icon className="h-4 w-4" />
            {item.label}
          </NavLink>
        );
      });

  return (
    <>
      {isOpen && (
        <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={onClose} />
      )}
      <aside
        className={cn(
          'fixed inset-y-0 left-0 z-50 w-64 transform border-r border-gray-200 bg-white transition-transform lg:static lg:translate-x-0',
          isOpen ? 'translate-x-0' : '-translate-x-full',
        )}
      >
        <div className="flex h-16 items-center justify-between border-b border-gray-200 px-4">
          <div className="flex items-center gap-2">
            <div className="flex h-8 w-8 items-center justify-center rounded-md bg-brand-600 text-sm font-bold text-white">
              SC
            </div>
            <span className="font-semibold text-gray-900">Contábil</span>
          </div>
          <button onClick={onClose} className="text-gray-400 hover:text-gray-600 lg:hidden">
            <X className="h-5 w-5" />
          </button>
        </div>

        <nav className="flex flex-col gap-1 p-4">
          {renderItems(NAV_ITEMS)}

          <div className="mt-4 border-t border-gray-200 pt-4">
            <p className="mb-2 px-3 text-xs font-semibold uppercase tracking-wider text-gray-500">
              Administração
            </p>
            {renderItems(ADMIN_ITEMS)}
          </div>
        </nav>
      </aside>
    </>
  );
}
SIDE_EOF

cat > src/components/Header.tsx <<'HEADER_EOF'
import { useState } from 'react';
import { Menu, LogOut, ChevronDown, User as UserIcon } from 'lucide-react';
import { useNavigate } from 'react-router-dom';
import { useAuthStore } from '@/stores/auth.store';
import { Button } from './ui/Button';

interface HeaderProps {
  onMenuClick: () => void;
}

export function Header({ onMenuClick }: HeaderProps) {
  const { user, clearAuth } = useAuthStore();
  const navigate = useNavigate();
  const [menuOpen, setMenuOpen] = useState(false);

  const handleLogout = () => {
    clearAuth();
    navigate('/login', { replace: true });
  };

  return (
    <header className="flex h-16 items-center justify-between border-b border-gray-200 bg-white px-4 lg:px-6">
      <button
        onClick={onMenuClick}
        className="rounded-md p-2 text-gray-600 hover:bg-gray-100 lg:hidden"
      >
        <Menu className="h-5 w-5" />
      </button>

      <div className="flex-1" />

      <div className="relative">
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="flex items-center gap-2 rounded-md px-3 py-2 text-sm hover:bg-gray-100"
        >
          <div className="flex h-8 w-8 items-center justify-center rounded-full bg-brand-100 text-sm font-semibold text-brand-700">
            {user?.nome?.charAt(0).toUpperCase() ?? '?'}
          </div>
          <div className="hidden text-left sm:block">
            <p className="text-sm font-medium text-gray-900">{user?.nome}</p>
            <p className="text-xs text-gray-500">{user?.tenantNome}</p>
          </div>
          <ChevronDown className="h-4 w-4 text-gray-500" />
        </button>

        {menuOpen && (
          <>
            <div className="fixed inset-0 z-10" onClick={() => setMenuOpen(false)} />
            <div className="absolute right-0 z-20 mt-2 w-56 rounded-md border border-gray-200 bg-white shadow-lg">
              <div className="border-b border-gray-100 px-4 py-3">
                <p className="text-sm font-medium text-gray-900">{user?.nome}</p>
                <p className="text-xs text-gray-500">{user?.email}</p>
              </div>
              <div className="p-1">
                <button
                  onClick={() => { setMenuOpen(false); navigate('/perfil'); }}
                  className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
                >
                  <UserIcon className="h-4 w-4" />
                  Meu perfil
                </button>
                <button
                  onClick={handleLogout}
                  className="flex w-full items-center gap-2 rounded-md px-3 py-2 text-sm text-red-600 hover:bg-red-50"
                >
                  <LogOut className="h-4 w-4" />
                  Sair
                </button>
              </div>
            </div>
          </>
        )}
      </div>
    </header>
  );
}
HEADER_EOF

cat > src/components/Layout.tsx <<'LAYOUT_EOF'
import { useState } from 'react';
import { Outlet } from 'react-router-dom';
import { Sidebar } from './Sidebar';
import { Header } from './Header';

export function Layout() {
  const [sidebarOpen, setSidebarOpen] = useState(false);

  return (
    <div className="flex h-screen overflow-hidden bg-gray-50">
      <Sidebar isOpen={sidebarOpen} onClose={() => setSidebarOpen(false)} />
      <div className="flex flex-1 flex-col overflow-hidden">
        <Header onMenuClick={() => setSidebarOpen(true)} />
        <main className="flex-1 overflow-y-auto p-4 lg:p-6">
          <Outlet />
        </main>
      </div>
    </div>
  );
}
LAYOUT_EOF

# ============================================================
# 13. PÁGINAS
# ============================================================
cat > src/pages/Login.tsx <<'LOGIN_EOF'
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Building2 } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { toast } from '@/components/ui/Toast';
import { authService } from '@/services/auth.service';
import { useAuthStore } from '@/stores/auth.store';
import { getApiError } from '@/lib/axios';

const schema = z.object({
  email: z.string().email('Email inválido'),
  senha: z.string().min(6, 'Senha deve ter pelo menos 6 caracteres'),
});

type FormData = z.infer<typeof schema>;

export function LoginPage() {
  const navigate = useNavigate();
  const setAuth = useAuthStore((s) => s.setAuth);

  const {
    register,
    handleSubmit,
    formState: { errors, isSubmitting },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
  });

  const onSubmit = async (data: FormData) => {
    try {
      const response = await authService.login(data.email, data.senha);
      setAuth(response.user, response.accessToken, response.refreshToken);
      toast.success(`Bem-vindo, ${response.user.nome}!`);
      navigate('/', { replace: true });
    } catch (error) {
      toast.error(getApiError(error));
    }
  };

  return (
    <div className="flex min-h-screen items-center justify-center bg-gradient-to-br from-brand-50 to-gray-100 p-4">
      <div className="w-full max-w-md">
        <div className="mb-8 flex flex-col items-center">
          <div className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-brand-600 text-white shadow-lg">
            <Building2 className="h-8 w-8" />
          </div>
          <h1 className="text-2xl font-bold text-gray-900">Sistema Contábil</h1>
          <p className="mt-1 text-sm text-gray-500">Entre com suas credenciais</p>
        </div>

        <div className="rounded-lg border border-gray-200 bg-white p-6 shadow-sm">
          <form onSubmit={handleSubmit(onSubmit)} className="space-y-4">
            <div>
              <Label htmlFor="email">Email</Label>
              <Input
                id="email"
                type="email"
                placeholder="seu@email.com"
                autoComplete="email"
                {...register('email')}
                error={errors.email?.message}
              />
            </div>

            <div>
              <Label htmlFor="senha">Senha</Label>
              <Input
                id="senha"
                type="password"
                placeholder="••••••••"
                autoComplete="current-password"
                {...register('senha')}
                error={errors.senha?.message}
              />
            </div>

            <Button type="submit" className="w-full" loading={isSubmitting} size="lg">
              Entrar
            </Button>
          </form>
        </div>

        <p className="mt-6 text-center text-xs text-gray-500">
          © {new Date().getFullYear()} Sistema Contábil — Todos os direitos reservados
        </p>
      </div>
    </div>
  );
}
LOGIN_EOF

cat > src/pages/Dashboard.tsx <<'DASH_EOF'
import { Building2, FileText, Receipt, Calculator, TrendingUp, AlertCircle } from 'lucide-react';
import { Card, CardContent } from '@/components/ui/Card';
import { useAuthStore } from '@/stores/auth.store';

interface StatCardProps {
  title: string;
  value: string;
  icon: React.ElementType;
  color: string;
  hint?: string;
}

function StatCard({ title, value, icon: Icon, color, hint }: StatCardProps) {
  return (
    <Card>
      <CardContent className="flex items-center justify-between">
        <div>
          <p className="text-sm font-medium text-gray-500">{title}</p>
          <p className="mt-1 text-2xl font-bold text-gray-900">{value}</p>
          {hint && <p className="mt-1 text-xs text-gray-400">{hint}</p>}
        </div>
        <div className={`flex h-12 w-12 items-center justify-center rounded-lg ${color}`}>
          <Icon className="h-6 w-6 text-white" />
        </div>
      </CardContent>
    </Card>
  );
}

export function DashboardPage() {
  const user = useAuthStore((s) => s.user);

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Dashboard</h1>
        <p className="mt-1 text-sm text-gray-500">
          Bem-vindo de volta, {user?.nome}!
        </p>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
        <StatCard
          title="Empresas"
          value="—"
          icon={Building2}
          color="bg-brand-600"
          hint="Clientes do escritório"
        />
        <StatCard
          title="Lançamentos"
          value="—"
          icon={FileText}
          color="bg-emerald-600"
          hint="Mês atual"
        />
        <StatCard
          title="Documentos"
          value="—"
          icon={Receipt}
          color="bg-amber-600"
          hint="Pendentes de contabilização"
        />
        <StatCard
          title="Apurações"
          value="—"
          icon={Calculator}
          color="bg-purple-600"
          hint="A vencer este mês"
        />
      </div>

      <div className="grid grid-cols-1 gap-4 lg:grid-cols-2">
        <Card>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-emerald-100">
                <TrendingUp className="h-5 w-5 text-emerald-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Começando agora</h3>
                <p className="text-sm text-gray-500">
                  Cadastre sua primeira empresa para começar
                </p>
              </div>
            </div>
            <div className="mt-4 space-y-2 text-sm text-gray-600">
              <p>✓ API rodando em <code className="rounded bg-gray-100 px-1">localhost:3000</code></p>
              <p>✓ Frontend em <code className="rounded bg-gray-100 px-1">localhost:5173</code></p>
              <p>✓ Autenticação funcionando</p>
            </div>
          </CardContent>
        </Card>

        <Card>
          <CardContent>
            <div className="flex items-center gap-3">
              <div className="flex h-10 w-10 items-center justify-center rounded-lg bg-amber-100">
                <AlertCircle className="h-5 w-5 text-amber-600" />
              </div>
              <div>
                <h3 className="font-semibold text-gray-900">Próximos passos</h3>
                <p className="text-sm text-gray-500">
                  Módulos que serão ativados nas próximas entregas
                </p>
              </div>
            </div>
            <ul className="mt-4 space-y-2 text-sm text-gray-600">
              <li>• Cadastro de empresas e sócios</li>
              <li>• Plano de contas e lançamentos</li>
              <li>• Importação de XML e conciliação</li>
              <li>• Apurações e relatórios</li>
            </ul>
          </CardContent>
        </Card>
      </div>
    </div>
  );
}
DASH_EOF

cat > src/pages/NotFound.tsx <<'NOTFOUND_EOF'
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/Button';

export function NotFoundPage() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center">
      <p className="text-6xl font-bold text-gray-300">404</p>
      <h1 className="mt-4 text-2xl font-bold text-gray-900">Página não encontrada</h1>
      <p className="mt-2 text-sm text-gray-500">
        A página que você está procurando não existe.
      </p>
      <Link to="/" className="mt-6">
        <Button>Voltar ao início</Button>
      </Link>
    </div>
  );
}
NOTFOUND_EOF

# ============================================================
# 14. APP + MAIN
# ============================================================
cat > src/App.tsx <<'APP_EOF'
import { BrowserRouter, Routes, Route, Navigate } from 'react-router-dom';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { Layout } from '@/components/Layout';
import { ProtectedRoute } from '@/components/ProtectedRoute';
import { ToastContainer } from '@/components/ui/Toast';
import { LoginPage } from '@/pages/Login';
import { DashboardPage } from '@/pages/Dashboard';
import { NotFoundPage } from '@/pages/NotFound';

const queryClient = new QueryClient({
  defaultOptions: {
    queries: {
      retry: 1,
      refetchOnWindowFocus: false,
      staleTime: 1000 * 60 * 5, // 5 min
    },
  },
});

export function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <BrowserRouter>
        <Routes>
          <Route path="/login" element={<LoginPage />} />

          <Route element={<ProtectedRoute />}>
            <Route element={<Layout />}>
              <Route index element={<DashboardPage />} />

              {/* Rotas que virão nos próximos pacotes */}
              <Route path="empresas" element={<EmBreve titulo="Empresas" />} />
              <Route path="plano-contas" element={<EmBreve titulo="Plano de Contas" />} />
              <Route path="lancamentos" element={<EmBreve titulo="Lançamentos" />} />
              <Route path="documentos-fiscais" element={<EmBreve titulo="Documentos Fiscais" />} />
              <Route path="conciliacao" element={<EmBreve titulo="Conciliação" />} />
              <Route path="apuracoes" element={<EmBreve titulo="Apurações" />} />
              <Route path="relatorios" element={<EmBreve titulo="Relatórios" />} />
              <Route path="usuarios" element={<EmBreve titulo="Usuários" />} />
              <Route path="perfis" element={<EmBreve titulo="Perfis" />} />
              <Route path="perfil" element={<EmBreve titulo="Meu Perfil" />} />

              <Route path="*" element={<NotFoundPage />} />
            </Route>
          </Route>

          <Route path="/404" element={<NotFoundPage />} />
          <Route path="*" element={<Navigate to="/404" replace />} />
        </Routes>
      </BrowserRouter>
      <ToastContainer />
    </QueryClientProvider>
  );
}

function EmBreve({ titulo }: { titulo: string }) {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center">
      <div className="rounded-lg border-2 border-dashed border-gray-300 bg-white p-12 text-center">
        <p className="text-4xl">🚧</p>
        <h2 className="mt-4 text-xl font-semibold text-gray-900">{titulo}</h2>
        <p className="mt-2 text-sm text-gray-500">
          Este módulo será implementado na próxima entrega.
        </p>
      </div>
    </div>
  );
}
APP_EOF

cat > src/main.tsx <<'MAIN_EOF'
import React from 'react';
import ReactDOM from 'react-dom/client';
import { App } from './App';
import './index.css';

ReactDOM.createRoot(document.getElementById('root')!).render(
  <React.StrictMode>
    <App />
  </React.StrictMode>,
);
MAIN_EOF

# ============================================================
# 15. GITIGNORE
# ============================================================
cat > .gitignore <<'GIT_EOF'
node_modules
dist
dist-ssr
*.local
.env
.env.local
.DS_Store
*.log
GIT_EOF

# ============================================================
# 16. VOLTAR PARA A RAIZ
# ============================================================
cd ..

# Adicionar frontend ao .gitignore do projeto principal (se ainda não estiver)
if ! grep -q "frontend/node_modules" .gitignore 2>/dev/null; then
  echo "frontend/node_modules" >> .gitignore
  echo "frontend/dist" >> .gitignore
  echo "frontend/.env" >> .gitignore
fi

echo ""
echo "✅ Frontend A1 instalado em ./frontend"
echo ""
echo "📦 Próximo passo — instalar dependências:"
echo "   cd frontend && npm install"
echo ""
echo "🚀 Depois, para rodar:"
echo "   cd frontend && npm run dev"
echo ""
echo "🌐 O frontend abrirá em http://localhost:5173"