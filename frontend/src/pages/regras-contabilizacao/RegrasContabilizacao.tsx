import { useState } from 'react';
import { Plus, Search, FlaskConical } from 'lucide-react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Spinner } from '@/components/ui/Spinner';
import { EmpresaSelect } from '@/components/common/EmpresaSelect';
import { RegrasTable } from '@/components/regras-contabilizacao/RegrasTable';
import { RegraModal } from '@/components/regras-contabilizacao/RegraModal';
import { SimuladorModal } from '@/components/regras-contabilizacao/SimuladorModal';
import {
  useRegras,
  useCriarRegra,
  useAtualizarRegra,
  useInativarRegra,
  useReativarRegra,
  useExcluirRegra,
} from '@/hooks/useRegrasContabilizacao';
import type {
  RegraContabilizacao,
  CreateRegraPayload,
  StatusRegra,
} from '@/services/regras-contabilizacao.service';

export function RegrasContabilizacaoPage() {
  const [empresaId, setEmpresaId] = useState<string | null>(null);
  const [busca, setBusca] = useState('');
  const [status, setStatus] = useState<StatusRegra | ''>('');
  const [page, setPage] = useState(1);
  const limit = 20;

  const [modalAberto, setModalAberto] = useState(false);
  const [simuladorAberto, setSimuladorAberto] = useState(false);
  const [regraEditando, setRegraEditando] = useState<RegraContabilizacao | null>(null);
  const [regraExcluindo, setRegraExcluindo] = useState<RegraContabilizacao | null>(null);

  const { data, isLoading } = useRegras({
    empresaId: empresaId ?? '',
    nome: busca || undefined,
    status: status || undefined,
    page,
    limit,
  });

  const criar = useCriarRegra(empresaId ?? '');
  const atualizar = useAtualizarRegra(empresaId ?? '');
  const inativar = useInativarRegra(empresaId ?? '');
  const reativar = useReativarRegra(empresaId ?? '');
  const excluir = useExcluirRegra(empresaId ?? '');

  const abrirNova = () => {
    setRegraEditando(null);
    setModalAberto(true);
  };

  const abrirEdicao = (r: RegraContabilizacao) => {
    setRegraEditando(r);
    setModalAberto(true);
  };

  const handleSubmit = (payload: CreateRegraPayload) => {
    if (regraEditando) {
      atualizar.mutate(
        { id: regraEditando.id, payload },
        { onSuccess: () => setModalAberto(false) },
      );
    } else {
      criar.mutate(payload, { onSuccess: () => setModalAberto(false) });
    }
  };

  const handleExcluir = () => {
    if (!regraExcluindo) return;
    excluir.mutate(regraExcluindo.id, {
      onSuccess: () => setRegraExcluindo(null),
    });
  };

  const totalPages = data?.meta?.totalPages ?? 0;
  const regras = data?.data ?? [];

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">
            Regras de Contabilização
          </h1>
          <p className="mt-1 text-sm text-gray-500">
            Defina como os XMLs serão contabilizados automaticamente
          </p>
        </div>
      </div>

      <Card>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="sm:col-span-2">
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Empresa
            </label>
            <EmpresaSelect
              value={empresaId ?? ''}
              onChange={(v) => { setEmpresaId(v || null); setPage(1); }}
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Status
            </label>
            <select
              className="input-base"
              value={status}
              onChange={(e) => { setStatus(e.target.value as any); setPage(1); }}
            >
              <option value="">Todos</option>
              <option value="ATIVO">Ativas</option>
              <option value="INATIVO">Inativas</option>
            </select>
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Buscar
            </label>
            <Input
              value={busca}
              onChange={(e) => { setBusca(e.target.value); setPage(1); }}
              placeholder="Nome da regra..."
            />
          </div>
        </div>
      </Card>

      {empresaId && (
        <>
          <div className="flex flex-wrap justify-end gap-2">
            <Button variant="outline" onClick={() => setSimuladorAberto(true)}>
              <FlaskConical className="h-4 w-4" />
              Simular XML
            </Button>
            <Button onClick={abrirNova}>
              <Plus className="h-4 w-4" />
              Nova regra
            </Button>
          </div>

          <Card>
            {isLoading ? (
              <div className="flex justify-center py-12">
                <Spinner />
              </div>
            ) : (
              <>
                <RegrasTable
                  regras={regras}
                  onEditar={abrirEdicao}
                  onExcluir={setRegraExcluindo}
                  onInativar={(r) => inativar.mutate(r.id)}
                  onReativar={(r) => reativar.mutate(r.id)}
                />

                {totalPages > 1 && (
                  <div className="mt-4 flex items-center justify-between border-t border-gray-100 pt-4">
                    <p className="text-xs text-gray-500">
                      Página {page} de {totalPages} — {data?.meta?.total} regras
                    </p>
                    <div className="flex gap-2">
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={page <= 1}
                        onClick={() => setPage((p) => p - 1)}
                      >
                        Anterior
                      </Button>
                      <Button
                        variant="outline"
                        size="sm"
                        disabled={page >= totalPages}
                        onClick={() => setPage((p) => p + 1)}
                      >
                        Próxima
                      </Button>
                    </div>
                  </div>
                )}
              </>
            )}
          </Card>
        </>
      )}

      {!empresaId && (
        <Card>
          <div className="py-12 text-center text-sm text-gray-500">
            Selecione uma empresa para visualizar as regras
          </div>
        </Card>
      )}

      {empresaId && (
        <RegraModal
          isOpen={modalAberto}
          onClose={() => setModalAberto(false)}
          empresaId={empresaId}
          regra={regraEditando}
          onSubmit={handleSubmit}
          loading={criar.isPending || atualizar.isPending}
        />
      )}

      {empresaId && (
        <SimuladorModal
          isOpen={simuladorAberto}
          onClose={() => setSimuladorAberto(false)}
          empresaId={empresaId}
        />
      )}

      <ConfirmDialog
        isOpen={!!regraExcluindo}
        onClose={() => setRegraExcluindo(null)}
        onConfirm={handleExcluir}
        title="Excluir regra"
        message={
          regraExcluindo
            ? `Tem certeza que deseja excluir "${regraExcluindo.nome}"? Esta ação é permanente.`
            : ''
        }
        confirmText="Excluir"
        loading={excluir.isPending}
      />
    </div>
  );
}
