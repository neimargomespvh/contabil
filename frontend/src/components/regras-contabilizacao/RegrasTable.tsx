import { Edit2, Trash2, Power, PowerOff } from 'lucide-react';
import type { RegraContabilizacao } from '@/services/regras-contabilizacao.service';

interface Props {
  regras: RegraContabilizacao[];
  onEditar: (r: RegraContabilizacao) => void;
  onExcluir: (r: RegraContabilizacao) => void;
  onInativar: (r: RegraContabilizacao) => void;
  onReativar: (r: RegraContabilizacao) => void;
}

function renderCondicoes(condicao: any): string[] {
  if (!condicao || typeof condicao !== 'object') return [];
  const tags: string[] = [];
  if (condicao.tipo) tags.push(`Tipo: ${condicao.tipo}`);
  if (condicao.cfop) tags.push(`CFOP: ${condicao.cfop}`);
  if (condicao.cfopPrefix) tags.push(`CFOP~${condicao.cfopPrefix}*`);
  if (condicao.ncm) tags.push(`NCM: ${condicao.ncm}`);
  if (condicao.ncmPrefix) tags.push(`NCM~${condicao.ncmPrefix}*`);
  if (condicao.emitenteCnpj) tags.push(`Emit: ${condicao.emitenteCnpj}`);
  if (condicao.destinatarioCnpj) tags.push(`Dest: ${condicao.destinatarioCnpj}`);
  return tags;
}

export function RegrasTable({
  regras,
  onEditar,
  onExcluir,
  onInativar,
  onReativar,
}: Props) {
  if (regras.length === 0) {
    return (
      <div className="py-12 text-center text-sm text-gray-500">
        Nenhuma regra cadastrada.
      </div>
    );
  }

  return (
    <div className="overflow-x-auto">
      <table className="w-full text-sm">
        <thead className="border-b border-gray-200 text-left text-xs uppercase tracking-wide text-gray-500">
          <tr>
            <th className="px-3 py-2 w-16">Prior.</th>
            <th className="px-3 py-2">Nome</th>
            <th className="px-3 py-2">Condições</th>
            <th className="px-3 py-2">Débito → Crédito</th>
            <th className="px-3 py-2 w-24">Status</th>
            <th className="px-3 py-2 w-32 text-right">Ações</th>
          </tr>
        </thead>
        <tbody className="divide-y divide-gray-100">
          {regras.map((r) => {
            const tags = renderCondicoes(r.condicao);
            return (
              <tr key={r.id} className="hover:bg-gray-50">
                <td className="px-3 py-2">
                  <span className="inline-flex h-6 w-6 items-center justify-center rounded-full bg-gray-100 text-xs font-bold text-gray-700">
                    {r.prioridade}
                  </span>
                </td>
                <td className="px-3 py-2">
                  <p className="font-medium text-gray-900">{r.nome}</p>
                  {r.historicoTemplate && (
                    <p className="mt-0.5 font-mono text-[10px] text-gray-500">
                      {r.historicoTemplate}
                    </p>
                  )}
                </td>
                <td className="px-3 py-2">
                  <div className="flex flex-wrap gap-1">
                    {tags.length === 0 ? (
                      <span className="text-xs text-gray-400">—</span>
                    ) : (
                      tags.map((t, i) => (
                        <span
                          key={i}
                          className="rounded bg-blue-50 px-1.5 py-0.5 font-mono text-[10px] text-blue-700"
                        >
                          {t}
                        </span>
                      ))
                    )}
                  </div>
                </td>
                <td className="px-3 py-2">
                  <div className="flex flex-col text-xs">
                    <span className="font-mono text-blue-700">
                      D: {r.contaDebito?.codigo ?? '—'} {r.contaDebito?.nome ?? ''}
                    </span>
                    <span className="font-mono text-red-700">
                      C: {r.contaCredito?.codigo ?? '—'} {r.contaCredito?.nome ?? ''}
                    </span>
                  </div>
                </td>
                <td className="px-3 py-2">
                  <span
                    className={`inline-flex items-center rounded-full px-2 py-0.5 text-[10px] font-medium ${
                      r.status === 'ATIVO'
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-600'
                    }`}
                  >
                    {r.status}
                  </span>
                </td>
                <td className="px-3 py-2">
                  <div className="flex justify-end gap-1">
                    <button
                      type="button"
                      onClick={() => onEditar(r)}
                      className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-blue-600"
                      title="Editar"
                    >
                      <Edit2 className="h-4 w-4" />
                    </button>
                    {r.status === 'ATIVO' ? (
                      <button
                        type="button"
                        onClick={() => onInativar(r)}
                        className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-orange-600"
                        title="Inativar"
                      >
                        <PowerOff className="h-4 w-4" />
                      </button>
                    ) : (
                      <button
                        type="button"
                        onClick={() => onReativar(r)}
                        className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-green-600"
                        title="Reativar"
                      >
                        <Power className="h-4 w-4" />
                      </button>
                    )}
                    <button
                      type="button"
                      onClick={() => onExcluir(r)}
                      className="rounded p-1 text-gray-400 hover:bg-gray-100 hover:text-red-600"
                      title="Excluir"
                    >
                      <Trash2 className="h-4 w-4" />
                    </button>
                  </div>
                </td>
              </tr>
            );
          })}
        </tbody>
      </table>
    </div>
  );
}
