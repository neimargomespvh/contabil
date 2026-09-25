import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  planoContasService,
  CreateContaPayload,
  UpdateContaPayload,
} from '@/services/plano-contas.service';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY_PLANOS = 'planos';
const KEY_CONTAS = 'contas';

export function usePlanos(empresaId: string | null) {
  return useQuery({
    queryKey: [KEY_PLANOS, empresaId],
    queryFn: () => planoContasService.listarPlanos(empresaId!),
    enabled: !!empresaId,
  });
}

export function usePlanoAtivo(empresaId: string | null) {
  return useQuery({
    queryKey: [KEY_PLANOS, 'ativo', empresaId],
    queryFn: async () => {
      const planos = await planoContasService.listarPlanos(empresaId!);
      return planos.find((p) => p.status === 'ATIVO') ?? planos[0] ?? null;
    },
    enabled: !!empresaId,
  });
}

export function useContasDoPlano(planoId: string | null) {
  return useQuery({
    queryKey: [KEY_CONTAS, planoId],
    queryFn: () => planoContasService.listarContas(planoId!),
    enabled: !!planoId,
  });
}

export function useCriarConta(planoId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateContaPayload) =>
      planoContasService.criarConta(planoId, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY_CONTAS, planoId] });
      toast.success('Conta criada com sucesso');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useAtualizarConta(planoId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, payload }: { id: string; payload: UpdateContaPayload }) =>
      planoContasService.atualizarConta(id, payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY_CONTAS, planoId] });
      toast.success('Conta atualizada');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useExcluirConta(planoId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => planoContasService.excluirConta(id),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY_CONTAS, planoId] });
      toast.success('Conta excluída');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useCriarPlanoPadrao(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (nome?: string) => planoContasService.criarPlanoPadrao(empresaId, nome),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY_PLANOS, empresaId] });
      toast.success('Plano padrão criado');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

/**
 * Achata a árvore em lista de contas analíticas.
 */
export function achatarContas(arvore: any[]): any[] {
  const resultado: any[] = [];
  function percorrer(nodes: any[]) {
    for (const node of nodes) {
      if (node.aceitaLancamento) resultado.push(node);
      if (node.filhas?.length) percorrer(node.filhas);
    }
  }
  percorrer(arvore);
  return resultado;
}
