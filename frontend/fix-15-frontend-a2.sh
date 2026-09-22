#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil/frontend

mkdir -p src/{types,services,hooks,components/empresas,components/socios,pages/empresas}

# ============================================================
# 1. TIPOS
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

// ============ EMPRESA ============
export type RegimeTributario = 'SIMPLES' | 'PRESUMIDO' | 'REAL' | 'MEI';
export type AnexoSimples = 'I' | 'II' | 'III' | 'IV' | 'V';
export type EmpresaStatus = 'ATIVA' | 'INATIVA' | 'BAIXADA';

export interface Endereco {
  logradouro?: string;
  numero?: string;
  complemento?: string;
  bairro?: string;
  cidade?: string;
  uf?: string;
  cep?: string;
}

export interface Empresa {
  id: string;
  razaoSocial: string;
  nomeFantasia?: string;
  cnpj: string;
  inscricaoEstadual?: string;
  inscricaoMunicipal?: string;
  regimeTributario: RegimeTributario;
  anexoSimples?: AnexoSimples;
  cnaePrincipal?: string;
  cnaesSecundarios?: string[];
  dataAbertura?: string;
  dataRegimeAtual?: string;
  endereco?: Endereco;
  email?: string;
  telefone?: string;
  responsavelNome?: string;
  responsavelCpf?: string;
  status: EmpresaStatus;
  observacoes?: string;
  createdAt: string;
  updatedAt: string;
  _count?: {
    socios: number;
    lancamentos: number;
  };
}

export interface CreateEmpresaPayload {
  razaoSocial: string;
  nomeFantasia?: string;
  cnpj: string;
  inscricaoEstadual?: string;
  inscricaoMunicipal?: string;
  regimeTributario: RegimeTributario;
  anexoSimples?: AnexoSimples;
  cnaePrincipal?: string;
  dataAbertura?: string;
  dataRegimeAtual?: string;
  endereco?: Endereco;
  email?: string;
  telefone?: string;
  responsavelNome?: string;
  responsavelCpf?: string;
  observacoes?: string;
}

export interface FilterEmpresas {
  busca?: string;
  regimeTributario?: RegimeTributario;
  status?: EmpresaStatus;
  page?: number;
  limit?: number;
}

// ============ SÓCIO ============
export interface Socio {
  id: string;
  empresaId: string;
  nome: string;
  cpf: string;
  participacao: number;
  proLabore?: number;
  dataEntrada?: string;
  dataSaida?: string;
  status: string;
  createdAt: string;
}

export interface CreateSocioPayload {
  empresaId: string;
  nome: string;
  cpf: string;
  participacao: number;
  proLabore?: number;
  dataEntrada?: string;
}

export interface UpdateSocioPayload {
  nome?: string;
  cpf?: string;
  participacao?: number;
  proLabore?: number;
  dataEntrada?: string;
  dataSaida?: string;
}

export interface SociosResponse {
  data: Socio[];
  resumo: {
    total: number;
    participacaoTotal: number;
    participacaoCompleta: boolean;
  };
}

// ============ PAGINAÇÃO ============
export interface PaginatedResponse<T> {
  data: T[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}
TYPES_EOF

# ============================================================
# 2. SERVICE — EMPRESAS
# ============================================================
cat > src/services/empresas.service.ts <<'SVC_EOF'
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
SVC_EOF

# ============================================================
# 3. SERVICE — SÓCIOS
# ============================================================
cat > src/services/socios.service.ts <<'SVC_EOF'
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
SVC_EOF

# ============================================================
# 4. SERVICE — VIACEP
# ============================================================
cat > src/services/viacep.service.ts <<'VIACEP_EOF'
export interface EnderecoViaCep {
  cep: string;
  logradouro: string;
  complemento: string;
  bairro: string;
  localidade: string;
  uf: string;
  erro?: boolean;
}

export const viacepService = {
  async buscar(cep: string): Promise<EnderecoViaCep | null> {
    const limpo = cep.replace(/\D/g, '');
    if (limpo.length !== 8) return null;

    try {
      const res = await fetch(`https://viacep.com.br/ws/${limpo}/json/`);
      if (!res.ok) return null;
      const data = (await res.json()) as EnderecoViaCep;
      if (data.erro) return null;
      return data;
    } catch {
      return null;
    }
  },
};
VIACEP_EOF

# ============================================================
# 5. VALIDAÇÕES
# ============================================================
cat > src/lib/validacoes.ts <<'VAL_EOF'
export function validarCnpj(cnpj: string): boolean {
  const limpo = cnpj.replace(/\D/g, '');
  if (limpo.length !== 14) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcular = (base: string, pesos: number[]): number => {
    const soma = base.split('').reduce((acc, d, i) => acc + parseInt(d, 10) * pesos[i], 0);
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };

  const p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  const d1 = calcular(limpo.slice(0, 12), p1);
  const d2 = calcular(limpo.slice(0, 13), p2);

  return limpo === limpo.slice(0, 12) + d1 + d2;
}

export function validarCpf(cpf: string): boolean {
  const limpo = cpf.replace(/\D/g, '');
  if (limpo.length !== 11) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcular = (base: string): number => {
    const fator = base.length + 1;
    const soma = base.split('').reduce((acc, d, i) => acc + parseInt(d, 10) * (fator - i), 0);
    const resto = (soma * 10) % 11;
    return resto === 10 ? 0 : resto;
  };

  const d1 = calcular(limpo.slice(0, 9));
  const d2 = calcular(limpo.slice(0, 10));

  return limpo === limpo.slice(0, 9) + d1 + d2;
}

export function mascararCnpj(v: string): string {
  const limpo = v.replace(/\D/g, '').slice(0, 14);
  return limpo
    .replace(/^(\d{2})(\d)/, '$1.$2')
    .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1/$2')
    .replace(/(\d{4})(\d)/, '$1-$2');
}

export function mascararCpf(v: string): string {
  const limpo = v.replace(/\D/g, '').slice(0, 11);
  return limpo
    .replace(/^(\d{3})(\d)/, '$1.$2')
    .replace(/^(\d{3})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1-$2');
}

export function mascararCep(v: string): string {
  const limpo = v.replace(/\D/g, '').slice(0, 8);
  return limpo.replace(/^(\d{5})(\d)/, '$1-$2');
}
VAL_EOF

# ============================================================
# 6. HOOKS — EMPRESAS
# ============================================================
cat > src/hooks/useEmpresas.ts <<'HOOK_EOF'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { empresasService } from '@/services/empresas.service';
import type { CreateEmpresaPayload, FilterEmpresas } from '@/types';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY = 'empresas';

export function useEmpresas(filtros: FilterEmpresas) {
  return useQuery({
    queryKey: [KEY, filtros],
    queryFn: () => empresasService.listar(filtros),
    placeholderData: (prev) => prev,
  });
}

export function useEmpresa(id: string | null) {
  return useQuery({
    queryKey: [KEY, id],
    queryFn: () => empresasService.buscarPorId(id!),
    enabled: !!id,
  });
}

export function useCriarEmpresa() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateEmpresaPayload) => empresasService.criar(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Empresa cadastrada com sucesso');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useAtualizarEmpresa() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: Partial<CreateEmpresaPayload> }) =>
      empresasService.atualizar(id, payload),
    onSuccess: (_, vars) => {
      qc.invalidateQueries({ queryKey: [KEY] });
      qc.invalidateQueries({ queryKey: [KEY, vars.id] });
      toast.success('Empresa atualizada');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useRemoverEmpresa() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => empresasService.remover(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Empresa removida');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}
HOOK_EOF

# ============================================================
# 7. HOOKS — SÓCIOS
# ============================================================
cat > src/hooks/useSocios.ts <<'HOOK_EOF'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { sociosService } from '@/services/socios.service';
import type { CreateSocioPayload, UpdateSocioPayload } from '@/types';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY = 'socios';

export function useSocios(empresaId: string | null) {
  return useQuery({
    queryKey: [KEY, empresaId],
    queryFn: () => sociosService.listarPorEmpresa(empresaId!),
    enabled: !!empresaId,
  });
}

export function useCriarSocio() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateSocioPayload) => sociosService.criar(payload),
    onSuccess: (_, vars) => {
      qc.invalidateQueries({ queryKey: [KEY, vars.empresaId] });
      toast.success('Sócio adicionado');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useAtualizarSocio(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateSocioPayload }) =>
      sociosService.atualizar(id, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY, empresaId] });
      toast.success('Sócio atualizado');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useRemoverSocio(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => sociosService.remover(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY, empresaId] });
      toast.success('Sócio removido');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}
