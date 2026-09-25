import { api } from '@/lib/axios';
import type { PaginatedResponse } from '@/types';

export type TipoDocumento = 'NFE' | 'NFCE' | 'CTE' | 'NFSE';
export type SituacaoDocumento = 'AUTORIZADA' | 'CANCELADA' | 'DENEGADA' | 'INUTILIZADA';

export interface DocumentoFiscal {
  id: string;
  tenantId: string;
  empresaId: string;
  tipo: TipoDocumento;
  chaveAcesso: string;
  numero: string;
  serie: string;
  modelo: string;
  emitenteCnpj: string;
  emitenteNome: string;
  destinatarioCnpj: string | null;
  destinatarioNome: string | null;
  dataEmissao: string;
  valorTotal: number;
  valorIcms: number | null;
  valorPis: number | null;
  valorCofins: number | null;
  valorIss: number | null;
  cfopPrincipal: string | null;
  ncmPrincipal: string | null;
  situacao: SituacaoDocumento;
  xmlS3Key: string | null;
  xmlHash: string | null;
  lancamentoId: string | null;
  importadoEm: string;
  createdAt: string;
  updatedAt: string;
  itens?: ItemDocumentoFiscal[];
}

export interface ItemDocumentoFiscal {
  id: string;
  numeroItem: number;
  codigoProduto: string | null;
  descricao: string | null;
  ncm: string | null;
  cfop: string | null;
  quantidade: number | null;
  valorUnitario: number | null;
  valorTotal: number | null;
  valorIcms: number | null;
  aliquotaIcms: number | null;
  valorPis: number | null;
  valorCofins: number | null;
}

export interface FilterDocumentos {
  empresaId: string;
  tipo?: TipoDocumento;
  situacao?: SituacaoDocumento;
  chaveAcesso?: string;
  emitenteCnpj?: string;
  dataInicio?: string;
  dataFim?: string;
  semContabilizacao?: 'true' | 'false';
  page?: number;
  limit?: number;
}

export interface ImportarResultado {
  total?: number;
  sucesso?: number;
  falhas?: Array<{ erro: string; motivo: string }>;
  [key: string]: any;
}

export const documentosFiscaisService = {
  async listar(filtros: FilterDocumentos): Promise<PaginatedResponse<DocumentoFiscal>> {
    const { data } = await api.get<PaginatedResponse<DocumentoFiscal>>(
      '/documentos-fiscais',
      {
        params: {
          empresaId: filtros.empresaId,
          tipo: filtros.tipo,
          situacao: filtros.situacao,
          chaveAcesso: filtros.chaveAcesso || undefined,
          emitenteCnpj: filtros.emitenteCnpj || undefined,
          dataInicio: filtros.dataInicio || undefined,
          dataFim: filtros.dataFim || undefined,
          semContabilizacao: filtros.semContabilizacao,
          page: filtros.page ?? 1,
          limit: filtros.limit ?? 20,
        },
      },
    );
    return data;
  },

  async buscarPorId(id: string): Promise<DocumentoFiscal> {
    const { data } = await api.get<DocumentoFiscal>(`/documentos-fiscais/${id}`);
    return data;
  },

  async upload(empresaId: string, file: File): Promise<DocumentoFiscal> {
    const form = new FormData();
    form.append('empresaId', empresaId);
    form.append('file', file);
    const { data } = await api.post<DocumentoFiscal>(
      '/documentos-fiscais/upload',
      form,
      { headers: { 'Content-Type': 'multipart/form-data' } },
    );
    return data;
  },

  async uploadLote(empresaId: string, files: File[]): Promise<ImportarResultado> {
    const form = new FormData();
    form.append('empresaId', empresaId);
    files.forEach((f) => form.append('files', f));
    const { data } = await api.post<ImportarResultado>(
      '/documentos-fiscais/upload-lote',
      form,
      { headers: { 'Content-Type': 'multipart/form-data' } },
    );
    return data;
  },

  async importarXml(empresaId: string, xml: string): Promise<DocumentoFiscal> {
    const { data } = await api.post<DocumentoFiscal>(
      '/documentos-fiscais/importar',
      { empresaId, xml },
    );
    return data;
  },

  async cancelar(id: string, motivo: string): Promise<DocumentoFiscal> {
    const { data } = await api.post<DocumentoFiscal>(
      `/documentos-fiscais/${id}/cancelar`,
      { motivo },
    );
    return data;
  },

  async obterUrlXml(id: string): Promise<{ url: string }> {
    const { data } = await api.get<{ url: string }>(
      `/documentos-fiscais/${id}/xml`,
    );
    return data;
  },

  async estatisticas(empresaId?: string): Promise<any> {
    const { data } = await api.get<any>('/documentos-fiscais/estatisticas', {
      params: empresaId ? { empresaId } : {},
    });
    return data;
  },
};
