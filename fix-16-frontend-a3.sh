#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil/frontend

mkdir -p src/{components/lancamentos,components/common,pages/lancamentos,hooks}

# ============================================================
# 1. TIPOS ADICIONAIS
# ============================================================
cat >> src/types/index.ts <<'TYPES_EOF'

// ============ PLANO DE CONTAS ============
export type NaturezaConta = 'ATIVO' | 'PASSIVO' | 'PATRIMONIO_LIQUIDO' | 'RECEITA' | 'DESPESA' | 'CUSTO';
export type TipoConta = 'SINTETICA' | 'ANALITICA';

export interface Conta {
  id: string;
  planoContasId: string;
  contaPaiId?: string;
  codigo: string;
  nome: string;
  natureza: NaturezaConta;
  tipo: TipoConta;
  grau: number;
  aceitaLancamento: boolean;
  dreLinha?: string;
  status: 'ATIVO' | 'INATIVO';
}

export interface ContaArvore extends Conta {
  filhas: ContaArvore[];
}

export interface PlanoContas {
  id: string;
  empresaId: string;
  nome: string;
  versao: number;
  vigenciaInicio: string;
  vigenciaFim?: string;
  status: 'ATIVO' | 'INATIVO';
}

// ============ CENTRO DE CUSTO ============
export interface CentroCusto {
  id: string;
  empresaId: string;
  codigo: string;
  nome: string;
  status: 'ATIVO' | 'INATIVO';
}

// ============ LANÇAMENTO ============
export type TipoPartida = 'D' | 'C';
export type StatusLancamento = 'ATIVO' | 'ESTORNADO';

export interface Partida {
  id: string;
  lancamentoId: string;
  contaId: string;
  centroCustoId?: string;
  tipo: TipoPartida;
  valor: number | string;
  conta?: Conta;
  centroCusto?: CentroCusto;
}

export interface Lancamento {
  id: string;
  empresaId: string;
  loteId?: string;
  numero: number;
  dataLancamento: string;
  competencia: string;
  historico: string;
  documentoRef?: string;
  valorTotal: number | string;
  status: StatusLancamento;
  estornoDeId?: string;
  createdAt: string;
  partidas?: Partida[];
  empresa?: { razaoSocial: string; cnpj: string };
}

export interface CreatePartidaPayload {
  contaId: string;
  centroCustoId?: string;
  tipo: TipoPartida;
  valor: number;
}

export interface CreateLancamentoPayload {
  empresaId: string;
  loteId?: string;
  dataLancamento: string;
  competencia: string;
  historico: string;
  documentoRef?: string;
  partidas: CreatePartidaPayload[];
}

export interface FilterLancamentos {
  empresaId?: string;
  competencia?: string;
  page?: number;
  limit?: number;
}

// ============ FECHAMENTO ============
export type StatusFechamento = 'ABERTO' | 'FECHADO';

export interface FechamentoPeriodo {
  id: string;
  empresaId: string;
  competencia: string;
  status: StatusFechamento;
  fechadoPor?: string;
  fechadoEm?: string;
}
TYPES_EOF

# ============================================================
# 2. SERVICE — PLANO DE CONTAS
# ============================================================
cat > src/services/plano-contas.service.ts <<'SVC_EOF'
import { api } from '@/lib/axios';
import type { ContaArvore, PlanoContas } from '@/types';

export const planoContasService = {
  async listarPlanos(empresaId: string): Promise<PlanoContas[]> {
    const { data } = await api.get<PlanoContas[]>(`/empresas/${empresaId}/plano-contas`);
    return data;
  },

  async listarContas(planoId: string): Promise<ContaArvore[]> {
    const { data } = await api.get<ContaArvore[]>(`/planos/${planoId}/contas`);
    return data;
  },

  async criarPlanoPadrao(empresaId: string, nome?: string): Promise<PlanoContas> {
    const { data } = await api.post<PlanoContas>(
      `/empresas/${empresaId}/plano-contas/padrao`,
      null,
      { params: nome ? { nome } : {} },
    );
    return data;
  },
};
SVC_EOF

