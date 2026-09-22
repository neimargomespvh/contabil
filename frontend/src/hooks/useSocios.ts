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
