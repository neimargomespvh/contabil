import { Eye, RotateCcw, FileText } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Spinner } from '@/components/ui/Spinner';
import { formatCurrency, formatDate } from '@/lib/format';
import type { Lancamento } from '@/types';

interface LancamentosTableProps {
  lancamentos: Lancamento[];
  loading: boolean;
  onEstornar: (l: Lancamento) => void;
}

export function LancamentosTable({ lancamentos, loading, onEstornar }: LancamentosTableProps) {
  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner size="lg" />
      </div>
    );
  }

  if (lancamentos.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-white py-16">
        <FileText className="h-12 w-12 text-gray-400" />
        <h3 className="mt-4 text-lg font-semibold text-gray-900">
          Nenhum lançamento encontrado
        </h3>
        <p className="mt-1 text-sm text-gray-500">
          Selecione outra competência ou crie um novo lançamento
        </p>
      </div>
    );
  }

  return (
    <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
      <table className="w-full">
        <thead className="bg-gray-50">
          <tr>
            <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
              Nº
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
              Data
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
              Histórico
            </th>
            <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
              Documento
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
              Valor
            </th>
            <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 md:table-cell">
              Status
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
              Ações
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {lancamentos.map((l) => (
            <tr key={l.id} className="hover:bg-gray-50">
              <td className="px-4 py-3 font-mono text-sm text-gray-600">
                {String(l.numero).padStart(6, '0')}
              </td>
              <td className="px-4 py-3 text-sm text-gray-700">
                {formatDate(l.dataLancamento)}
              </td>
              <td className="px-4 py-3">
                <p className="max-w-xs truncate font-medium text-gray-900" title={l.historico}>
                  {l.historico}
                </p>
              </td>
              <td className="hidden px-4 py-3 text-sm text-gray-500 lg:table-cell">
                {l.documentoRef || '—'}
              </td>
              <td className="px-4 py-3 text-right font-mono text-sm font-medium text-gray-900">
                {formatCurrency(Number(l.valorTotal))}
              </td>
              <td className="hidden px-4 py-3 md:table-cell">
                <Badge variant={l.status === 'ATIVO' ? 'success' : 'danger'}>
                  {l.status}
                </Badge>
              </td>
              <td className="px-4 py-3">
                <div className="flex items-center justify-end gap-1">
                  <Link to={`/lancamentos/${l.id}`}>
                    <Button variant="ghost" size="sm" title="Ver detalhes">
                      <Eye className="h-4 w-4" />
                    </Button>
                  </Link>
                  {l.status === 'ATIVO' && (
                    <Button
                      variant="ghost"
                      size="sm"
                      className="text-rose-600 hover:bg-rose-50"
                      onClick={() => onEstornar(l)}
                      title="Estornar"
                    >
                      <RotateCcw className="h-4 w-4" />
                    </Button>
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