# ============================================================
# 3. SERVICE — CENTROS DE CUSTO
# ============================================================
cat > src/services/centros-custo.service.ts <<'SVC_EOF'
import { api } from '@/lib/axios';
import type { CentroCusto } from '@/types';

export const centrosCustoService = {
  async listarPorEmpresa(empresaId: string): Promise<CentroCusto[]> {
    const { data } = await api.get<CentroCusto[]>(`/centros-custo/empresa/${empresaId}`);
    return data;
  },
};
SVC_EOF

# ============================================================
# 4. SERVICE — LANÇAMENTOS
# ============================================================
cat > src/services/lancamentos.service.ts <<'SVC_EOF'
import { api } from '@/lib/axios';
import type {
  Lancamento,
  CreateLancamentoPayload,
  FilterLancamentos,
} from '@/types';

interface LancamentosResponse {
  data: Lancamento[];
  meta: {
    total: number;
    page: number;
    limit: number;
    totalPages: number;
  };
}

export const lancamentosService = {
  async listar(filtros: FilterLancamentos): Promise<LancamentosResponse> {
    const { data } = await api.get<LancamentosResponse>('/lancamentos', {
      params: {
        empresaId: filtros.empresaId,
        competencia: filtros.competencia,
        page: filtros.page ?? 1,
        limit: filtros.limit ?? 30,
      },
    });
    return data;
  },

  async buscarPorId(id: string): Promise<Lancamento> {
    const { data } = await api.get<Lancamento>(`/lancamentos/${id}`);
    return data;
  },

  async criar(payload: CreateLancamentoPayload): Promise<Lancamento> {
    const { data } = await api.post<Lancamento>('/lancamentos', payload);
    return data;
  },

  async estornar(id: string, motivo: string): Promise<Lancamento> {
    const { data } = await api.post<Lancamento>(`/lancamentos/${id}/estornar`, { motivo });
    return data;
  },
};
SVC_EOF

# ============================================================
# 5. SERVICE — FECHAMENTO
# ============================================================
cat > src/services/fechamento.service.ts <<'SVC_EOF'
import { api } from '@/lib/axios';

interface Fechamento {
  id: string;
  empresaId: string;
  competencia: string;
  status: 'ABERTO' | 'FECHADO';
  fechadoEm?: string;
}

export const fechamentoService = {
  async buscar(empresaId: string, competencia: string): Promise<Fechamento | null> {
    try {
      const { data } = await api.get(`/fechamento`, {
        params: { empresaId, competencia },
      });
      return data;
    } catch {
      return null;
    }
  },

  async fechar(empresaId: string, competencia: string): Promise<Fechamento> {
    const { data } = await api.post('/fechamento/fechar', { empresaId, competencia });
    return data;
  },

  async reabrir(empresaId: string, competencia: string, motivo: string): Promise<Fechamento> {
    const { data } = await api.post('/fechamento/reabrir', {
      empresaId,
      competencia,
      motivo,
    });
    return data;
  },
};
SVC_EOF

# ============================================================
# 6. HOOKS — PLANO DE CONTAS
# ============================================================
cat > src/hooks/usePlanoContas.ts <<'HOOK_EOF'
import { useQuery } from '@tanstack/react-query';
import { planoContasService } from '@/services/plano-contas.service';

export function usePlanoAtivo(empresaId: string | null) {
  return useQuery({
    queryKey: ['planos', empresaId],
    queryFn: async () => {
      const planos = await planoContasService.listarPlanos(empresaId!);
      return planos.find((p) => p.status === 'ATIVO') ?? planos[0] ?? null;
    },
    enabled: !!empresaId,
  });
}

export function useContasDoPlano(planoId: string | null) {
  return useQuery({
    queryKey: ['contas', planoId],
    queryFn: () => planoContasService.listarContas(planoId!),
    enabled: !!planoId,
  });
}

/**
 * Retorna a lista achatada de contas analíticas (que aceitam lançamento).
 */
