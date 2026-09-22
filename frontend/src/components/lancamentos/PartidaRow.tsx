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
  empresaId: string;
  centros: CentroCusto[];
  onChange: (partida: PartidaForm) => void;
  onRemove: () => void;
  showRemove: boolean;
}

export function PartidaRow({
  partida,
  planoId,
  empresaId,
  centros,
  onChange,
  onRemove,
  showRemove,
}: PartidaRowProps) {
  return (
    <div className="grid grid-cols-12 items-start gap-2">
      <div className="col-span-12 lg:col-span-5">
        <ContaSelect
          planoId={planoId}
          empresaId={empresaId}
          value={partida.contaId}
          onChange={(contaId) => onChange({ ...partida, contaId })}
        />
      </div>

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