HOOK_EOF

# ============================================================
# 8. COMPONENTE — MODAL
# ============================================================
cat > src/components/ui/Modal.tsx <<'MODAL_EOF'
import { useEffect, type ReactNode } from 'react';
import { X } from 'lucide-react';
import { cn } from '@/lib/utils';

interface ModalProps {
  isOpen: boolean;
  onClose: () => void;
  title: string;
  children: ReactNode;
  size?: 'sm' | 'md' | 'lg' | 'xl';
}

export function Modal({ isOpen, onClose, title, children, size = 'md' }: ModalProps) {
  useEffect(() => {
    if (isOpen) {
      document.body.style.overflow = 'hidden';
      const handler = (e: KeyboardEvent) => e.key === 'Escape' && onClose();
      window.addEventListener('keydown', handler);
      return () => {
        document.body.style.overflow = '';
        window.removeEventListener('keydown', handler);
      };
    }
  }, [isOpen, onClose]);

  if (!isOpen) return null;

  const sizes = {
    sm: 'max-w-md',
    md: 'max-w-xl',
    lg: 'max-w-3xl',
    xl: 'max-w-5xl',
  };

  return (
    <div className="fixed inset-0 z-50 flex items-start justify-center overflow-y-auto p-4 sm:p-6">
      <div className="fixed inset-0 bg-black/50" onClick={onClose} />
      <div
        className={cn(
          'relative my-8 w-full rounded-lg bg-white shadow-xl',
          sizes[size],
        )}
      >
        <div className="flex items-center justify-between border-b border-gray-200 px-6 py-4">
          <h2 className="text-lg font-semibold text-gray-900">{title}</h2>
          <button
            onClick={onClose}
            className="rounded-md p-1 text-gray-400 hover:bg-gray-100 hover:text-gray-600"
          >
            <X className="h-5 w-5" />
          </button>
        </div>
        <div className="px-6 py-4">{children}</div>
      </div>
    </div>
  );
}
MODAL_EOF

# ============================================================
# 9. COMPONENTE — CONFIRM DIALOG
# ============================================================
cat > src/components/ui/ConfirmDialog.tsx <<'CONFIRM_EOF'
import { AlertTriangle } from 'lucide-react';
import { Modal } from './Modal';
import { Button } from './Button';

interface ConfirmDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  variant?: 'danger' | 'primary';
  loading?: boolean;
}

