import type { SituacaoDocumento, TipoDocumento } from '@/services/documentos-fiscais.service';

const CORES_SITUACAO: Record<SituacaoDocumento, string> = {
  AUTORIZADA: 'bg-green-100 text-green-700 border-green-200',
  CANCELADA: 'bg-red-100 text-red-700 border-red-200',
  DENEGADA: 'bg-orange-100 text-orange-700 border-orange-200',
  INUTILIZADA: 'bg-gray-100 text-gray-700 border-gray-200',
};

const CORES_TIPO: Record<TipoDocumento, string> = {
  NFE: 'bg-blue-100 text-blue-700',
  NFCE: 'bg-cyan-100 text-cyan-700',
  CTE: 'bg-purple-100 text-purple-700',
  NFSE: 'bg-indigo-100 text-indigo-700',
};

export function DocumentoStatusBadge({ situacao }: { situacao: SituacaoDocumento }) {
  return (
    <span
      className={`inline-flex items-center rounded-full border px-2 py-0.5 text-[10px] font-medium uppercase tracking-wide ${CORES_SITUACAO[situacao]}`}
    >
      {situacao}
    </span>
  );
}

export function DocumentoTipoBadge({ tipo }: { tipo: TipoDocumento }) {
  return (
    <span
      className={`inline-flex items-center rounded px-1.5 py-0.5 text-[10px] font-bold ${CORES_TIPO[tipo]}`}
    >
      {tipo}
    </span>
  );
}