export function achatarContas(arvore: any[]): any[] {
  const resultado: any[] = [];
  function percorrer(nodes: any[]) {
    for (const node of nodes) {
      if (node.aceitaLancamento) resultado.push(node);
      if (node.filhas?.length) percorrer(node.filhas);
    }
  }
  percorrer(arvore);
  return resultado;
}
HOOK_EOF

# ============================================================
# 7. HOOKS — LANÇAMENTOS
# ============================================================
cat > src/hooks/useLancamentos.ts <<'HOOK_EOF'
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { lancamentosService } from '@/services/lancamentos.service';
import type { CreateLancamentoPayload, FilterLancamentos } from '@/types';
import { toast } from '@/components/ui/Toast';
import { getApiError } from '@/lib/axios';

const KEY = 'lancamentos';

export function useLancamentos(filtros: FilterLancamentos) {
  return useQuery({
    queryKey: [KEY, filtros],
    queryFn: () => lancamentosService.listar(filtros),
    enabled: !!filtros.empresaId,
    placeholderData: (prev) => prev,
  });
}

export function useLancamento(id: string | null) {
  return useQuery({
    queryKey: [KEY, id],
    queryFn: () => lancamentosService.buscarPorId(id!),
    enabled: !!id,
  });
}

export function useCriarLancamento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: (payload: CreateLancamentoPayload) => lancamentosService.criar(payload),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Lançamento criado com sucesso');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}

export function useEstornarLancamento() {
  const qc = useQueryClient();
  return useMutation({
    mutationFn: ({ id, motivo }: { id: string; motivo: string }) =>
      lancamentosService.estornar(id, motivo),
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: [KEY] });
      toast.success('Lançamento estornado');
    },
    onError: (err) => toast.error(getApiError(err)),
  });
}
HOOK_EOF

# ============================================================
# 8. HOOKS — CENTROS DE CUSTO
# ============================================================
cat > src/hooks/useCentrosCusto.ts <<'HOOK_EOF'
import { useQuery } from '@tanstack/react-query';
import { centrosCustoService } from '@/services/centros-custo.service';

export function useCentrosCusto(empresaId: string | null) {
  return useQuery({
    queryKey: ['centros-custo', empresaId],
    queryFn: () => centrosCustoService.listarPorEmpresa(empresaId!),
    enabled: !!empresaId,
  });
}
HOOK_EOF

# ============================================================
# 9. COMPONENTE — SELETOR DE EMPRESA
# ============================================================
cat > src/components/common/EmpresaSelect.tsx <<'SEL_EOF'
import { useEmpresas } from '@/hooks/useEmpresas';

interface EmpresaSelectProps {
  value: string;
  onChange: (id: string) => void;
  disabled?: boolean;
  required?: boolean;
  className?: string;
}

export function EmpresaSelect({
  value,
  onChange,
  disabled,
  required,
  className,
}: EmpresaSelectProps) {
  const { data, isLoading } = useEmpresas({ limit: 200, status: 'ATIVA' });

  return (
    <select
      className={`input-base ${className ?? ''}`}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled || isLoading}
      required={required}
    >
      <option value="">— Selecione uma empresa —</option>
      {data?.data.map((e) => (
        <option key={e.id} value={e.id}>
          {e.razaoSocial}
        </option>
      ))}
    </select>
  );
}
SEL_EOF

# ============================================================
# 10. COMPONENTE — SELETOR DE CONTA
# ============================================================
cat > src/components/common/ContaSelect.tsx <<'CONTA_SEL_EOF'
import { useMemo, useState } from 'react';
import { Check, ChevronDown, Search } from 'lucide-react';
import { useContasDoPlano, achatarContas } from '@/hooks/usePlanoContas';
import { cn } from '@/lib/utils';

interface ContaSelectProps {
  planoId: string | null;
  value: string;
  onChange: (contaId: string) => void;
  disabled?: boolean;
  placeholder?: string;
}

