import { useMemo, useState } from 'react';
import { Check, ChevronDown, Search, Plus, Loader2 } from 'lucide-react';
import { useContasDoPlano, achatarContas } from '@/hooks/usePlanoContas';
import { Button } from '@/components/ui/Button';
import { toast } from '@/components/ui/Toast';
import { planoContasService } from '@/services/plano-contas.service';
import { useQueryClient } from '@tanstack/react-query';
import { getApiError } from '@/lib/axios';
import { cn } from '@/lib/utils';

interface ContaSelectProps {
  planoId: string | null;
  empresaId: string;
  value: string;
  onChange: (contaId: string) => void;
  disabled?: boolean;
  placeholder?: string;
}

export function ContaSelect({
  planoId,
  empresaId,
  value,
  onChange,
  disabled,
  placeholder = 'Selecionar conta...',
}: ContaSelectProps) {
  const { data: arvore, isLoading } = useContasDoPlano(planoId);
  const [open, setOpen] = useState(false);
  const [busca, setBusca] = useState('');
  const [criando, setCriando] = useState(false);
  const qc = useQueryClient();

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

  const handleCriarPlano = async () => {
    setCriando(true);
    try {
      await planoContasService.criarPlanoPadrao(empresaId);
      await qc.invalidateQueries({ queryKey: ['planos', empresaId] });
      toast.success('Plano padrão criado com sucesso');
    } catch (err) {
      toast.error(getApiError(err));
    } finally {
      setCriando(false);
    }
  };

  if (isLoading) {
    return (
      <div className="input-base flex items-center gap-2 text-gray-400">
        <Loader2 className="h-4 w-4 animate-spin" />
        Carregando contas...
      </div>
    );
  }

  // Sem plano OU plano sem contas analíticas
  if (!planoId || contas.length === 0) {
    return (
      <button
        type="button"
        onClick={handleCriarPlano}
        disabled={criando || !empresaId}
        className={cn(
          'input-base flex items-center justify-center gap-2 border-dashed text-brand-600 hover:bg-brand-50',
          criando && 'opacity-60',
        )}
      >
        {criando ? (
          <>
            <Loader2 className="h-4 w-4 animate-spin" />
            Criando plano...
          </>
        ) : (
          <>
            <Plus className="h-4 w-4" />
            Criar plano de contas padrão
          </>
        )}
      </button>
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
                      <p className="text-xs text-gray-400">{c.natureza.toLowerCase()}</p>
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
