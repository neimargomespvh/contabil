import { Eye, Pencil, Trash2, Building2 } from 'lucide-react';
import { Link } from 'react-router-dom';
import { Badge } from '@/components/ui/Badge';
import { Button } from '@/components/ui/Button';
import { Spinner } from '@/components/ui/Spinner';
import { formatCnpj } from '@/lib/format';
import type { Empresa } from '@/types';

interface EmpresasTableProps {
  empresas: Empresa[];
  loading: boolean;
  onEditar: (e: Empresa) => void;
  onRemover: (e: Empresa) => void;
}

const REGIME_LABEL: Record<string, string> = {
  SIMPLES: 'Simples Nacional',
  PRESUMIDO: 'Lucro Presumido',
  REAL: 'Lucro Real',
  MEI: 'MEI',
};

export function EmpresasTable({ empresas, loading, onEditar, onRemover }: EmpresasTableProps) {
  if (loading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner size="lg" />
      </div>
    );
  }

  if (empresas.length === 0) {
    return (
      <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-white py-16">
        <Building2 className="h-12 w-12 text-gray-400" />
        <h3 className="mt-4 text-lg font-semibold text-gray-900">Nenhuma empresa cadastrada</h3>
        <p className="mt-1 text-sm text-gray-500">
          Comece cadastrando sua primeira empresa cliente
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
              Empresa
            </th>
            <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 md:table-cell">
              CNPJ
            </th>
            <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
              Regime
            </th>
            <th className="hidden px-4 py-3 text-center text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
              Sócios
            </th>
            <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
              Status
            </th>
            <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
              Ações
            </th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-200">
          {empresas.map((emp) => (
            <tr key={emp.id} className="hover:bg-gray-50">
              <td className="px-4 py-3">
                <div>
                  <p className="font-medium text-gray-900">{emp.razaoSocial}</p>
                  {emp.nomeFantasia && (
                    <p className="text-xs text-gray-500">{emp.nomeFantasia}</p>
                  )}
                </div>
              </td>
              <td className="hidden px-4 py-3 text-sm text-gray-600 md:table-cell">
                {formatCnpj(emp.cnpj)}
              </td>
              <td className="hidden px-4 py-3 text-sm text-gray-600 lg:table-cell">
                {REGIME_LABEL[emp.regimeTributario] ?? emp.regimeTributario}
                {emp.anexoSimples && (
                  <span className="ml-1 text-xs text-gray-400">(Anexo {emp.anexoSimples})</span>
                )}
              </td>
              <td className="hidden px-4 py-3 text-center text-sm text-gray-600 lg:table-cell">
                {emp._count?.socios ?? 0}
              </td>
              <td className="px-4 py-3">
                <Badge variant={emp.status === 'ATIVA' ? 'success' : 'default'}>
                  {emp.status}
                </Badge>
              </td>
              <td className="px-4 py-3">
                <div className="flex items-center justify-end gap-1">
                  <Link to={`/empresas/${emp.id}`}>
                    <Button variant="ghost" size="sm" title="Ver detalhes">
                      <Eye className="h-4 w-4" />
                    </Button>
                  </Link>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onEditar(emp)}
                    title="Editar"
                  >
                    <Pencil className="h-4 w-4" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="sm"
                    onClick={() => onRemover(emp)}
                    className="text-red-600 hover:bg-red-50"
                    title="Remover"
                  >
                    <Trash2 className="h-4 w-4" />
                  </Button>
                </div>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}
