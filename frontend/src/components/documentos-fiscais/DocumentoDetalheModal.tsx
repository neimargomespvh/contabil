import { Download, FileText } from 'lucide-react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import {
  DocumentoStatusBadge,
  DocumentoTipoBadge,
} from './DocumentoStatusBadge';
import { documentosFiscaisService } from '@/services/documentos-fiscais.service';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';
import type { DocumentoFiscal } from '@/services/documentos-fiscais.service';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  documento: DocumentoFiscal | null;
}

const money = (v: number | null | undefined) =>
  v == null
    ? '—'
    : new Intl.NumberFormat('pt-BR', { style: 'currency', currency: 'BRL' }).format(Number(v));

const dt = (iso: string) => new Date(iso).toLocaleString('pt-BR');

export function DocumentoDetalheModal({ isOpen, onClose, documento }: Props) {
  if (!documento) return null;

  const baixarXml = async () => {
    try {
      const { url } = await documentosFiscaisService.obterUrlXml(documento.id);
      window.open(url, '_blank');
    } catch (err) {
      toast.error(getApiError(err));
    }
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Detalhes do documento" size="xl">
      <div className="space-y-6">
        {/* Cabeçalho */}
        <div className="flex items-start justify-between gap-4 rounded-lg bg-gray-50 p-4">
          <div className="space-y-1">
            <div className="flex items-center gap-2">
              <DocumentoTipoBadge tipo={documento.tipo} />
              <span className="font-mono text-xs text-gray-500">
                {documento.chaveAcesso}
              </span>
            </div>
            <h3 className="text-lg font-semibold text-gray-900">
              Nº {documento.numero} / série {documento.serie}
            </h3>
            <div className="flex items-center gap-2">
              <DocumentoStatusBadge situacao={documento.situacao} />
              {documento.lancamentoId && (
                <span className="rounded bg-green-100 px-2 py-0.5 text-[10px] font-medium text-green-700">
                  ✓ Contabilizado
                </span>
              )}
            </div>
          </div>

          <Button variant="outline" size="sm" onClick={baixarXml}>
            <Download className="h-4 w-4" />
            Baixar XML
          </Button>
        </div>

        {/* Emitente / Destinatário */}
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2">
          <div className="rounded-lg border border-gray-200 p-4">
            <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
              Emitente
            </h4>
            <p className="text-sm font-medium text-gray-900">{documento.emitenteNome}</p>
            <p className="mt-0.5 font-mono text-xs text-gray-500">{documento.emitenteCnpj}</p>
          </div>

          <div className="rounded-lg border border-gray-200 p-4">
            <h4 className="mb-2 text-xs font-semibold uppercase tracking-wide text-gray-500">
              Destinatário
            </h4>
            <p className="text-sm font-medium text-gray-900">
              {documento.destinatarioNome ?? '—'}
            </p>
            <p className="mt-0.5 font-mono text-xs text-gray-500">
              {documento.destinatarioCnpj ?? '—'}
            </p>
          </div>
        </div>

        {/* Valores */}
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div className="rounded-lg bg-gray-50 p-3">
            <p className="text-[10px] uppercase tracking-wide text-gray-500">Emissão</p>
            <p className="mt-1 text-sm font-medium text-gray-900">
              {dt(documento.dataEmissao)}
            </p>
          </div>
          <div className="rounded-lg bg-gray-50 p-3">
            <p className="text-[10px] uppercase tracking-wide text-gray-500">Valor Total</p>
            <p className="mt-1 text-sm font-medium text-gray-900">{money(documento.valorTotal)}</p>
          </div>
          <div className="rounded-lg bg-gray-50 p-3">
            <p className="text-[10px] uppercase tracking-wide text-gray-500">ICMS</p>
            <p className="mt-1 text-sm text-gray-800">{money(documento.valorIcms)}</p>
          </div>
          <div className="rounded-lg bg-gray-50 p-3">
            <p className="text-[10px] uppercase tracking-wide text-gray-500">CFOP Principal</p>
            <p className="mt-1 font-mono text-sm text-gray-800">
              {documento.cfopPrincipal ?? '—'}
            </p>
          </div>
        </div>

        {/* Itens */}
        {documento.itens && documento.itens.length > 0 && (
          <div>
            <h4 className="mb-2 flex items-center gap-2 text-sm font-semibold text-gray-700">
              <FileText className="h-4 w-4" />
              Itens ({documento.itens.length})
            </h4>
            <div className="max-h-72 overflow-auto rounded-lg border border-gray-200">
              <table className="w-full text-xs">
                <thead className="sticky top-0 border-b border-gray-200 bg-gray-50 text-left uppercase tracking-wide text-gray-500">
                  <tr>
                    <th className="px-2 py-1.5">#</th>
                    <th className="px-2 py-1.5">Produto</th>
                    <th className="px-2 py-1.5">NCM</th>
                    <th className="px-2 py-1.5">CFOP</th>
                    <th className="px-2 py-1.5 text-right">Qtd</th>
                    <th className="px-2 py-1.5 text-right">V. Unit.</th>
                    <th className="px-2 py-1.5 text-right">Total</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-gray-100">
                  {documento.itens.map((item) => (
                    <tr key={item.id} className="hover:bg-gray-50">
                      <td className="px-2 py-1.5 text-gray-500">{item.numeroItem}</td>
                      <td className="px-2 py-1.5 text-gray-800">{item.descricao ?? '—'}</td>
                      <td className="px-2 py-1.5 font-mono text-gray-600">{item.ncm ?? '—'}</td>
                      <td className="px-2 py-1.5 font-mono text-gray-600">{item.cfop ?? '—'}</td>
                      <td className="px-2 py-1.5 text-right text-gray-700">{item.quantidade ?? '—'}</td>
                      <td className="px-2 py-1.5 text-right text-gray-700">{money(item.valorUnitario)}</td>
                      <td className="px-2 py-1.5 text-right font-medium text-gray-900">
                        {money(item.valorTotal)}
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        )}

        <div className="flex justify-end border-t border-gray-200 pt-4">
          <Button variant="outline" onClick={onClose}>Fechar</Button>
        </div>
      </div>
    </Modal>
  );
}
