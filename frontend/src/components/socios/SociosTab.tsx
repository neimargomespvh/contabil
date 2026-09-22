import { useState } from 'react';
import { Plus, Pencil, Trash2, Users } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Badge } from '@/components/ui/Badge';
import { Spinner } from '@/components/ui/Spinner';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { SocioModal } from './SocioModal';
import { useSocios, useRemoverSocio } from '@/hooks/useSocios';
import { formatCpf, formatCurrency } from '@/lib/format';
import type { Socio } from '@/types';

interface SociosTabProps {
  empresaId: string;
}

export function SociosTab({ empresaId }: SociosTabProps) {
  const { data, isLoading } = useSocios(empresaId);
  const remover = useRemoverSocio(empresaId);

  const [modalOpen, setModalOpen] = useState(false);
  const [editando, setEditando] = useState<Socio | null>(null);
  const [removendo, setRemovendo] = useState<Socio | null>(null);

  const socios = data?.data ?? [];
  const resumo = data?.resumo;

  const participacaoDisponivel =
    100 - Number(resumo?.participacaoTotal ?? 0) + (editando ? Number(editando.participacao) : 0);

  const handleNovo = () => {
    setEditando(null);
    setModalOpen(true);
  };

  const handleEditar = (s: Socio) => {
    setEditando(s);
    setModalOpen(true);
  };

  const handleRemover = () => {
    if (!removendo) return;
    remover.mutate(removendo.id, {
      onSuccess: () => setRemovendo(null),
    });
  };

  if (isLoading) {
    return (
      <div className="flex justify-center py-12">
        <Spinner size="lg" />
      </div>
    );
  }

  return (
    <div className="space-y-4">
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h3 className="text-lg font-semibold text-gray-900">Quadro Societário</h3>
          {resumo && (
            <p className="mt-1 text-sm text-gray-500">
              {resumo.total} sócio(s) —{' '}
              <span className={resumo.participacaoCompleta ? 'text-emerald-600' : 'text-amber-600'}>
                {resumo.participacaoTotal.toFixed(2)}% do capital
              </span>
            </p>
          )}
        </div>
        <Button
          onClick={handleNovo}
          disabled={participacaoDisponivel <= 0 && !editando}
          title={
            participacaoDisponivel <= 0 ? 'Soma das participações já é 100%' : undefined
          }
        >
          <Plus className="h-4 w-4" />
          Novo Sócio
        </Button>
      </div>

      {socios.length === 0 ? (
        <div className="flex flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-white py-12">
          <Users className="h-10 w-10 text-gray-400" />
          <p className="mt-3 text-sm font-medium text-gray-900">Nenhum sócio cadastrado</p>
          <p className="mt-1 text-xs text-gray-500">
            Adicione os sócios desta empresa
          </p>
        </div>
      ) : (
        <div className="overflow-hidden rounded-lg border border-gray-200 bg-white">
          <table className="w-full">
            <thead className="bg-gray-50">
              <tr>
                <th className="px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600">
                  Nome
                </th>
                <th className="hidden px-4 py-3 text-left text-xs font-semibold uppercase tracking-wider text-gray-600 sm:table-cell">
                  CPF
                </th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
                  Participação
                </th>
                <th className="hidden px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600 lg:table-cell">
                  Pró-labore
                </th>
                <th className="px-4 py-3 text-right text-xs font-semibold uppercase tracking-wider text-gray-600">
                  Ações
                </th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-200">
              {socios.map((s) => (
                <tr key={s.id} className="hover:bg-gray-50">
                  <td className="px-4 py-3">
                    <p className="font-medium text-gray-900">{s.nome}</p>
                  </td>
                  <td className="hidden px-4 py-3 text-sm text-gray-600 sm:table-cell">
                    {formatCpf(s.cpf)}
                  </td>
                  <td className="px-4 py-3 text-right">
                    <Badge variant={Number(s.participacao) >= 50 ? 'info' : 'default'}>
                      {Number(s.participacao).toFixed(4)}%
                    </Badge>
                  </td>
                  <td className="hidden px-4 py-3 text-right text-sm text-gray-600 lg:table-cell">
                    {s.proLabore ? formatCurrency(Number(s.proLabore)) : '—'}
                  </td>
                  <td className="px-4 py-3">
                    <div className="flex items-center justify-end gap-1">
                      <Button
                        variant="ghost"
                        size="sm"
                        onClick={() => handleEditar(s)}
                        title="Editar"
                      >
                        <Pencil className="h-4 w-4" />
                      </Button>
                      <Button
                        variant="ghost"
                        size="sm"
                        className="text-red-600 hover:bg-red-50"
                        onClick={() => setRemovendo(s)}
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
      )}

      <SocioModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditando(null); }}
        empresaId={empresaId}
        socio={editando}
        participacaoDisponivel={Math.max(0, participacaoDisponivel)}
      />

      <ConfirmDialog
        isOpen={!!removendo}
        onClose={() => setRemovendo(null)}
        onConfirm={handleRemover}
        title="Remover sócio"
        message={`Tem certeza que deseja remover "${removendo?.nome}" do quadro societário?`}
        confirmText="Remover"
        loading={remover.isPending}
      />
    </div>
  );
}
