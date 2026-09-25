import { useState } from 'react';
import {
  ChevronRight,
  ChevronDown,
  Folder,
  FileText,
  Edit2,
  Trash2,
  Plus,
} from 'lucide-react';
import type { ContaArvore } from '@/types';

interface Props {
  contas: ContaArvore[];
  onEditar: (conta: ContaArvore) => void;
  onExcluir: (conta: ContaArvore) => void;
  onAdicionarFilha: (contaPai: ContaArvore) => void;
}

interface NodeProps {
  conta: ContaArvore;
  nivel: number;
  onEditar: (conta: ContaArvore) => void;
  onExcluir: (conta: ContaArvore) => void;
  onAdicionarFilha: (contaPai: ContaArvore) => void;
}

const CORES: Record<string, string> = {
  ATIVO: 'text-blue-700 bg-blue-50 border-blue-200',
  PASSIVO: 'text-red-700 bg-red-50 border-red-200',
  PATRIMONIO_LIQUIDO: 'text-purple-700 bg-purple-50 border-purple-200',
  RECEITA: 'text-green-700 bg-green-50 border-green-200',
  DESPESA: 'text-orange-700 bg-orange-50 border-orange-200',
  CUSTO: 'text-yellow-700 bg-yellow-50 border-yellow-200',
};

function ContaNode({ conta, nivel, onEditar, onExcluir, onAdicionarFilha }: NodeProps) {
  const [aberto, setAberto] = useState(nivel < 2);
  const temFilhas = conta.filhas && conta.filhas.length > 0;

  return (
    <div>
      <div
        className="group flex items-center gap-2 rounded-md py-1.5 pr-2 hover:bg-gray-50"
        style={{ paddingLeft: `${nivel * 20 + 8}px` }}
      >
        <button
          type="button"
          onClick={() => setAberto(!aberto)}
          className="flex h-5 w-5 shrink-0 items-center justify-center rounded text-gray-400 hover:bg-gray-200 hover:text-gray-700"
          disabled={!temFilhas}
        >
          {temFilhas ? (
            aberto ? (
              <ChevronDown className="h-4 w-4" />
            ) : (
              <ChevronRight className="h-4 w-4" />
            )
          ) : (
            <span className="h-1 w-1 rounded-full bg-gray-300" />
          )}
        </button>

        {conta.tipo === 'SINTETICA' ? (
          <Folder className="h-4 w-4 shrink-0 text-gray-500" />
        ) : (
          <FileText className="h-4 w-4 shrink-0 text-gray-400" />
        )}

        <span className="shrink-0 font-mono text-xs text-gray-500">
          {conta.codigo}
        </span>
        <span className="flex-1 truncate text-sm text-gray-800">{conta.nome}</span>

        {conta.tipo === 'ANALITICA' && (
          <span
            className={`shrink-0 rounded border px-1.5 py-0.5 text-[10px] font-medium ${
              CORES[conta.natureza] ?? 'bg-gray-100 text-gray-700'
            }`}
          >
            {conta.natureza}
          </span>
        )}

        {conta.dreLinha && (
          <span className="shrink-0 rounded bg-indigo-50 px-1.5 py-0.5 text-[10px] font-medium text-indigo-700">
            {conta.dreLinha}
          </span>
        )}

        <div className="flex shrink-0 gap-1 opacity-0 transition-opacity group-hover:opacity-100">
          {conta.tipo === 'SINTETICA' && (
            <button
              type="button"
              onClick={() => onAdicionarFilha(conta)}
              className="rounded p-1 text-gray-400 hover:bg-gray-200 hover:text-blue-600"
              title="Adicionar subconta"
            >
              <Plus className="h-3.5 w-3.5" />
            </button>
          )}
          <button
            type="button"
            onClick={() => onEditar(conta)}
            className="rounded p-1 text-gray-400 hover:bg-gray-200 hover:text-blue-600"
            title="Editar"
          >
            <Edit2 className="h-3.5 w-3.5" />
          </button>
          <button
            type="button"
            onClick={() => onExcluir(conta)}
            className="rounded p-1 text-gray-400 hover:bg-gray-200 hover:text-red-600"
            title="Excluir"
          >
            <Trash2 className="h-3.5 w-3.5" />
          </button>
        </div>
      </div>

      {aberto && temFilhas && (
        <div>
          {conta.filhas!.map((filha) => (
            <ContaNode
              key={filha.id}
              conta={filha}
              nivel={nivel + 1}
              onEditar={onEditar}
              onExcluir={onExcluir}
              onAdicionarFilha={onAdicionarFilha}
            />
          ))}
        </div>
      )}
    </div>
  );
}

export function ContaTree({ contas, onEditar, onExcluir, onAdicionarFilha }: Props) {
  if (!contas || contas.length === 0) {
    return (
      <div className="py-12 text-center text-sm text-gray-500">
        Nenhuma conta cadastrada.
      </div>
    );
  }

  return (
    <div className="divide-y divide-gray-100">
      {contas.map((conta) => (
        <ContaNode
          key={conta.id}
          conta={conta}
          nivel={0}
          onEditar={onEditar}
          onExcluir={onExcluir}
          onAdicionarFilha={onAdicionarFilha}
        />
      ))}
    </div>
  );
}
