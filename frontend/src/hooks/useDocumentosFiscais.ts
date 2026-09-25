import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import {
  documentosFiscaisService,
  FilterDocumentos,
} from '@/services/documentos-fiscais.service';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY = 'documentos-fiscais';

export function useDocumentosFiscais(filtros: FilterDocumentos) {
  return useQuery({
    queryKey: [KEY, filtros],
    queryFn: () => documentosFiscaisService.listar(filtros),
    enabled: !!filtros.empresaId,
    placeholderData: (prev) => prev,
  });
}

export function useDocumentoFiscal(id: string | null) {
  return useQuery({
    queryKey: [KEY, id],
    queryFn: () => documentosFiscaisService.buscarPorId(id!),
    enabled: !!id,
  });
}

export function useEstatisticasDocumentos(empresaId: string | null) {
  return useQuery({
    queryKey: [KEY, 'estatisticas', empresaId],
    queryFn: () => documentosFiscaisService.estatisticas(empresaId!),
    enabled: !!empresaId,
  });
}

export function useUploadXml(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (file: File) => documentosFiscaisService.upload(empresaId, file),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      qc.invalidateQueries({ queryKey: [KEY, 'estatisticas'] });
      toast.success('XML importado com sucesso');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useUploadLote(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (files: File[]) => documentosFiscaisService.uploadLote(empresaId, files),
    onSuccess: (result) => {
      qc.invalidateQueries({ queryKey: [KEY] });
      qc.invalidateQueries({ queryKey: [KEY, 'estatisticas'] });

      if (result.total !== undefined && result.sucesso !== undefined) {
        const falhas = result.falhas?.length ?? 0;
        if (falhas > 0) {
          toast.info(
            `${result.sucesso} de ${result.total} importados. ${falhas} falharam.`,
          );
        } else {
          toast.success(`${result.sucesso} arquivos importados`);
        }
      } else {
        toast.success('Lote importado');
      }
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useCancelarDocumento(empresaId: string) {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, motivo }: { id: string; motivo: string }) =>
      documentosFiscaisService.cancelar(id, motivo),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Documento cancelado');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}
