import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  regrasContabilizacaoService,
  CreateRegraPayload,
  UpdateRegraPayload,
  FilterRegras,
} from '@/services/regras-contabilizacao.service';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY = 'regras-contabilizacao';

export function useRegras(filtros: FilterRegras) {
  return useQuery({
    queryKey: [KEY, filtros],
    queryFn: () => regrasContabilizacaoService.listar(filtros),
    enabled: !!filtros.empresaId,
    placeholderData: (prev) => prev,
  });
}

export function useRegra(id: string | null) {
  return useQuery({
    queryKey: [KEY, id],
    queryFn: () => regrasContabilizacaoService.buscarPorId(id!),
    enabled: !!id,
  });
}

export function useCriarRegra(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateRegraPayload) =>
      regrasContabilizacaoService.criar(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY, { empresaId }] });
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Regra criada com sucesso');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useAtualizarRegra(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateRegraPayload }) =>
      regrasContabilizacaoService.atualizar(id, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Regra atualizada');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useInativarRegra(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => regrasContabilizacaoService.inativar(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Regra inativada');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useReativarRegra(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => regrasContabilizacaoService.reativar(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Regra reativada');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useExcluirRegra(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => regrasContabilizacaoService.excluir(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Regra excluída');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useSimularRegra(empresaId: string) {
  return useMutation({
    mutationFn: (xml: string) => regrasContabilizacaoService.simular(empresaId, xml),
    onError: (err) => toast.error(getApiError(err)),
  });
}
