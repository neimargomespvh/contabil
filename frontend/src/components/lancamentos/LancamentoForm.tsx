import { useMemo, useState } from 'react';
import { Plus, Scale } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { PartidaRow, type PartidaForm } from './PartidaRow';
import { EmpresaSelect } from '@/components/common/EmpresaSelect';
import { usePlanoAtivo } from '@/hooks/usePlanoContas';
import { useCentrosCusto } from '@/hooks/useCentrosCusto';
import { formatCurrency } from '@/lib/format';
import { cn } from '@/lib/utils';
import type { CreateLancamentoPayload } from '@/types';

const NOVA_PARTIDA: PartidaForm = {
  contaId: '',
  tipo: 'D',
  valor: 0,
};

interface LancamentoFormProps {
  onSubmit: (payload: CreateLancamentoPayload) => void;
  onCancel: () => void;
  loading?: boolean;
  empresaIdInicial?: string;
}

export function LancamentoForm({
  onSubmit,
  onCancel,
  loading,
  empresaIdInicial,
}: LancamentoFormProps) {
  const hoje = new Date().toISOString().slice(0, 10);
  const competenciaInicial = hoje.slice(0, 8) + '01';

  const [empresaId, setEmpresaId] = useState(empresaIdInicial ?? '');
  const [dataLancamento, setDataLancamento] = useState(hoje);
  const [competencia, setCompetencia] = useState(competenciaInicial);
  const [historico, setHistorico] = useState('');
  const [documentoRef, setDocumentoRef] = useState('');
  const [partidas, setPartidas] = useState<PartidaForm[]>([
    { ...NOVA_PARTIDA },
    { ...NOVA_PARTIDA, tipo: 'C' },
  ]);

  const { data: plano } = usePlanoAtivo(empresaId || null);
  const { data: centros = [] } = useCentrosCusto(empresaId || null);

  const totais = useMemo(() => {
    const debitos = partidas.filter((p) => p.tipo === 'D').reduce((s, p) => s + (p.valor || 0), 0);
    const creditos = partidas.filter((p) => p.tipo === 'C').reduce((s, p) => s + (p.valor || 0), 0);
    return {
      debitos,
      creditos,
      diferenca: Number((debitos - creditos).toFixed(2)),
      balanceado: Math.abs(debitos - creditos) < 0.01 && debitos > 0,
    };
  }, [partidas]);

  const atualizarPartida = (index: number, p: PartidaForm) => {
    const novo = [...partidas];
    novo[index] = p;
    setPartidas(novo);
  };

  const removerPartida = (index: number) => {
    setPartidas(partidas.filter((_, i) => i !== index));
  };

  const adicionarPartida = () => {
    setPartidas([...partidas, { ...NOVA_PARTIDA }]);
  };

  const podeSalvar =
    empresaId &&
    historico.trim().length >= 3 &&
    partidas.length >= 2 &&
    partidas.every((p) => p.contaId && p.valor > 0) &&
    totais.balanceado;

  const submit = (e: React.FormEvent) => {
    e.preventDefault();
    if (!podeSalvar) return;

    const payload: CreateLancamentoPayload = {
      empresaId,
      dataLancamento,
      competencia,
      historico: historico.trim(),
      documentoRef: documentoRef.trim() || undefined,
      partidas: partidas.map((p) => ({
        contaId: p.contaId,
        centroCustoId: p.centroCustoId,
        tipo: p.tipo,
        valor: p.valor,
      })),
    };

    onSubmit(payload);
  };

  return (
    <form onSubmit={submit} className="space-y-6">
      {/* Cabeçalho */}
      <div className="grid grid-cols-1 gap-4 sm:grid-cols-4">
        <div className="sm:col-span-2">
          <Label>Empresa *</Label>
          <EmpresaSelect
            value={empresaId}
            onChange={setEmpresaId}
            required
          />
        </div>

        <div>
          <Label>Data do lançamento *</Label>
          <Input
            type="date"
            value={dataLancamento}
            onChange={(e) => setDataLancamento(e.target.value)}
            required
          />
        </div>

        <div>
          <Label>Competência *</Label>
          <Input
            type="date"
            value={competencia}
            onChange={(e) => setCompetencia(e.target.value)}
            required
          />
        </div>
      </div>

      <div className="grid grid-cols-1 gap-4 sm:grid-cols-3">
        <div className="sm:col-span-2">
          <Label>Histórico *</Label>
          <Input
            value={historico}
            onChange={(e) => setHistorico(e.target.value)}
            placeholder="Ex: Compra de mercadoria para revenda"
            maxLength={500}
            required
          />
        </div>

        <div>
          <Label>Documento de referência</Label>
          <Input
            value={documentoRef}
            onChange={(e) => setDocumentoRef(e.target.value)}
            placeholder="Ex: NF 1234"
            maxLength={100}
          />
        </div>
      </div>

      {/* Partidas */}
      <div>
        <div className="mb-3 flex items-center justify-between">
          <h3 className="text-sm font-semibold uppercase tracking-wide text-gray-500">
            Partidas dobradas *
          </h3>
          <Button type="button" variant="outline" size="sm" onClick={adicionarPartida}>
            <Plus className="h-4 w-4" />
            Adicionar partida
          </Button>
        </div>

        {/* Cabeçalho das colunas */}
        <div className="hidden grid-cols-12 gap-2 px-1 pb-2 text-xs font-semibold uppercase text-gray-500 lg:grid">
          <div className="col-span-5">Conta</div>
          <div className="col-span-2">Centro de custo</div>
          <div className="col-span-2">Tipo</div>
          <div className="col-span-2 text-right">Valor</div>
          <div className="col-span-1" />
        </div>

        <div className="space-y-2">
          {partidas.map((p, i) => (
            <PartidaRow
              key={i}
              partida={p}
              planoId={plano?.id ?? null}
              empresaId={empresaId}
              centros={centros}
              onChange={(nova) => atualizarPartida(i, nova)}
              onRemove={() => removerPartida(i)}
              showRemove={partidas.length > 2}
            />
          ))}
        </div>

        {/* Totais */}
        <div
          className={cn(
            'mt-4 flex items-center justify-between rounded-md border p-4',
            totais.balanceado
              ? 'border-emerald-200 bg-emerald-50'
              : 'border-amber-200 bg-amber-50',
          )}
        >
          <div className="flex items-center gap-3">
            <div
              className={cn(
                'flex h-10 w-10 items-center justify-center rounded-full',
                totais.balanceado ? 'bg-emerald-100' : 'bg-amber-100',
              )}
            >
              <Scale
                className={cn(
                  'h-5 w-5',
                  totais.balanceado ? 'text-emerald-600' : 'text-amber-600',
                )}
              />
            </div>
            <div>
              <p
                className={cn(
                  'text-sm font-semibold',
                  totais.balanceado ? 'text-emerald-800' : 'text-amber-800',
                )}
              >
                {totais.balanceado
                  ? '✓ Lançamento balanceado'
                  : `Diferença: ${formatCurrency(Math.abs(totais.diferenca))}`}
              </p>
              <p className="text-xs text-gray-600">
                {totais.balanceado
                  ? 'Débitos e créditos conferem'
                  : 'Débitos e créditos precisam ser iguais'}
              </p>
            </div>
          </div>

          <div className="flex gap-6 text-right">
            <div>
              <p className="text-xs font-medium text-gray-500">Débitos</p>
              <p className="font-mono text-sm font-semibold text-emerald-700">
                {formatCurrency(totais.debitos)}
              </p>
            </div>
            <div>
              <p className="text-xs font-medium text-gray-500">Créditos</p>
              <p className="font-mono text-sm font-semibold text-rose-700">
                {formatCurrency(totais.creditos)}
              </p>
            </div>
          </div>
        </div>
      </div>

      <div className="flex justify-end gap-2 border-t border-gray-200 pt-4">
        <Button type="button" variant="outline" onClick={onCancel} disabled={loading}>
          Cancelar
        </Button>
        <Button type="submit" loading={loading} disabled={!podeSalvar}>
          Lançar
        </Button>
      </div>
    </form>
  );
}
