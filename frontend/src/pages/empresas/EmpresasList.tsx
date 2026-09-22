import { useState } from 'react';
import { Plus, Search, Filter } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Pagination } from '@/components/ui/Pagination';
import { EmpresasTable } from '@/components/empresas/EmpresasTable';
import { EmpresaModal } from '@/components/empresas/EmpresaModal';
import { useEmpresas, useRemoverEmpresa } from '@/hooks/useEmpresas';
import { useDebounce } from '@/hooks/useDebounce';
import type { Empresa, RegimeTributario, EmpresaStatus } from '@/types';

export function EmpresasListPage() {
  const [page, setPage] = useState(1);
  const [busca, setBusca] = useState('');
  const [regime, setRegime] = useState<RegimeTributario | ''>('');
  const [status, setStatus] = useState<EmpresaStatus | ''>('ATIVA');
  const [modalOpen, setModalOpen] = useState(false);
  const [editando, setEditando] = useState<Empresa | null>(null);
  const [removendo, setRemovendo] = useState<Empresa | null>(null);

  const buscaDebounced = useDebounce(busca, 400);

  const { data, isLoading } = useEmpresas({
    page,
    limit: 20,
    busca: buscaDebounced || undefined,
    regimeTributario: regime || undefined,
    status: status || undefined,
  });

  const remover = useRemoverEmpresa();

  const handleNovo = () => {
    setEditando(null);
    setModalOpen(true);
  };

  const handleEditar = (emp: Empresa) => {
    setEditando(emp);
    setModalOpen(true);
  };

  const handleRemover = () => {
    if (!removendo) return;
    remover.mutate(removendo.id, {
      onSuccess: () => setRemovendo(null),
    });
  };

  return (
    <div className="space-y-6">
      {/* Header */}
      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-center">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Empresas</h1>
          <p className="mt-1 text-sm text-gray-500">
            Gerencie os clientes do seu escritório
          </p>
        </div>
        <Button onClick={handleNovo}>
          <Plus className="h-4 w-4" />
          Nova Empresa
        </Button>
      </div>

      {/* Filtros */}
      <div className="rounded-lg border border-gray-200 bg-white p-4">
        <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-4">
          <div className="lg:col-span-2">
            <div className="relative">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <Input
                placeholder="Buscar por razão social, fantasia ou CNPJ..."
                value={busca}
                onChange={(e) => { setBusca(e.target.value); setPage(1); }}
                className="pl-9"
              />
            </div>
          </div>

          <select
            className="input-base"
            value={regime}
            onChange={(e) => { setRegime(e.target.value as any); setPage(1); }}
          >
            <option value="">Todos os regimes</option>
            <option value="SIMPLES">Simples Nacional</option>
            <option value="PRESUMIDO">Lucro Presumido</option>
            <option value="REAL">Lucro Real</option>
            <option value="MEI">MEI</option>
          </select>

          <select
            className="input-base"
            value={status}
            onChange={(e) => { setStatus(e.target.value as any); setPage(1); }}
          >
            <option value="">Todos os status</option>
            <option value="ATIVA">Ativas</option>
            <option value="INATIVA">Inativas</option>
            <option value="BAIXADA">Baixadas</option>
          </select>
        </div>
      </div>

      {/* Tabela */}
      <EmpresasTable
        empresas={data?.data ?? []}
        loading={isLoading}
        onEditar={handleEditar}
        onRemover={setRemovendo}
      />

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

      {/* Modal */}
      <EmpresaModal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setEditando(null); }}
        empresa={editando}
      />

      {/* Confirm delete */}
      <ConfirmDialog
        isOpen={!!removendo}
        onClose={() => setRemovendo(null)}
        onConfirm={handleRemover}
        title="Remover empresa"
        message={`Tem certeza que deseja remover "${removendo?.razaoSocial}"? Esta ação marcará a empresa como baixada.`}
        confirmText="Remover"
        loading={remover.isPending}
      />
    </div>
  );
}