export function ContaSelect({
  planoId,
  value,
  onChange,
  disabled,
  placeholder = 'Selecionar conta...',
}: ContaSelectProps) {
  const { data: arvore, isLoading } = useContasDoPlano(planoId);
  const [open, setOpen] = useState(false);
  const [busca, setBusca] = useState('');

  const contas = useMemo(() => {
    if (!arvore) return [];
    return achatarContas(arvore);
  }, [arvore]);

  const filtradas = useMemo(() => {
    if (!busca) return contas.slice(0, 50);
    const termo = busca.toLowerCase();
    return contas
      .filter(
        (c) =>
          c.codigo.toLowerCase().includes(termo) ||
          c.nome.toLowerCase().includes(termo),
      )
      .slice(0, 50);
  }, [contas, busca]);

  const selecionada = contas.find((c) => c.id === value);

  if (isLoading) {
    return <div className="input-base opacity-60">Carregando contas...</div>;
  }

  if (contas.length === 0) {
    return (
      <div className="input-base text-amber-600">
        Nenhuma conta analítica no plano. Crie um plano primeiro.
      </div>
    );
  }

  return (
    <div className="relative">
      <button
        type="button"
        className={cn(
          'input-base flex items-center justify-between text-left',
          !selecionada && 'text-gray-400',
        )}
        onClick={() => !disabled && setOpen(!open)}
        disabled={disabled}
      >
        {selecionada ? (
          <span className="truncate">
            <span className="font-mono text-xs text-gray-500">{selecionada.codigo}</span>{' '}
            {selecionada.nome}
          </span>
        ) : (
          <span>{placeholder}</span>
        )}
        <ChevronDown className="h-4 w-4 flex-shrink-0 opacity-50" />
      </button>

      {open && (
        <>
          <div className="fixed inset-0 z-10" onClick={() => setOpen(false)} />
          <div className="absolute left-0 right-0 top-full z-20 mt-1 max-h-80 overflow-hidden rounded-md border border-gray-200 bg-white shadow-lg">
            <div className="border-b border-gray-100 p-2">
              <div className="relative">
                <Search className="absolute left-2 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
                <input
                  autoFocus
                  className="w-full rounded-md border border-gray-200 py-1.5 pl-8 pr-2 text-sm focus:outline-none focus:ring-2 focus:ring-brand-500"
                  placeholder="Buscar por código ou nome..."
                  value={busca}
                  onChange={(e) => setBusca(e.target.value)}
                />
              </div>
            </div>
            <div className="max-h-60 overflow-y-auto">
              {filtradas.length === 0 ? (
                <p className="p-4 text-center text-sm text-gray-500">
                  Nenhuma conta encontrada
                </p>
              ) : (
                filtradas.map((c) => (
                  <button
                    key={c.id}
                    type="button"
                    onClick={() => {
                      onChange(c.id);
                      setOpen(false);
                      setBusca('');
                    }}
                    className={cn(
                      'flex w-full items-center justify-between gap-2 px-3 py-2 text-left text-sm hover:bg-gray-50',
                      c.id === value && 'bg-brand-50',
                    )}
                  >
                    <div className="min-w-0 flex-1">
                      <div className="flex items-center gap-2">
                        <span className="font-mono text-xs text-gray-500">{c.codigo}</span>
                        <span className="truncate text-gray-900">{c.nome}</span>
                      </div>
                      <p className="text-xs text-gray-400">
                        {c.natureza.toLowerCase()}
                      </p>
                    </div>
                    {c.id === value && <Check className="h-4 w-4 text-brand-600" />}
                  </button>
                ))
              )}
            </div>
          </div>
        </>
      )}
    </div>
  );
}
CONTA_SEL_EOF

# ============================================================
# 11. COMPONENTE — LINHA DE PARTIDA
# ============================================================
cat > src/components/lancamentos/PartidaRow.tsx <<'PARTIDA_ROW_EOF'
import { Trash2 } from 'lucide-react';
import { Input } from '@/components/ui/Input';
import { ContaSelect } from '@/components/common/ContaSelect';
import { cn } from '@/lib/utils';
import type { CentroCusto } from '@/types';

export interface PartidaForm {
  contaId: string;
  centroCustoId?: string;
  tipo: 'D' | 'C';
  valor: number;
}

