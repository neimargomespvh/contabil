import { useQuery } from '@tanstack/react-query';
import { planoContasService } from '@/services/plano-contas.service';

export function usePlanoAtivo(empresaId: string | null) {
  return useQuery({
    queryKey: ['planos', empresaId],
    queryFn: async () => {
      const planos = await planoContasService.listarPlanos(empresaId!);
      return planos.find((p) => p.status === 'ATIVO') ?? planos[0] ?? null;
    },
    enabled: !!empresaId,
  });
}

export function useContasDoPlano(planoId: string | null) {
  return useQuery({
    queryKey: ['contas', planoId],
    queryFn: () => planoContasService.listarContas(planoId!),
    enabled: !!planoId,
  });
}

/**
 * Retorna a lista achatada de contas analíticas (que aceitam lançamento).
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
