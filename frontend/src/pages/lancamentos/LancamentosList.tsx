import { useState } from 'react';
import { Plus } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Label } from '@/components/ui/Label';
import { Pagination } from '@/components/ui/Pagination';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Modal } from '@/components/ui/Modal';
import { Input } from '@/components/ui/Input';
import { EmpresaSelect } from '@/components/common/EmpresaSelect';
import { CompetenciaNav } from '@/components/common/CompetenciaNav';
import { LancamentosTable } from '@/components/lancamentos/LancamentosTable';
import { LancamentoModal } from '@/components/lancamentos/LancamentoModal';
import { useLancamentos, useEstornarLancamento } from '@/hooks/useLancamentos';
import { useEmpresas } from '@/hooks/useEmpresas';
import type { Lancamento } from '@/types';

export function LancamentosListPage() {
  const hoje = new Date();
  const competenciaPadrao = `${hoje.getFullYear()}-${String(hoje.getMonth() + 1).padStart(2, '0')}-01`;

  const [empresaId, setEmpresaId] = useState('');
  const [competencia, setCompetencia] = useState(competenciaPadrao);
  const [page, setPage] = useState(1);
  const [modalOpen, setModalOpen] = useState(false);
  const [estornando, setEstornando] = useState<Lancamento | null>(null);
  const [motivo, setMotivo] = useState('');

  const { data, isLoading } = useLancamentos({
    empresaId: empresaId || undefined,
    competencia,
    page,
    limit: 30,
  });

  const { data: empresasData } = useEmpresas({ limit: 1 });
  const temEmpresas = (empresasData?.meta.total ?? 0) > 0;

  const estornar = useEstornarLancamento();

  const handleEstornar = () => {
    if (!estornando || motivo.trim().length < 5) return;
    estornar.mutate(
      { id: estornando.id, motivo: motivo.trim() },
      {
        onSuccess: () => {
          setEstornando(null);
          setMotivo('');
        },
      },
    );
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Lançamentos Contábeis</h1>
          <p className="mt-1 text-sm text-gray-500">
            Registre e consulte as partidas dobradas por competência
          </p>
        </div>
        <Button
          onClick={() => setModalOpen(true)}
          
        >
          <Plus className="h-4 w-4" />
          Novo Lançamento
        </Button>
      </div>

      {!temEmpresas && (
        <div className="rounded-lg border border-amber-200 bg-amber-50 p-4">
          <p className="text-sm text-amber-800">
            Você precisa ter pelo menos uma empresa cadastrada para lançar.
          </p>
        </div>
      )}

      {/* Filtros */}
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
          <div>
            <Label>Empresa</Label>
            <EmpresaSelect
              value={empresaId}
              onChange={(id) => { setEmpresaId(id); setPage(1); }}
            />
          </div>

          <div>
            <Label>Competência</Label>
            <CompetenciaNav
              competencia={competencia}
              onChange={(c) => { setCompetencia(c); setPage(1); }}
            />
          </div>

          <div className="flex items-end">
            <div className="w-full rounded-md border border-gray-200 bg-gray-50 px-3 py-2">
              <p className="text-xs text-gray-500">Total no período</p>
              <p className="text-sm font-semibold text-gray-900">
                {data?.meta.total ?? 0} lançamento(s)
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Tabela */}
      {!empresaId ? (
        <div className="rounded-lg border-2 border-dashed border-gray-300 bg-white p-12 text-center">
          <p className="font-medium text-gray-900">Selecione uma empresa</p>
          <p className="mt-1 text-sm text-gray-500">
            Escolha uma empresa acima para ver os lançamentos
          </p>
        </div>
      ) : (
        <LancamentosTable
          lancamentos={data?.data ?? []}
          loading={isLoading}
          onEstornar={setEstornando}
        />
      )}

      {/* Paginação */}
      {data && data.meta.totalPages > 1 && (
        <Pagination
          page={data.meta.page}
          totalPages={data.meta.totalPages}
          total={data.meta.total}
          limit={data.meta.limit}
          onChange={setPage}
        />
      )}

      {/* Modal de criação */}
      <LancamentoModal
        isOpen={modalOpen}
        onClose={() => setModalOpen(false)}
        empresaIdInicial={empresaId}
      />

      {/* Modal de estorno */}
      <Modal
        isOpen={!!estornando}
        onClose={() => { setEstornando(null); setMotivo(''); }}
        title="Estornar lançamento"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-sm text-gray-600">
            O lançamento <strong>nº {String(estornando?.numero ?? 0).padStart(6, '0')}</strong> será
            estornado com uma partida inversa. O original ficará marcado como{' '}
            <strong>ESTORNADO</strong>.
          </p>

          <div>
            <Label>Motivo do estorno *</Label>
            <Input
              value={motivo}
              onChange={(e) => setMotivo(e.target.value)}
              placeholder="Mínimo 5 caracteres"
              autoFocus
            />
          </div>

          <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
            <Button
              variant="outline"
              onClick={() => { setEstornando(null); setMotivo(''); }}
              disabled={estornar.isPending}
            >
              Cancelar
            </Button>
            <Button
              variant="danger"
              onClick={handleEstornar}
              loading={estornar.isPending}
              disabled={motivo.trim().length < 5}
            >
              Estornar
            </Button>
          </div>
        </div>
      </Modal>
    </div>
  );
}