interface PartidaRowProps {
  partida: PartidaForm;
  planoId: string | null;
  centros: CentroCusto[];
  onChange: (partida: PartidaForm) => void;
  onRemove: () => void;
  showRemove: boolean;
}

export function PartidaRow({
  partida,
  planoId,
  centros,
  onChange,
  onRemove,
  showRemove,
}: PartidaRowProps) {
  return (
    <div className="grid grid-cols-12 items-start gap-2">
      {/* Conta */}
      <div className="col-span-12 lg:col-span-5">
        <ContaSelect
          planoId={planoId}
          value={partida.contaId}
          onChange={(contaId) => onChange({ ...partida, contaId })}
        />
      </div>

      {/* Centro de custo */}
      <div className="col-span-6 lg:col-span-2">
        <select
          className="input-base"
          value={partida.centroCustoId ?? ''}
          onChange={(e) =>
            onChange({ ...partida, centroCustoId: e.target.value || undefined })
          }
        >
          <option value="">— CC —</option>
          {centros.map((cc) => (
            <option key={cc.id} value={cc.id}>
              {cc.codigo} — {cc.nome}
            </option>
          ))}
        </select>
      </div>

      {/* Tipo */}
      <div className="col-span-3 lg:col-span-2">
        <div className="flex h-10 overflow-hidden rounded-md border border-gray-300">
          <button
            type="button"
            onClick={() => onChange({ ...partida, tipo: 'D' })}
            className={cn(
              'flex-1 text-sm font-medium transition-colors',
              partida.tipo === 'D'
                ? 'bg-emerald-600 text-white'
                : 'bg-white text-gray-600 hover:bg-gray-50',
            )}
          >
            Débito
          </button>
          <button
            type="button"
            onClick={() => onChange({ ...partida, tipo: 'C' })}
            className={cn(
              'flex-1 text-sm font-medium transition-colors',
              partida.tipo === 'C'
                ? 'bg-rose-600 text-white'
                : 'bg-white text-gray-600 hover:bg-gray-50',
            )}
          >
            Crédito
          </button>
        </div>
      </div>

      {/* Valor */}
      <div className="col-span-2 lg:col-span-2">
        <Input
          type="number"
          step="0.01"
          placeholder="0,00"
          value={partida.valor || ''}
          onChange={(e) =>
            onChange({ ...partida, valor: parseFloat(e.target.value) || 0 })
          }
          className="text-right font-mono"
        />
      </div>

      {/* Remover */}
      <div className="col-span-1 flex justify-end">
        {showRemove && (
          <button
            type="button"
            onClick={onRemove}
            className="rounded-md p-2 text-gray-400 hover:bg-red-50 hover:text-red-600"
            title="Remover partida"
          >
            <Trash2 className="h-4 w-4" />
          </button>
        )}
      </div>
    </div>
  );
}
PARTIDA_ROW_EOF

# ============================================================
# 12. COMPONENTE — FORMULÁRIO DE LANÇAMENTO
# ============================================================
cat > src/components/lancamentos/LancamentoForm.tsx <<'LANC_FORM_EOF'
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
LANC_FORM_EOF

# ============================================================
# 13. COMPONENTE — MODAL DE LANÇAMENTO
# ============================================================
cat > src/components/lancamentos/LancamentoModal.tsx <<'LANC_MODAL_EOF'
import { Modal } from '@/components/ui/Modal';
import { LancamentoForm } from './LancamentoForm';
import { useCriarLancamento } from '@/hooks/useLancamentos';
import type { CreateLancamentoPayload } from '@/types';

interface LancamentoModalProps {
  isOpen: boolean;
  onClose: () => void;
  empresaIdInicial?: string;
}

export function LancamentoModal({ isOpen, onClose, empresaIdInicial }: LancamentoModalProps) {
  const criar = useCriarLancamento();

  const handleSubmit = (payload: CreateLancamentoPayload) => {
    criar.mutate(payload, { onSuccess: onClose });
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Novo Lançamento Contábil"
      size="xl"
    >
      <LancamentoForm
        onSubmit={handleSubmit}
        onCancel={onClose}
        loading={criar.isPending}
        empresaIdInicial={empresaIdInicial}
      />
    </Modal>
  );
}
LANC_MODAL_EOF