export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirmar',
  variant = 'danger',
  loading,
}: ConfirmDialogProps) {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} size="sm">
      <div className="flex gap-4">
        <div
          className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full ${
            variant === 'danger' ? 'bg-red-100' : 'bg-blue-100'
          }`}
        >
          <AlertTriangle
            className={`h-5 w-5 ${variant === 'danger' ? 'text-red-600' : 'text-blue-600'}`}
          />
        </div>
        <p className="flex-1 pt-2 text-sm text-gray-700">{message}</p>
      </div>
      <div className="mt-6 flex justify-end gap-2">
        <Button variant="outline" onClick={onClose} disabled={loading}>
          Cancelar
        </Button>
        <Button
          variant={variant === 'danger' ? 'danger' : 'primary'}
          onClick={onConfirm}
          loading={loading}
        >
          {confirmText}
        </Button>
      </div>
    </Modal>
  );
}
CONFIRM_EOF

# ============================================================
# 10. COMPONENTE — BADGE
# ============================================================
cat > src/components/ui/Badge.tsx <<'BADGE_EOF'
import type { ReactNode } from 'react';
import { cn } from '@/lib/utils';

interface BadgeProps {
  children: ReactNode;
  variant?: 'default' | 'success' | 'warning' | 'danger' | 'info';
}

export function Badge({ children, variant = 'default' }: BadgeProps) {
  const variants = {
    default: 'bg-gray-100 text-gray-700',
    success: 'bg-emerald-100 text-emerald-700',
    warning: 'bg-amber-100 text-amber-700',
    danger: 'bg-red-100 text-red-700',
    info: 'bg-blue-100 text-blue-700',
  };

  return (
    <span
      className={cn(
        'inline-flex items-center rounded-full px-2 py-0.5 text-xs font-medium',
        variants[variant],
      )}
    >
      {children}
    </span>
  );
}
BADGE_EOF

# ============================================================
# 11. FORM — EMPRESA
# ============================================================
cat > src/components/empresas/EmpresaForm.tsx <<'FORM_EOF'
import { useEffect } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { toast } from '@/components/ui/Toast';
import { viacepService } from '@/services/viacep.service';
import {
  validarCnpj,
  validarCpf,
  mascararCnpj,
  mascararCpf,
  mascararCep,
} from '@/lib/validacoes';
import type { Empresa, CreateEmpresaPayload } from '@/types';

const schema = z.object({
  razaoSocial: z.string().min(3, 'Mínimo 3 caracteres').max(200),
  nomeFantasia: z.string().max(200).optional().or(z.literal('')),
  cnpj: z
    .string()
    .length(18, 'CNPJ incompleto')
    .refine(validarCnpj, 'CNPJ inválido'),
  inscricaoEstadual: z.string().max(20).optional().or(z.literal('')),
  inscricaoMunicipal: z.string().max(20).optional().or(z.literal('')),
  regimeTributario: z.enum(['SIMPLES', 'PRESUMIDO', 'REAL', 'MEI']),
  anexoSimples: z.enum(['', 'I', 'II', 'III', 'IV', 'V']).optional(),
  cnaePrincipal: z.string().max(10).optional().or(z.literal('')),
  dataAbertura: z.string().optional().or(z.literal('')),
  email: z.string().email('Email inválido').optional().or(z.literal('')),
  telefone: z.string().max(20).optional().or(z.literal('')),
  responsavelNome: z.string().max(200).optional().or(z.literal('')),
  responsavelCpf: z
    .string()
    .optional()
    .or(z.literal(''))
    .refine((v) => !v || validarCpf(v), 'CPF inválido'),
  observacoes: z.string().optional().or(z.literal('')),
  cep: z.string().optional().or(z.literal('')),
  logradouro: z.string().optional().or(z.literal('')),
  numero: z.string().optional().or(z.literal('')),
  complemento: z.string().optional().or(z.literal('')),
  bairro: z.string().optional().or(z.literal('')),
  cidade: z.string().optional().or(z.literal('')),
  uf: z.string().max(2).optional().or(z.literal('')),
});

type FormData = z.infer<typeof schema>;

interface EmpresaFormProps {
  empresa?: Empresa;
  onSubmit: (payload: CreateEmpresaPayload) => void;
  onCancel: () => void;
  loading?: boolean;
}

export function EmpresaForm({ empresa, onSubmit, onCancel, loading }: EmpresaFormProps) {
  const {
    register,
    handleSubmit,
    setValue,
    watch,
    formState: { errors },
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: empresa
      ? {
          razaoSocial: empresa.razaoSocial,
          nomeFantasia: empresa.nomeFantasia ?? '',
          cnpj: mascararCnpj(empresa.cnpj),
          inscricaoEstadual: empresa.inscricaoEstadual ?? '',
          inscricaoMunicipal: empresa.inscricaoMunicipal ?? '',
          regimeTributario: empresa.regimeTributario,
          anexoSimples: empresa.anexoSimples ?? '',
          cnaePrincipal: empresa.cnaePrincipal ?? '',
          dataAbertura: empresa.dataAbertura?.slice(0, 10) ?? '',
          email: empresa.email ?? '',
          telefone: empresa.telefone ?? '',
          responsavelNome: empresa.responsavelNome ?? '',
          responsavelCpf: empresa.responsavelCpf ? mascararCpf(empresa.responsavelCpf) : '',
          observacoes: empresa.observacoes ?? '',
          cep: empresa.endereco?.cep ? mascararCep(empresa.endereco.cep) : '',
          logradouro: empresa.endereco?.logradouro ?? '',
          numero: empresa.endereco?.numero ?? '',
          complemento: empresa.endereco?.complemento ?? '',
          bairro: empresa.endereco?.bairro ?? '',
          cidade: empresa.endereco?.cidade ?? '',
          uf: empresa.endereco?.uf ?? '',
        }
      : {
          regimeTributario: 'SIMPLES',
          anexoSimples: 'I',
        },
  });

  const regime = watch('regimeTributario');

  const handleCepChange = async (e: React.ChangeEvent<HTMLInputElement>) => {
    const valor = mascararCep(e.target.value);
    setValue('cep', valor);

    if (valor.length === 9) {
      const dados = await viacepService.buscar(valor);
      if (dados) {
        setValue('logradouro', dados.logradouro);
        setValue('bairro', dados.bairro);
        setValue('cidade', dados.localidade);
        setValue('uf', dados.uf);
        toast.success('Endereço preenchido pelo ViaCEP');
      }
    }
  };

  const handleCnpjChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setValue('cnpj', mascararCnpj(e.target.value));
  };

  const handleCpfChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setValue('responsavelCpf', mascararCpf(e.target.value));
  };

  const submit = (data: FormData) => {
    const payload: CreateEmpresaPayload = {
      razaoSocial: data.razaoSocial,
      nomeFantasia: data.nomeFantasia || undefined,
      cnpj: data.cnpj.replace(/\D/g, ''),
      inscricaoEstadual: data.inscricaoEstadual || undefined,
      inscricaoMunicipal: data.inscricaoMunicipal || undefined,
      regimeTributario: data.regimeTributario,
      anexoSimples:
        data.regimeTributario === 'SIMPLES' && data.anexoSimples
          ? (data.anexoSimples as any)
          : undefined,
      cnaePrincipal: data.cnaePrincipal || undefined,
      dataAbertura: data.dataAbertura || undefined,
      email: data.email || undefined,
      telefone: data.telefone || undefined,
      responsavelNome: data.responsavelNome || undefined,
      responsavelCpf: data.responsavelCpf ? data.responsavelCpf.replace(/\D/g, '') : undefined,
      observacoes: data.observacoes || undefined,
      endereco:
        data.cep || data.logradouro || data.cidade
          ? {
              cep: data.cep?.replace(/\D/g, ''),
              logradouro: data.logradouro,
              numero: data.numero,
              complemento: data.complemento,
              bairro: data.bairro,
              cidade: data.cidade,
              uf: data.uf,
            }
          : undefined,
    };

    onSubmit(payload);
  };

  return (
    <form onSubmit={handleSubmit(submit)} className="space-y-6">
      {/* Dados principais */}
      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Dados da Empresa
        </h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="sm:col-span-2">
            <Label htmlFor="razaoSocial">Razão Social *</Label>
            <Input
              id="razaoSocial"
              {...register('razaoSocial')}
              error={errors.razaoSocial?.message}
            />
          </div>

          <div>
            <Label htmlFor="nomeFantasia">Nome Fantasia</Label>
            <Input id="nomeFantasia" {...register('nomeFantasia')} />
          </div>

          <div>
            <Label htmlFor="cnpj">CNPJ *</Label>
            <Input
              id="cnpj"
              {...register('cnpj')}
              onChange={handleCnpjChange}
              placeholder="00.000.000/0000-00"
              error={errors.cnpj?.message}
            />
          </div>

          <div>
            <Label htmlFor="inscricaoEstadual">Inscrição Estadual</Label>
            <Input id="inscricaoEstadual" {...register('inscricaoEstadual')} />
          </div>

          <div>
            <Label htmlFor="inscricaoMunicipal">Inscrição Municipal</Label>
            <Input id="inscricaoMunicipal" {...register('inscricaoMunicipal')} />
          </div>

          <div>
            <Label htmlFor="regimeTributario">Regime Tributário *</Label>
            <select
              id="regimeTributario"
              {...register('regimeTributario')}
              className="input-base"
            >
              <option value="SIMPLES">Simples Nacional</option>
              <option value="PRESUMIDO">Lucro Presumido</option>
              <option value="REAL">Lucro Real</option>
              <option value="MEI">MEI</option>
            </select>
          </div>

          {regime === 'SIMPLES' && (
            <div>
              <Label htmlFor="anexoSimples">Anexo do Simples</Label>
              <select id="anexoSimples" {...register('anexoSimples')} className="input-base">
                <option value="">— Selecione —</option>
                <option value="I">Anexo I — Comércio</option>
                <option value="II">Anexo II — Indústria</option>
                <option value="III">Anexo III — Serviços</option>
                <option value="IV">Anexo IV — Serviços (construção)</option>
                <option value="V">Anexo V — Serviços (tecnologia)</option>
              </select>
            </div>
          )}

          <div>
            <Label htmlFor="cnaePrincipal">CNAE Principal</Label>
            <Input id="cnaePrincipal" {...register('cnaePrincipal')} />
          </div>

          <div>
            <Label htmlFor="dataAbertura">Data de Abertura</Label>
            <Input id="dataAbertura" type="date" {...register('dataAbertura')} />
          </div>
        </div>
      </div>

      {/* Endereço */}
      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Endereço
        </h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-6">
          <div className="sm:col-span-2">
            <Label htmlFor="cep">CEP</Label>
            <Input
              id="cep"
              {...register('cep')}
              onChange={handleCepChange}
              placeholder="00000-000"
            />
          </div>

          <div className="sm:col-span-4">
            <Label htmlFor="logradouro">Logradouro</Label>
            <Input id="logradouro" {...register('logradouro')} />
          </div>

          <div className="sm:col-span-2">
            <Label htmlFor="numero">Número</Label>
            <Input id="numero" {...register('numero')} />
          </div>

          <div className="sm:col-span-4">
            <Label htmlFor="complemento">Complemento</Label>
            <Input id="complemento" {...register('complemento')} />
          </div>

          <div className="sm:col-span-3">
            <Label htmlFor="bairro">Bairro</Label>
            <Input id="bairro" {...register('bairro')} />
          </div>

          <div className="sm:col-span-2">
            <Label htmlFor="cidade">Cidade</Label>
            <Input id="cidade" {...register('cidade')} />
          </div>

          <div className="sm:col-span-1">
            <Label htmlFor="uf">UF</Label>
            <Input id="uf" {...register('uf')} maxLength={2} />
          </div>
        </div>
      </div>

      {/* Contato */}
      <div>
        <h3 className="mb-3 text-sm font-semibold uppercase tracking-wide text-gray-500">
          Contato e Responsável
        </h3>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div>
            <Label htmlFor="email">Email</Label>
            <Input id="email" type="email" {...register('email')} />
          </div>

          <div>
            <Label htmlFor="telefone">Telefone</Label>
            <Input id="telefone" {...register('telefone')} placeholder="(00) 00000-0000" />
          </div>

          <div>
            <Label htmlFor="responsavelNome">Nome do Responsável</Label>
            <Input id="responsavelNome" {...register('responsavelNome')} />
          </div>

          <div>
            <Label htmlFor="responsavelCpf">CPF do Responsável</Label>
            <Input
              id="responsavelCpf"
              {...register('responsavelCpf')}
              onChange={handleCpfChange}
              placeholder="000.000.000-00"
              error={errors.responsavelCpf?.message}
            />
          </div>
        </div>
      </div>

      {/* Observações */}
      <div>
        <Label htmlFor="observacoes">Observações</Label>
        <textarea
          id="observacoes"
          {...register('observacoes')}
          rows={3}
          className="input-base h-auto py-2"
          placeholder="Anotações internas sobre a empresa..."
        />
      </div>

      <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          Cancelar
        </Button>
        <Button type="submit" loading={loading}>
          {empresa ? 'Salvar alterações' : 'Cadastrar empresa'}
        </Button>
      </div>
    </form>
  );
}
FORM_EOF

# ============================================================
# 12. MODAL DE EMPRESA
# ============================================================
cat > src/components/empresas/EmpresaModal.tsx <<'MODAL_EMP_EOF'
import { Modal } from '@/components/ui/Modal';
import { EmpresaForm } from './EmpresaForm';
import { useCriarEmpresa, useAtualizarEmpresa } from '@/hooks/useEmpresas';
import type { Empresa, CreateEmpresaPayload } from '@/types';

interface EmpresaModalProps {
  isOpen: boolean;
  onClose: () => void;
  empresa?: Empresa | null;
}

export function EmpresaModal({ isOpen, onClose, empresa }: EmpresaModalProps) {
  const criar = useCriarEmpresa();
  const atualizar = useAtualizarEmpresa();

  const handleSubmit = (payload: CreateEmpresaPayload) => {
    if (empresa) {
      atualizar.mutate(
        { id: empresa.id, payload },
        { onSuccess: onClose },
      );
    } else {
      criar.mutate(payload, { onSuccess: onClose });
    }
  };

  const loading = criar.isPending || atualizar.isPending;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={empresa ? `Editar — ${empresa.razaoSocial}` : 'Nova Empresa'}
      size="lg"
    >
      <EmpresaForm
        empresa={empresa ?? undefined}
        onSubmit={handleSubmit}
        onCancel={onClose}
        loading={loading}
      />
    </Modal>
  );
}
MODAL_EMP_EOF

# ============================================================
# 13. COMPONENTE — TABELA DE EMPRESAS
# ============================================================
cat > src/components/empresas/EmpresasTable.tsx <<'TABLE_EOF'
import { Eye, Pencil, Trash2, Building2 } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Spinner } from '@/components/ui/Spinner';
import { formatCnpj } from '@/lib/format';
import type { Empresa } from '@/types';

interface EmpresasTableProps {
  empresas: Empresa[];
  loading: boolean;
  onEditar: (e: Empresa) => void;
  onRemover: (e: Empresa) => void;
}

const REGIME_LABEL: Record<string, string> = {
  SIMPLES: 'Simples Nacional',
  PRESUMIDO: 'Lucro Presumido',
  REAL: 'Lucro Real',
  MEI: 'MEI',
};

export function EmpresasTable({ empresas, loading, onEditar, onRemover }: EmpresasTableProps) {
  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner size="lg" />
      </div>
    );
  }

  if (empresas.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-white py-16">
        <Building2 className="h-12 w-12 text-gray-400" />
        <h3 className="mt-4 text-lg font-semibold text-gray-900">Nenhuma empresa cadastrada</h3>
        <p className="mt-1 text-sm text-gray-500">
          Comece cadastrando sua primeira empresa cliente
        </p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
      <table className="w-full">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
              Empresa
            </th>
            <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 md:table-cell">
              CNPJ
            </th>
            <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
              Regime
            </th>
            <th className="hidden px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
              Sócios
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
              Status
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
              Ações
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {empresas.map((emp) => (
            <tr key={emp.id} className="hover:bg-gray-50">
              <td className="px-4 py-3">
                <div>
                  <p className="font-medium text-gray-900">{emp.razaoSocial}</p>
                  {emp.nomeFantasia && (
                    <p className="text-xs text-gray-500">{emp.nomeFantasia}</p>
                  )}
                </div>
              </td>
              <td className="hidden px-4 py-3 text-sm text-gray-600 md:table-cell">
                {formatCnpj(emp.cnpj)}
              </td>
              <td className="hidden px-4 py-3 text-sm text-gray-600 lg:table-cell">
                {REGIME_LABEL[emp.regimeTributario] ?? emp.regimeTributario}
                {emp.anexoSimples && (
                  <span className="ml-1 text-xs text-gray-400">(Anexo {emp.anexoSimples})</span>
                )}
              </td>
              <td className="hidden px-4 py-3 text-center text-sm text-gray-600 lg:table-cell">
                {emp._count?.socios ?? 0}
              </td>
              <td className="px-4 py-3">
                <Badge variant={emp.status === 'ATIVA' ? 'success' : 'default'}>
                  {emp.status}
                </Badge>
              </td>
              <td className="px-4 py-3">
                <div className="flex items-center justify-end gap-1">
                  <Link to={`/empresas/${emp.id}`}>
                    <Button variant="ghost" size="sm" title="Ver detalhes">
                      <Eye className="h-4 w-4" />
                    </Button>
                  </Link>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onEditar(emp)}
                    title="Editar"
                  >
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onRemover(emp)}
                    className="text-red-600 hover:bg-red-50"
                    title="Remover"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
TABLE_EOF

# ============================================================
# 14. COMPONENTE — PAGINAÇÃO
# ============================================================
cat > src/components/ui/Pagination.tsx <<'PAG_EOF'
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from './Button';

interface PaginationProps {
  page: number;
  totalPages: number;
  total: number;
  limit: number;
  onChange: (page: number) => void;
}

export function Pagination({ page, totalPages, total, limit, onChange }: PaginationProps) {
  if (totalPages <= 1) return null;

  const inicio = (page - 1) * limit + 1;
  const fim = Math.min(page * limit, total);

  return (
    <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
      <p className="text-sm text-gray-600">
        Mostrando <span className="font-medium">{inicio}</span> a{' '}
        <span className="font-medium">{fim}</span> de{' '}
        <span className="font-medium">{total}</span> resultados
      </p>

      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          disabled={page <= 1}
          onClick={() => onChange(page - 1)}
        >
          <ChevronLeft className="h-4 w-4" />
          Anterior
        </Button>

        <span className="px-3 text-sm text-gray-600">
          Página <span className="font-medium">{page}</span> de{' '}
          <span className="font-medium">{totalPages}</span>
        </span>

        <Button
          variant="outline"
          size="sm"
          disabled={page >= totalPages}
          onClick={() => onChange(page + 1)}
        >
          Próxima
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
PAG_EOF

# ============================================================
# 15. PÁGINA — LISTA DE EMPRESAS
# ============================================================
cat > src/pages/empresas/EmpresasList.tsx <<'LIST_EOF'
import { useState } from 'react';
import { Plus, Search, Filter } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Pagination } from '@/components/ui/Pagination';
import { EmpresasTable } from '@/components/empresas/EmpresasTable';
import { EmpresaModal } from '@/components/empresas/EmpresaModal';
import { useEmpresas, useRemoverEmpresa } from '@/hooks/useEmpresas';
import { useDebounce } from '@/hooks/useDebounce';
import type { Empresa, RegimeTributario, EmpresaStatus } from '@/types';

export function EmpresasListPage() {
  const [page, setPage] = useState(1);
  const [busca, setBusca] = useState('');
  const [regime, setRegime] = useState<RegimeTributario | ''>('');
  const [status, setStatus] = useState<EmpresaStatus | ''>('ATIVA');
  const [modalOpen, setModalOpen] = useState(false);
  const [editando, setEditando] = useState<Empresa | null>(null);
  const [removendo, setRemovendo] = useState<Empresa | null>(null);

  const buscaDebounced = useDebounce(busca, 400);

  const { data, isLoading } = useEmpresas({
    page,
    limit: 20,
    busca: buscaDebounced || undefined,
    regimeTributario: regime || undefined,
    status: status || undefined,
  });

  const remover = useRemoverEmpresa();

  const handleNovo = () => {
    setEditando(null);
    setModalOpen(true);
  };

  const handleEditar = (emp: Empresa) => {
    setEditando(emp);
    setModalOpen(true);
  };

  const handleRemover = () => {
    if (!removendo) return;
    remover.mutate(removendo.id, {
      onSuccess: () => setRemovendo(null),
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Empresas</h1>
          <p className="mt-1 text-sm text-gray-500">
            Gerencie os clientes do seu escritório
          </p>
        </div>
        <Button onClick={handleNovo}>
          <Plus className="h-4 w-4" />
          Nova Empresa
        </Button>
      </div>

      {/* Filtros */}
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div className="lg:col-span-2">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <Input
                placeholder="Buscar por razão social, fantasia ou CNPJ..."
                value={busca}
                onChange={(e) => { setBusca(e.target.value); setPage(1); }}
                className="pl-9"
              />
            </div>
          </div>

          <select
            className="input-base"
            value={regime}
            onChange={(e) => { setRegime(e.target.value as any); setPage(1); }}
          >
            <option value="">Todos os regimes</option>
            <option value="SIMPLES">Simples Nacional</option>
            <option value="PRESUMIDO">Lucro Presumido</option>
            <option value="REAL">Lucro Real</option>
            <option value="MEI">MEI</option>
          </select>

          <select
            className="input-base"
            value={status}
            onChange={(e) => { setStatus(e.target.value as any); setPage(1); }}
          >
            <option value="">Todos os status</option>
            <option value="ATIVA">Ativas</option>
            <option value="INATIVA">Inativas</option>
            <option value="BAIXADA">Baixadas</option>
          </select>
        </div>
      </div>

      {/* Tabela */}
      <EmpresasTable
        empresas={data?.data ?? []}
        loading={isLoading}
        onEditar={handleEditar}
        onRemover={setRemovendo}
      />

      {/* Paginação */}
      {data && data.meta.totalPages > 1 && (
        <Pagination
          page={data.meta.page}
          totalPages={data.meta.totalPages}
          total={data.meta.total}
          limit={data.meta.limit}
          onChange={setPage}
        />
      )}

      {/* Modal */}
      <EmpresaModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditando(null); }}
        empresa={editando}
      />

      {/* Confirm delete */}
      <ConfirmDialog
        isOpen={!!removendo}
        onClose={() => setRemovendo(null)}
        onConfirm={handleRemover}
        title="Remover empresa"
        message={`Tem certeza que deseja remover "${removendo?.razaoSocial}"? Esta ação marcará a empresa como baixada.`}
        confirmText="Remover"
        loading={remover.isPending}
      />
    </div>
  );
}
LIST_EOF

# ============================================================
# 16. HOOK — DEBOUNCE
# ============================================================
cat > src/hooks/useDebounce.ts <<'DEB_EOF'
import { useEffect, useState } from 'react';

export function useDebounce<T>(value: T, delay = 500): T {
  const [debounced, setDebounced] = useState(value);

  useEffect(() => {
    const timer = setTimeout(() => setDebounced(value), delay);
    return () => clearTimeout(timer);
  }, [value, delay]);

  return debounced;
}
DEB_EOF

# ============================================================
# 17. PÁGINA — DETALHE DE EMPRESA (com sócios)
# ============================================================
cat > src/components/socios/SocioModal.tsx <<'SOCIO_MODAL_EOF'
import { useEffect, useState } from 'react';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import { z } from 'zod';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { useCriarSocio, useAtualizarSocio } from '@/hooks/useSocios';
import { validarCpf, mascararCpf } from '@/lib/validacoes';
import type { Socio, CreateSocioPayload } from '@/types';

const schema = z.object({
  nome: z.string().min(3, 'Mínimo 3 caracteres').max(200),
  cpf: z.string().refine(validarCpf, 'CPF inválido'),
  participacao: z
    .number({ invalid_type_error: 'Informe um número' })
    .min(0.000001, 'Deve ser maior que zero')
    .max(100, 'Máximo 100%'),
  proLabore: z.number().min(0).optional(),
  dataEntrada: z.string().optional().or(z.literal('')),
});

type FormData = z.infer<typeof schema>;

interface SocioModalProps {
  isOpen: boolean;
  onClose: () => void;
  empresaId: string;
  socio?: Socio | null;
  participacaoDisponivel: number;
}

export function SocioModal({
  isOpen,
  onClose,
  empresaId,
  socio,
  participacaoDisponivel,
}: SocioModalProps) {
  const criar = useCriarSocio();
  const atualizar = useAtualizarSocio(empresaId);

  const {
    register,
    handleSubmit,
    setValue,
    formState: { errors },
    reset,
  } = useForm<FormData>({
    resolver: zodResolver(schema),
    defaultValues: {
      nome: '',
      cpf: '',
      participacao: 0,
      proLabore: undefined,
      dataEntrada: '',
    },
  });

  useEffect(() => {
    if (isOpen) {
      reset(
        socio
          ? {
              nome: socio.nome,
              cpf: mascararCpf(socio.cpf),
              participacao: Number(socio.participacao),
              proLabore: socio.proLabore ? Number(socio.proLabore) : undefined,
              dataEntrada: socio.dataEntrada?.slice(0, 10) ?? '',
            }
          : {
              nome: '',
              cpf: '',
              participacao: 0,
              proLabore: undefined,
              dataEntrada: '',
            },
      );
    }
  }, [isOpen, socio, reset]);

  const handleCpfChange = (e: React.ChangeEvent<HTMLInputElement>) => {
    setValue('cpf', mascararCpf(e.target.value));
  };

  const submit = (data: FormData) => {
    const payload: CreateSocioPayload = {
      empresaId,
      nome: data.nome,
      cpf: data.cpf.replace(/\D/g, ''),
      participacao: Number(data.participacao),
      proLabore: data.proLabore ? Number(data.proLabore) : undefined,
      dataEntrada: data.dataEntrada || undefined,
    };

    if (socio) {
      atualizar.mutate(
        {
          id: socio.id,
          payload: {
            nome: payload.nome,
            cpf: payload.cpf,
            participacao: payload.participacao,
            proLabore: payload.proLabore,
            dataEntrada: payload.dataEntrada,
          },
        },
        { onSuccess: onClose },
      );
    } else {
      criar.mutate(payload, { onSuccess: onClose });
    }
  };

  const loading = criar.isPending || atualizar.isPending;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={socio ? `Editar sócio — ${socio.nome}` : 'Novo sócio'}
      size="md"
    >
      <form onSubmit={handleSubmit(submit)} className="space-y-4">
        <div>
          <Label htmlFor="nome">Nome completo *</Label>
          <Input id="nome" {...register('nome')} error={errors.nome?.message} />
        </div>

        <div>
          <Label htmlFor="cpf">CPF *</Label>
          <Input
            id="cpf"
            {...register('cpf')}
            onChange={handleCpfChange}
            placeholder="000.000.000-00"
            error={errors.cpf?.message}
          />
        </div>

        <div className="grid grid-cols-2 gap-4">
          <div>
            <Label htmlFor="participacao">
              Participação (%) *
              {!socio && (
                <span className="ml-1 text-xs font-normal text-gray-400">
                  (até {participacaoDisponivel.toFixed(2)}%)
                </span>
              )}
            </Label>
            <Input
              id="participacao"
              type="number"
              step="0.000001"
              {...register('participacao', { valueAsNumber: true })}
              error={errors.participacao?.message}
            />
          </div>

          <div>
            <Label htmlFor="proLabore">Pró-labore (R$)</Label>
            <Input
              id="proLabore"
              type="number"
              step="0.01"
              {...register('proLabore', { valueAsNumber: true })}
            />
          </div>
        </div>

        <div>
          <Label htmlFor="dataEntrada">Data de entrada</Label>
          <Input id="dataEntrada" type="date" {...register('dataEntrada')} />
        </div>

        <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
          <Button type="button" variant="outline" onClick={onClose} disabled={loading}>
            Cancelar
          </Button>
          <Button type="submit" loading={loading}>
            {socio ? 'Salvar alterações' : 'Adicionar sócio'}
          </Button>
        </div>
      </form>
    </Modal>
  );
}
SOCIO_MODAL_EOF

cat > src/components/socios/SociosTab.tsx <<'SOCIO_TAB_EOF'
import { useState } from 'react';
import { Plus, Pencil, Trash2, Users } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Spinner } from '@/components/ui/Spinner';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { SocioModal } from './SocioModal';
import { useSocios, useRemoverSocio } from '@/hooks/useSocios';
import { formatCpf, formatCurrency } from '@/lib/format';
import type { Socio } from '@/types';

interface SociosTabProps {
  empresaId: string;
}

export function SociosTab({ empresaId }: SociosTabProps) {
  const { data, isLoading } = useSocios(empresaId);
  const remover = useRemoverSocio(empresaId);

  const [modalOpen, setModalOpen] = useState(false);
  const [editando, setEditando] = useState<Socio | null>(null);
  const [removendo, setRemovendo] = useState<Socio | null>(null);

  const socios = data?.data ?? [];
  const resumo = data?.resumo;

  const participacaoDisponivel =
    100 - Number(resumo?.participacaoTotal ?? 0) + (editando ? Number(editando.participacao) : 0);

  const handleNovo = () => {
    setEditando(null);
    setModalOpen(true);
  };

  const handleEditar = (s: Socio) => {
    setEditando(s);
    setModalOpen(true);
  };

  const handleRemover = () => {
    if (!removendo) return;
    remover.mutate(removendo.id, {
      onSuccess: () => setRemovendo(null),
    });
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Quadro Societário</h3>
          {resumo && (
            <p className="mt-1 text-sm text-gray-500">
              {resumo.total} sócio(s) —{' '}
              <span className={resumo.participacaoCompleta ? 'text-emerald-600' : 'text-amber-600'}>
                {resumo.participacaoTotal.toFixed(2)}% do capital
              </span>
            </p>
          )}
        </div>
        <Button
          onClick={handleNovo}
          disabled={participacaoDisponivel <= 0 && !editando}
          title={
            participacaoDisponivel <= 0 ? 'Soma das participações já é 100%' : undefined
          }
        >
          <Plus className="h-4 w-4" />
          Novo Sócio
        </Button>
      </div>

      {socios.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-white py-12">
          <Users className="h-10 w-10 text-gray-400" />
          <p className="mt-3 text-sm font-medium text-gray-900">Nenhum sócio cadastrado</p>
          <p className="mt-1 text-xs text-gray-500">
            Adicione os sócios desta empresa
          </p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
                  Nome
                </th>
                <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 sm:table-cell">
                  CPF
                </th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
                  Participação
                </th>
                <th className="hidden px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
                  Pró-labore
                </th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
                  Ações
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {socios.map((s) => (
                <tr key={s.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <p className="font-medium text-gray-900">{s.nome}</p>
                  </td>
                  <td className="hidden px-4 py-3 text-sm text-gray-600 sm:table-cell">
                    {formatCpf(s.cpf)}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Badge variant={Number(s.participacao) >= 50 ? 'info' : 'default'}>
                      {Number(s.participacao).toFixed(4)}%
                    </Badge>
                  </td>
                  <td className="hidden px-4 py-3 text-right text-sm text-gray-600 lg:table-cell">
                    {s.proLabore ? formatCurrency(Number(s.proLabore)) : '—'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEditar(s)}
                        title="Editar"
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-red-600 hover:bg-red-50"
                        onClick={() => setRemovendo(s)}
                        title="Remover"
                      >
                        <Trash2 className="h-4 w-4" />
                      </Button>
                    </div>
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      )}

      <SocioModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditando(null); }}
        empresaId={empresaId}
        socio={editando}
        participacaoDisponivel={Math.max(0, participacaoDisponivel)}
      />

      <ConfirmDialog
        isOpen={!!removendo}
        onClose={() => setRemovendo(null)}
        onConfirm={handleRemover}
        title="Remover sócio"
        message={`Tem certeza que deseja remover "${removendo?.nome}" do quadro societário?`}
        confirmText="Remover"
        loading={remover.isPending}
      />
    </div>
  );
}
SOCIO_TAB_EOF

# ============================================================
# 18. PÁGINA — DETALHE DE EMPRESA
# ============================================================
cat > src/pages/empresas/EmpresaDetail.tsx <<'DETAIL_EOF'
import { useState } from 'react';
import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, Pencil, Building2, Users, FileText } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Spinner } from '@/components/ui/Spinner';
import { EmpresaModal } from '@/components/empresas/EmpresaModal';
import { SociosTab } from '@/components/socios/SociosTab';
import { useEmpresa } from '@/hooks/useEmpresas';
import { formatCnpj, formatCpf } from '@/lib/format';
import { cn } from '@/lib/utils';

type Tab = 'dados' | 'socios' | 'lancamentos';

const REGIME_LABEL: Record<string, string> = {
  SIMPLES: 'Simples Nacional',
  PRESUMIDO: 'Lucro Presumido',
  REAL: 'Lucro Real',
  MEI: 'MEI',
};

export function EmpresaDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: empresa, isLoading } = useEmpresa(id ?? null);
  const [editOpen, setEditOpen] = useState(false);
  const [tab, setTab] = useState<Tab>('dados');

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size="lg" />
      </div>
    );
  }

  if (!empresa) {
    return (
      <div className="py-20 text-center">
        <p className="text-gray-500">Empresa não encontrada</p>
        <Link to="/empresas" className="mt-4 inline-block">
          <Button variant="outline">Voltar</Button>
        </Link>
      </div>
    );
  }

  const tabs = [
    { id: 'dados' as Tab, label: 'Dados', icon: Building2 },
    { id: 'socios' as Tab, label: 'Sócios', icon: Users },
    { id: 'lancamentos' as Tab, label: 'Lançamentos', icon: FileText },
  ];

  return (
    <div className="space-y-6">
      {/* Header */}
      <div>
        <Link
          to="/empresas"
          className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
        >
          <ArrowLeft className="h-4 w-4" />
          Voltar para Empresas
        </Link>
      </div>

      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div className="flex items-start gap-4">
          <div className="flex h-14 w-14 flex-shrink-0 items-center justify-center rounded-lg bg-brand-100 text-xl font-bold text-brand-700">
            {empresa.razaoSocial.charAt(0).toUpperCase()}
          </div>
          <div>
            <h1 className="text-2xl font-bold text-gray-900">{empresa.razaoSocial}</h1>
            <p className="text-sm text-gray-500">
              {empresa.nomeFantasia && `${empresa.nomeFantasia} · `}
              {formatCnpj(empresa.cnpj)}
            </p>
            <div className="mt-2 flex flex-wrap gap-2">
              <Badge variant={empresa.status === 'ATIVA' ? 'success' : 'default'}>
                {empresa.status}
              </Badge>
              <Badge variant="info">{REGIME_LABEL[empresa.regimeTributario]}</Badge>
              {empresa.anexoSimples && <Badge>Anexo {empresa.anexoSimples}</Badge>}
            </div>
          </div>
        </div>

        <Button onClick={() => setEditOpen(true)} variant="outline">
          <Pencil className="h-4 w-4" />
          Editar
        </Button>
      </div>

      {/* Tabs */}
      <div className="border-b border-gray-200">
        <nav className="-mb-px flex gap-6">
          {tabs.map((t) => {
            const Icon = t.icon;
            return (
              <button
                key={t.id}
                onClick={() => setTab(t.id)}
                className={cn(
                  'flex items-center gap-2 border-b-2 px-1 py-3 text-sm font-medium transition-colors',
                  tab === t.id
                    ? 'border-brand-600 text-brand-600'
                    : 'border-transparent text-gray-500 hover:border-gray-300 hover:text-gray-700',
                )}
              >
                <Icon className="h-4 w-4" />
                {t.label}
              </button>
            );
          })}
        </nav>
      </div>

      {/* Conteúdo */}
      {tab === 'dados' && (
        <div className="grid grid-cols-1 gap-6 lg:grid-cols-2">
          <Card>
            <CardHeader>
              <CardTitle>Informações Gerais</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <Field label="CNPJ" value={formatCnpj(empresa.cnpj)} />
              <Field label="Razão Social" value={empresa.razaoSocial} />
              <Field label="Nome Fantasia" value={empresa.nomeFantasia || '—'} />
              <Field label="Inscrição Estadual" value={empresa.inscricaoEstadual || '—'} />
              <Field label="Inscrição Municipal" value={empresa.inscricaoMunicipal || '—'} />
              <Field label="CNAE Principal" value={empresa.cnaePrincipal || '—'} />
              <Field
                label="Data de Abertura"
                value={
                  empresa.dataAbertura
                    ? new Date(empresa.dataAbertura).toLocaleDateString('pt-BR')
                    : '—'
                }
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Endereço</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <Field label="CEP" value={empresa.endereco?.cep || '—'} />
              <Field label="Logradouro" value={empresa.endereco?.logradouro || '—'} />
              <Field label="Número" value={empresa.endereco?.numero || '—'} />
              <Field label="Complemento" value={empresa.endereco?.complemento || '—'} />
              <Field label="Bairro" value={empresa.endereco?.bairro || '—'} />
              <Field
                label="Cidade / UF"
                value={
                  empresa.endereco?.cidade
                    ? `${empresa.endereco.cidade} / ${empresa.endereco.uf}`
                    : '—'
                }
              />
            </CardContent>
          </Card>

          <Card>
            <CardHeader>
              <CardTitle>Contato e Responsável</CardTitle>
            </CardHeader>
            <CardContent className="space-y-3 text-sm">
              <Field label="Email" value={empresa.email || '—'} />
              <Field label="Telefone" value={empresa.telefone || '—'} />
              <Field label="Responsável" value={empresa.responsavelNome || '—'} />
              <Field
                label="CPF Responsável"
                value={empresa.responsavelCpf ? formatCpf(empresa.responsavelCpf) : '—'}
              />
            </CardContent>
          </Card>

          {empresa.observacoes && (
            <Card>
              <CardHeader>
                <CardTitle>Observações</CardTitle>
              </CardHeader>
              <CardContent>
                <p className="whitespace-pre-wrap text-sm text-gray-700">
                  {empresa.observacoes}
                </p>
              </CardContent>
            </Card>
          )}
        </div>
      )}

      {tab === 'socios' && <SociosTab empresaId={empresa.id} />}

      {tab === 'lancamentos' && (
        <div className="rounded-lg border-2 border-dashed border-gray-300 bg-white p-12 text-center">
          <FileText className="mx-auto h-10 w-10 text-gray-400" />
          <p className="mt-4 font-medium text-gray-900">Lançamentos contábeis</p>
          <p className="mt-1 text-sm text-gray-500">
            Será implementado no próximo pacote (A3)
          </p>
        </div>
      )}

      <EmpresaModal isOpen={editOpen} onClose={() => setEditOpen(false)} empresa={empresa} />
    </div>
  );
}

function Field({ label, value }: { label: string; value: string }) {
  return (
    <div className="flex justify-between gap-4 border-b border-gray-100 pb-2 last:border-0">
      <span className="text-gray-500">{label}</span>
      <span className="text-right font-medium text-gray-900">{value}</span>
    </div>
  );
}
DETAIL_EOF

# ============================================================
# 19. ATUALIZAR App.tsx COM AS ROTAS
# ============================================================
python3 <<'PYEOF'
import re
with open('src/App.tsx', 'r') as f:
    content = f.read()

# Adicionar imports
imports = """import { EmpresasListPage } from '@/pages/empresas/EmpresasList';
import { EmpresaDetailPage } from '@/pages/empresas/EmpresaDetail';
"""
if 'EmpresasListPage' not in content:
    content = content.replace(
        "import { LoginPage } from '@/pages/Login';",
        "import { LoginPage } from '@/pages/Login';\n" + imports
    )

# Substituir a rota placeholder de empresas
content = content.replace(
    '<Route path="empresas" element={<EmBreve titulo="Empresas" />} />',
    '<Route path="empresas" element={<EmpresasListPage />} />\n'
    '              <Route path="empresas/:id" element={<EmpresaDetailPage />} />'
)

with open('src/App.tsx', 'w') as f:
    f.write(content)
print("✅ App.tsx atualizado")
PYEOF

echo ""
echo "✅ Pacote A2 instalado!"
echo ""
echo "Rode agora:"
echo "  cd /home/neimar/Projetos/Contabil/frontend"
echo "  npm run dev"