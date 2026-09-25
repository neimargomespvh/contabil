import { useState, useMemo } from 'react';
import { Plus, Search } from 'lucide-react';
import { Card } from '@/components/ui/Card';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Spinner } from '@/components/ui/Spinner';
import { EmpresaSelect } from '@/components/common/EmpresaSelect';
import { ContaTree } from '@/components/plano-contas/ContaTree';
import { ContaModal } from '@/components/plano-contas/ContaModal';
import {
  usePlanoAtivo,
  useContasDoPlano,
  useCriarConta,
  useAtualizarConta,
  useExcluirConta,
  useCriarPlanoPadrao,
} from '@/hooks/usePlanoContas';
import type { ContaArvore } from '@/types';
import type { CreateContaPayload } from '@/services/plano-contas.service';

export function PlanoContasPage() {
  const [empresaId, setEmpresaId] = useState<string | null>(null);
  const [busca, setBusca] = useState('');
  const [modalAberto, setModalAberto] = useState(false);
  const [contaEditando, setContaEditando] = useState<ContaArvore | null>(null);
  const [contaPai, setContaPai] = useState<ContaArvore | null>(null);
  const [contaExcluindo, setContaExcluindo] = useState<ContaArvore | null>(null);

  const { data: plano, isLoading: carregandoPlano } = usePlanoAtivo(empresaId);
  const { data: contas, isLoading: carregandoContas } = useContasDoPlano(plano?.id ?? null);
  const criar = useCriarConta(plano?.id ?? '');
  const atualizar = useAtualizarConta(plano?.id ?? '');
  const excluir = useExcluirConta(plano?.id ?? '');
  const criarPadrao = useCriarPlanoPadrao(empresaId ?? '');

  const contasFiltradas = useMemo(() => {
    if (!contas || !busca.trim()) return contas ?? [];
    const termo = busca.toLowerCase();
    function filtrar(nodes: ContaArvore[]): ContaArvore[] {
      return nodes
        .map((n) => {
          const filhas = n.filhas ? filtrar(n.filhas) : [];
          const match =
            n.codigo.toLowerCase().includes(termo) ||
            n.nome.toLowerCase().includes(termo);
          if (match || filhas.length > 0) {
            return { ...n, filhas };
          }
          return null;
        })
        .filter(Boolean) as ContaArvore[];
    }
    return filtrar(contas);
  }, [contas, busca]);

  const abrirNovaConta = () => {
    setContaEditando(null);
    setContaPai(null);
    setModalAberto(true);
  };

  const abrirSubconta = (pai: ContaArvore) => {
    setContaEditando(null);
    setContaPai(pai);
    setModalAberto(true);
  };

  const abrirEdicao = (conta: ContaArvore) => {
    setContaEditando(conta);
    setContaPai(null);
    setModalAberto(true);
  };

  const handleSubmit = (payload: CreateContaPayload) => {
    if (contaEditando) {
      atualizar.mutate(
        { id: contaEditando.id, payload },
        { onSuccess: () => setModalAberto(false) },
      );
    } else {
      criar.mutate(payload, { onSuccess: () => setModalAberto(false) });
    }
  };

  const handleExcluir = () => {
    if (!contaExcluindo) return;
    excluir.mutate(contaExcluindo.id, {
      onSuccess: () => setContaExcluindo(null),
    });
  };

  const handleCriarPadrao = () => {
    if (!empresaId) return;
    criarPadrao.mutate('Plano Padrão RFB');
  };

  return (
    <div className="space-y-6">
      <div className="flex flex-col gap-4 sm:flex-row sm:items-center sm:justify-between">
        <div>
          <h1 className="text-2xl font-bold text-gray-900">Plano de Contas</h1>
          <p className="mt-1 text-sm text-gray-500">
            Gerencie a estrutura de contas da empresa
          </p>
        </div>
      </div>

      <Card>
        <div className="flex flex-col gap-4 sm:flex-row sm:items-end">
          <div className="flex-1">
            <label className="mb-1 block text-sm font-medium text-gray-700">
              Empresa
            </label>
            <EmpresaSelect
              value={empresaId ?? ''}
              onChange={(v) => setEmpresaId(v || null)}
            />
          </div>

          {empresaId && !carregandoPlano && !plano && (
            <Button onClick={handleCriarPadrao} loading={criarPadrao.isPending}>
              <Plus className="h-4 w-4" />
              Criar plano padrão
            </Button>
          )}

          {plano && (
            <Button onClick={abrirNovaConta} variant="outline">
              <Plus className="h-4 w-4" />
              Nova conta
            </Button>
          )}
        </div>
      </Card>

      {empresaId && plano && (
        <Card>
          <div className="mb-4 flex flex-col gap-3 sm:flex-row sm:items-center sm:justify-between">
            <div>
              <h2 className="text-sm font-semibold text-gray-700">
                {plano.nome} — v{plano.versao}
              </h2>
              <p className="text-xs text-gray-500">
                {contas?.length ?? 0} contas de primeiro nível
              </p>
            </div>

            <div className="flex gap-2">
              <div className="relative">
                <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <Input
                  value={busca}
                  onChange={(e) => setBusca(e.target.value)}
                  placeholder="Buscar conta..."
                  className="pl-9 sm:w-64"
                />
              </div>
            </div>
          </div>

          {carregandoContas ? (
            <div className="flex justify-center py-12">
              <Spinner />
            </div>
          ) : (
            <ContaTree
              contas={contasFiltradas}
              onEditar={abrirEdicao}
              onExcluir={setContaExcluindo}
              onAdicionarFilha={abrirSubconta}
            />
          )}
        </Card>
      )}

      {!empresaId && (
        <Card>
          <div className="py-12 text-center">
            <p className="text-sm text-gray-500">
              Selecione uma empresa para visualizar o plano de contas
            </p>
          </div>
        </Card>
      )}

      <ContaModal
        open={modalAberto}
        onClose={() => setModalAberto(false)}
        conta={contaEditando}
        contaPai={contaPai}
        onSubmit={handleSubmit}
        loading={criar.isPending || atualizar.isPending}
      />

      <ConfirmDialog
        isOpen={!!contaExcluindo}
        onClose={() => setContaExcluindo(null)}
        onConfirm={handleExcluir}
        title="Excluir conta"
        message={
          contaExcluindo
            ? `Tem certeza que deseja excluir "${contaExcluindo.codigo} — ${contaExcluindo.nome}"?`
            : ''
        }
        confirmText="Excluir"
        loading={excluir.isPending}
      />
    </div>
  );
}
