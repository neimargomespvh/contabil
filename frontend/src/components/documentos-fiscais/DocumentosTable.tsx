import { Eye, Ban } from 'lucide-react';
import {
  DocumentoStatusBadge,
  DocumentoTipoBadge,
} from './DocumentoStatusBadge';
import type { DocumentoFiscal } from '@/services/documentos-fiscais.service';

interface Props {
  documentos: DocumentoFiscal[];
  onVer: (doc: DocumentoFiscal) => void;
  onCancelar: (doc: DocumentoFiscal) => void;
}

const formatMoney = (v: number | null | undefined) =>
  v == null
    ? '—'
    : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v));

const formatDate = (iso: string) =>
  new Date(iso).toLocaleDateString('pt-BR');

const formatCnpj = (c: string) =>
  c.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');

export function DocumentosTable({ documentos, onVer, onCancelar }: Props) {
  if (documentos.length === 0) {
    return (
      <div className="py-12 text-center text-sm text-gray-500">
        Nenhum documento fiscal importado.
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead className="border-b border-gray-200 text-left text-xs uppercase tracking-wide text-gray-500">
          <tr>
            <th className="px-3 py-2">Tipo</th>
            <th className="px-3 py-2">Número / Série</th>
            <th className="px-3 py-2">Emitente</th>
            <th className="px-3 py-2">Emissão</th>
            <th className="px-3 py-2 text-right">Valor</th>
            <th className="px-3 py-2">CFOP</th>
            <th className="px-3 py-2">Situação</th>
            <th className="px-3 py-2 text-right">Ações</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {documentos.map((doc) => (
            <tr key={doc.id} className="hover:bg-gray-50">
              <td className="px-3 py-2">
                <DocumentoTipoBadge tipo={doc.tipo} />
              </td>
              <td className="px-3 py-2">
                <span className="font-medium text-gray-900">{doc.numero}</span>
                <span className="ml-1 text-xs text-gray-500">/ {doc.serie}</span>
              </td>
              <td className="px-3 py-2">
                <div className="flex flex-col">
                  <span className="truncate text-gray-800" title={doc.emitenteNome}>
                    {doc.emitenteNome}
                  </span>
                  <span className="font-mono text-[10px] text-gray-500">
                    {formatCnpj(doc.emitenteCnpj)}
                  </span>
                </div>
              </td>
              <td className="px-3 py-2 text-gray-700">{formatDate(doc.dataEmissao)}</td>
              <td className="px-3 py-2 text-right font-medium text-gray-900">
                {formatMoney(doc.valorTotal)}
              </td>
              <td className="px-3 py-2 font-mono text-xs text-gray-600">
                {doc.cfopPrincipal ?? '—'}
              </td>
              <td className="px-3 py-2">
                <DocumentoStatusBadge situacao={doc.situacao} />
              </td>
              <td className="px-3 py-2">
                <div className="flex justify-end gap-1">
                  <button
                    type="button"
                    onClick={() => onVer(doc)}
                    className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-blue-600"
                    title="Ver detalhes"
                  >
                    <Eye className="h-4 w-4" />
                  </button>
                  {doc.situacao === 'AUTORIZADA' && (
                    <button
                      type="button"
                      onClick={() => onCancelar(doc)}
                      className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-red-600"
                      title="Cancelar documento"
                    >
                      <Ban className="h-4 w-4" />
                    </button>
                  )}
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
