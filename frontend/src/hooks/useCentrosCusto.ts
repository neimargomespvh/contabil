import { useQuery } from '@tanstack/react-query';
import { centrosCustoService } from '@/services/centros-custo.service';

export function useCentrosCusto(empresaId: string | null) {
  return useQuery({
    queryKey: ['centros-custo', empresaId],
    queryFn: () => centrosCustoService.listarPorEmpresa(empresaId!),
    enabled: !!empresaId,
  });
}
