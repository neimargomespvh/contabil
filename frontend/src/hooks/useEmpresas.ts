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
