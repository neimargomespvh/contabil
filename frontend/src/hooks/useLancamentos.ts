import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { lancamentosService } from '@/services/lancamentos.service';
import type { CreateLancamentoPayload, FilterLancamentos } from '@/types';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY = 'lancamentos';

export function useLancamentos(filtros: FilterLancamentos) {
  return useQuery({
    queryKey: [KEY, filtros],
    queryFn: () => lancamentosService.listar(filtros),
    enabled: !!filtros.empresaId,
    placeholderData: (prev) => prev,
  });
}

export function useLancamento(id: string | null) {
  return useQuery({
    queryKey: [KEY, id],
    queryFn: () => lancamentosService.buscarPorId(id!),
    enabled: !!id,
  });
}

export function useCriarLancamento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateLancamentoPayload) => lancamentosService.criar(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Lançamento criado com sucesso');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useEstornarLancamento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, motivo }: { id: string; motivo: string }) =>
      lancamentosService.estornar(id, motivo),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Lançamento estornado');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}