# ============================================================
# 14. COMPONENTE — TABELA DE LANÇAMENTOS
# ============================================================
cat > src/components/lancamentos/LancamentosTable.tsx <<'LANC_TABLE_EOF'
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
LANC_TABLE_EOF

# ============================================================
# 15. COMPONENTE — NAVEGAÇÃO DE COMPETÊNCIA
# ============================================================
cat > src/components/common/CompetenciaNav.tsx <<'COMP_NAV_EOF'
import { ChevronLeft, ChevronRight, Calendar } from 'lucide-react';
import { Button } from '@/components/ui/Button';

interface CompetenciaNavProps {
  competencia: string; // YYYY-MM-DD
  onChange: (nova: string) => void;
}

function formatarCompetencia(data: string): string {
  const [ano, mes] = data.split('-');
  const nome = new Date(parseInt(ano), parseInt(mes) - 1, 1).toLocaleDateString('pt-BR', {
    month: 'long',
    year: 'numeric',
  });
  return nome.charAt(0).toUpperCase() + nome.slice(1);
}

export function CompetenciaNav({ competencia, onChange }: CompetenciaNavProps) {
  const mudarMes = (delta: number) => {
    const [ano, mes] = competencia.split('-').map(Number);
    const d = new Date(ano, mes - 1 + delta, 1);
    const novo = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`;
    onChange(novo);
  };

  return (
    <div className="flex items-center gap-2">
      <Button variant="outline" size="sm" onClick={() => mudarMes(-1)} title="Mês anterior">
        <ChevronLeft className="h-4 w-4" />
      </Button>

      <div className="flex items-center gap-2 rounded-md border border-gray-300 bg-white px-3 py-2">
        <Calendar className="h-4 w-4 text-gray-500" />
        <input
          type="month"
          value={competencia.slice(0, 7)}
          onChange={(e) => onChange(`${e.target.value}-01`)}
          className="border-0 bg-transparent text-sm font-medium text-gray-900 focus:outline-none"
        />
      </div>

      <Button variant="outline" size="sm" onClick={() => mudarMes(1)} title="Próximo mês">
        <ChevronRight className="h-4 w-4" />
      </Button>
    </div>
  );
}
COMP_NAV_EOF

# ============================================================
# 16. PÁGINA — LISTA DE LANÇAMENTOS
# ============================================================
cat > src/pages/lancamentos/LancamentosList.tsx <<'LIST_EOF'
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
          disabled={!empresaId}
          title={!empresaId ? 'Selecione uma empresa primeiro' : undefined}
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
LIST_EOF

# ============================================================
# 17. PÁGINA — DETALHE DE LANÇAMENTO
# ============================================================
cat > src/pages/lancamentos/LancamentoDetail.tsx <<'DETAIL_EOF'
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
DETAIL_EOF

# ============================================================
# 18. ATUALIZAR App.tsx
# ============================================================
python3 <<'PYEOF'
with open('src/App.tsx', 'r') as f:
    content = f.read()

imports = """import { LancamentosListPage } from '@/pages/lancamentos/LancamentosList';
import { LancamentoDetailPage } from '@/pages/lancamentos/LancamentoDetail';
"""
if 'LancamentosListPage' not in content:
    content = content.replace(
        "import { EmpresasListPage } from '@/pages/empresas/EmpresasList';",
        "import { EmpresasListPage } from '@/pages/empresas/EmpresasList';\n" + imports
    )

content = content.replace(
    '<Route path="lancamentos" element={<EmBreve titulo="Lançamentos" />} />',
    '<Route path="lancamentos" element={<LancamentosListPage />} />\n'
    '              <Route path="lancamentos/:id" element={<LancamentoDetailPage />} />'
)

with open('src/App.tsx', 'w') as f:
    f.write(content)
print("✅ App.tsx atualizado")
PYEOF

echo ""
echo "✅ Pacote A3 instalado!"
echo ""
echo "Rode agora:"
echo "  cd /home/neimar/Projetos/Contabil/frontend && npm run dev"