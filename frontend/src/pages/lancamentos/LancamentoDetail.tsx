import { Link, useParams } from 'react-router-dom';
import { ArrowLeft, RotateCcw, FileText } from 'lucide-react';
import { useState } from 'react';
import { Button } from '@/components/ui/Button';
import { Card, CardContent, CardHeader, CardTitle } from '@/components/ui/Card';
import { Badge } from '@/components/ui/Badge';
import { Spinner } from '@/components/ui/Spinner';
import { Modal } from '@/components/ui/Modal';
import { Input } from '@/components/ui/Input';
import { Label } from '@/components/ui/Label';
import { useLancamento, useEstornarLancamento } from '@/hooks/useLancamentos';
import { formatCurrency, formatDate } from '@/lib/format';

export function LancamentoDetailPage() {
  const { id } = useParams<{ id: string }>();
  const { data: lancamento, isLoading } = useLancamento(id ?? null);
  const estornar = useEstornarLancamento();
  const [modalOpen, setModalOpen] = useState(false);
  const [motivo, setMotivo] = useState('');

  if (isLoading) {
    return (
      <div className="flex justify-center py-20">
        <Spinner size="lg" />
      </div>
    );
  }

  if (!lancamento) {
    return (
      <div className="py-20 text-center">
        <p className="text-gray-500">Lançamento não encontrado</p>
        <Link to="/lancamentos" className="mt-4 inline-block">
          <Button variant="outline">Voltar</Button>
        </Link>
      </div>
    );
  }

  const partidas = lancamento.partidas ?? [];
  const debitos = partidas.filter((p) => p.tipo === 'D').reduce((s, p) => s + Number(p.valor), 0);
  const creditos = partidas.filter((p) => p.tipo === 'C').reduce((s, p) => s + Number(p.valor), 0);

  const handleEstornar = () => {
    if (motivo.trim().length < 5) return;
    estornar.mutate(
      { id: lancamento.id, motivo: motivo.trim() },
      {
        onSuccess: () => {
          setModalOpen(false);
          setMotivo('');
        },
      },
    );
  };

  return (
    <div className="space-y-6">
      <Link
        to="/lancamentos"
        className="inline-flex items-center gap-1 text-sm text-gray-500 hover:text-gray-700"
      >
        <ArrowLeft className="h-4 w-4" />
        Voltar para Lançamentos
      </Link>

      <div className="flex flex-col justify-between gap-4 sm:flex-row sm:items-start">
        <div>
          <div className="flex items-center gap-3">
            <div className="flex h-12 w-12 items-center justify-center rounded-lg bg-brand-100">
              <FileText className="h-6 w-6 text-brand-700" />
            </div>
            <div>
              <h1 className="text-2xl font-bold text-gray-900">
                Lançamento nº {String(lancamento.numero).padStart(6, '0')}
              </h1>
              <p className="text-sm text-gray-500">
                {formatDate(lancamento.dataLancamento)} · Competência{' '}
                {new Date(lancamento.competencia).toLocaleDateString('pt-BR', {
                  month: 'long',
                  year: 'numeric',
                })}
              </p>
            </div>
          </div>
          <div className="mt-3">
            <Badge variant={lancamento.status === 'ATIVO' ? 'success' : 'danger'}>
              {lancamento.status}
            </Badge>
          </div>
        </div>

        {lancamento.status === 'ATIVO' && (
          <Button variant="outline" onClick={() => setModalOpen(true)}>
            <RotateCcw className="h-4 w-4" />
            Estornar
          </Button>
        )}
      </div>

      <div className="grid grid-cols-1 gap-6 lg:grid-cols-3">
        <Card className="lg:col-span-2">
          <CardHeader>
            <CardTitle>Partidas</CardTitle>
          </CardHeader>
          <CardContent className="p-0">
            <table className="w-full">
              <thead className="bg-gray-50">
                <tr>
                  <th className="px-4 py-2 text-left text-xs font-semibold uppercase text-gray-600">
                    Conta
                  </th>
                  <th className="px-4 py-2 text-left text-xs font-semibold uppercase text-gray-600">
                    Centro de custo
                  </th>
                  <th className="px-4 py-2 text-right text-xs font-semibold uppercase text-gray-600">
                    Débito
                  </th>
                  <th className="px-4 py-2 text-right text-xs font-semibold uppercase text-gray-600">
                    Crédito
                  </th>
                </tr>
              </thead>
              <tbody className="divide-y divide-gray-100">
                {partidas.map((p) => (
                  <tr key={p.id}>
                    <td className="px-4 py-3">
                      <span className="font-mono text-xs text-gray-500">
                        {p.conta?.codigo}
                      </span>{' '}
                      <span className="text-sm text-gray-900">{p.conta?.nome}</span>
                    </td>
                    <td className="px-4 py-3 text-sm text-gray-600">
                      {p.centroCusto?.nome ?? '—'}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-sm">
                      {p.tipo === 'D' ? formatCurrency(Number(p.valor)) : ''}
                    </td>
                    <td className="px-4 py-3 text-right font-mono text-sm">
                      {p.tipo === 'C' ? formatCurrency(Number(p.valor)) : ''}
                    </td>
                  </tr>
                ))}
                <tr className="bg-gray-50 font-semibold">
                  <td colSpan={2} className="px-4 py-3 text-right text-sm text-gray-700">
                    Totais
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-sm text-emerald-700">
                    {formatCurrency(debitos)}
                  </td>
                  <td className="px-4 py-3 text-right font-mono text-sm text-rose-700">
                    {formatCurrency(creditos)}
                  </td>
                </tr>
              </tbody>
            </table>
          </CardContent>
        </Card>

        <Card>
          <CardHeader>
            <CardTitle>Informações</CardTitle>
          </CardHeader>
          <CardContent className="space-y-3 text-sm">
            <Field label="Histórico" value={lancamento.historico} />
            <Field label="Documento" value={lancamento.documentoRef ?? '—'} />
            <Field label="Valor total" value={formatCurrency(Number(lancamento.valorTotal))} />
            <Field
              label="Competência"
              value={new Date(lancamento.competencia).toLocaleDateString('pt-BR')}
            />
            <Field
              label="Criado em"
              value={new Date(lancamento.createdAt).toLocaleString('pt-BR')}
            />
            {lancamento.estornoDeId && (
              <Field
                label="Estorno de"
                value={
                  <Link
                    to={`/lancamentos/${lancamento.estornoDeId}`}
                    className="text-brand-600 hover:underline"
                  >
                    Ver original
                  </Link>
                }
              />
            )}
          </CardContent>
        </Card>
      </div>

      <Modal
        isOpen={modalOpen}
        onClose={() => { setModalOpen(false); setMotivo(''); }}
        title="Estornar lançamento"
        size="sm"
      >
        <div className="space-y-4">
          <p className="text-sm text-gray-600">
            Um novo lançamento com as partidas invertidas será criado. Esta ação não pode ser
            desfeita.
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
              onClick={() => { setModalOpen(false); setMotivo(''); }}
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

function Field({ label, value }: { label: string; value: React.ReactNode }) {
  return (
    <div className="flex flex-col gap-0.5 border-b border-gray-100 pb-2 last:border-0">
      <span className="text-xs font-medium text-gray-500">{label}</span>
      <span className="text-sm text-gray-900">{value}</span>
    </div>
  );
}
