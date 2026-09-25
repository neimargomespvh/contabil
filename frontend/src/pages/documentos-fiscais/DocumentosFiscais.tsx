import { useState } from 'react';
import { Search, FileText, CheckCircle2, XCircle, AlertCircle } from 'lucide-react';
import { Card } from '@/components/ui/Card';
import { Input } from '@/components/ui/Input';
import { Button } from '@/components/ui/Button';
import { ConfirmDialog } from '@/components/ui/ConfirmDialog';
import { Spinner } from '@/components/ui/Spinner';
import { EmpresaSelect } from '@/components/common/EmpresaSelect';
import { UploadXmlCard } from '@/components/documentos-fiscais/UploadXmlCard';
import { DocumentosTable } from '@/components/documentos-fiscais/DocumentosTable';
import { DocumentoDetalheModal } from '@/components/documentos-fiscais/DocumentoDetalheModal';
import {
  useDocumentosFiscais,
  useEstatisticasDocumentos,
  useCancelarDocumento,
} from '@/hooks/useDocumentosFiscais';
import type {
  DocumentoFiscal,
  TipoDocumento,
  SituacaoDocumento,
} from '@/services/documentos-fiscais.service';

export function DocumentosFiscaisPage() {
  const [empresaId, setEmpresaId] = useState<string | null>(null);
  const [busca, setBusca] = useState('');
  const [tipo, setTipo] = useState<TipoDocumento | ''>('');
  const [situacao, setSituacao] = useState<SituacaoDocumento | ''>('');
  const [dataInicio, setDataInicio] = useState('');
  const [dataFim, setDataFim] = useState('');
  const [page, setPage] = useState(1);
  const limit = 20;

  const [detalhe, setDetalhe] = useState<DocumentoFiscal | null>(null);
  const [cancelando, setCancelando] = useState<DocumentoFiscal | null>(null);
  const [motivo, setMotivo] = useState('');

  const { data, isLoading } = useDocumentosFiscais({
    empresaId: empresaId ?? '',
    tipo: tipo || undefined,
    situacao: situacao || undefined,
    chaveAcesso: busca || undefined,
    dataInicio: dataInicio || undefined,
    dataFim: dataFim || undefined,
    page,
    limit,
  });

  const { data: stats } = useEstatisticasDocumentos(empresaId);
  const cancelar = useCancelarDocumento(empresaId ?? '');

  const handleCancelar = () => {
    if (!cancelando || motivo.length < 5) return;
    cancelar.mutate(
      { id: cancelando.id, motivo },
      {
        onSuccess: () => {
          setCancelando(null);
          setMotivo('');
        },
      },
    );
  };

  const totalPages = data?.meta?.totalPages ?? 0;

  return (
    <div className="space-y-6">
      <div>
        <h1 className="text-2xl font-bold text-gray-900">Documentos Fiscais</h1>
        <p className="mt-1 text-sm text-gray-500">
          Importe e gerencie XMLs de NFe, NFCe, CT-e e NFS-e
        </p>
      </div>

      <Card>
        <div className="grid grid-cols-1 gap-4 sm:grid-cols-2 lg:grid-cols-4">
          <div className="sm:col-span-2">
            <label className="mb-1 block text-sm font-medium text-gray-700">Empresa</label>
            <EmpresaSelect
              value={empresaId ?? ''}
              onChange={(v) => { setEmpresaId(v || null); setPage(1); }}
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Data início</label>
            <Input
              type="date"
              value={dataInicio}
              onChange={(e) => { setDataInicio(e.target.value); setPage(1); }}
            />
          </div>
          <div>
            <label className="mb-1 block text-sm font-medium text-gray-700">Data fim</label>
            <Input
              type="date"
              value={dataFim}
              onChange={(e) => { setDataFim(e.target.value); setPage(1); }}
            />
          </div>
        </div>
      </Card>

      {empresaId && (
        <Card>
          <h2 className="mb-3 text-sm font-semibold text-gray-700">Importar XMLs</h2>
          <UploadXmlCard empresaId={empresaId} />
        </Card>
      )}

      {stats && (
        <div className="grid grid-cols-2 gap-3 sm:grid-cols-4">
          <div className="rounded-lg border border-gray-200 bg-white p-4">
            <div className="flex items-center gap-2 text-gray-500">
              <FileText className="h-4 w-4" />
              <span className="text-xs uppercase">Total</span>
            </div>
            <p className="mt-1 text-2xl font-bold text-gray-900">{stats.total}</p>
          </div>
          <div className="rounded-lg border border-green-200 bg-green-50 p-4">
            <div className="flex items-center gap-2 text-green-600">
              <CheckCircle2 className="h-4 w-4" />
              <span className="text-xs uppercase">Autorizadas</span>
            </div>
            <p className="mt-1 text-2xl font-bold text-green-700">{stats.autorizadas}</p>
          </div>
          <div className="rounded-lg border border-red-200 bg-red-50 p-4">
            <div className="flex items-center gap-2 text-red-600">
              <XCircle className="h-4 w-4" />
              <span className="text-xs uppercase">Canceladas</span>
            </div>
            <p className="mt-1 text-2xl font-bold text-red-700">{stats.canceladas}</p>
          </div>
          <div className="rounded-lg border border-orange-200 bg-orange-50 p-4">
            <div className="flex items-center gap-2 text-orange-600">
              <AlertCircle className="h-4 w-4" />
              <span className="text-xs uppercase">Sem contabilização</span>
            </div>
            <p className="mt-1 text-2xl font-bold text-orange-700">
              {stats.semContabilizacao}
            </p>
          </div>
        </div>
      )}

      {empresaId && (
        <Card>
          <div className="mb-4 flex flex-col gap-3 sm:flex-row">
            <div className="relative flex-1">
              <Search className="absolute left-3 top-1/2 h-4 w-4 -translate-y-1/2 text-gray-400" />
              <Input
                value={busca}
                onChange={(e) => { setBusca(e.target.value); setPage(1); }}
                placeholder="Buscar por chave de acesso..."
                className="pl-9"
              />
            </div>
            <select
              className="input-base sm:w-40"
              value={tipo}
              onChange={(e) => { setTipo(e.target.value as any); setPage(1); }}
            >
              <option value="">Todos os tipos</option>
              <option value="NFE">NFe</option>
              <option value="NFCE">NFCe</option>
              <option value="CTE">CT-e</option>
              <option value="NFSE">NFS-e</option>
            </select>
            <select
              className="input-base sm:w-44"
              value={situacao}
              onChange={(e) => { setSituacao(e.target.value as any); setPage(1); }}
            >
              <option value="">Todas as situações</option>
              <option value="AUTORIZADA">Autorizada</option>
              <option value="CANCELADA">Cancelada</option>
              <option value="DENEGADA">Denegada</option>
              <option value="INUTILIZADA">Inutilizada</option>
            </select>
          </div>

          {isLoading ? (
            <div className="flex justify-center py-12">
              <Spinner />
            </div>
          ) : (
            <>
              <DocumentosTable
                documentos={data?.data ?? []}
                onVer={setDetalhe}
                onCancelar={setCancelarDoc}
              />

              {totalPages > 1 && (
                <div className="mt-4 flex items-center justify-between border-t border-gray-100 pt-4">
                  <p className="text-xs text-gray-500">
                    Página {page} de {totalPages} — {data?.meta?.total} documentos
                  </p>
                  <div className="flex gap-2">
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={page <= 1}
                      onClick={() => setPage((p) => p - 1)}
                    >
                      Anterior
                    </Button>
                    <Button
                      variant="outline"
                      size="sm"
                      disabled={page >= totalPages}
                      onClick={() => setPage((p) => p + 1)}
                    >
                      Próxima
                    </Button>
                  </div>
                </div>
              )}
            </>
          )}
        </Card>
      )}

      {!empresaId && (
        <Card>
          <div className="py-12 text-center text-sm text-gray-500">
            Selecione uma empresa para visualizar os documentos fiscais
          </div>
        </Card>
      )}

      <DocumentoDetalheModal
        isOpen={!!detalhe}
        onClose={() => setDetalhe(null)}
        documento={detalhe}
      />

      <ConfirmDialog
        isOpen={!!cancelando}
        onClose={() => { setCancelando(null); setMotivo(''); }}
        onConfirm={handleCancelar}
        title="Cancelar documento fiscal"
        message="Tem certeza que deseja cancelar este documento? Esta ação não afeta o XML original, apenas marca o registro como cancelado."
        confirmText="Cancelar documento"
        loading={cancelar.isPending}
      />
    </div>
  );

  function setCancelarDoc(doc: DocumentoFiscal) {
    setCancelando(doc);
    setMotivo('Cancelamento solicitado pelo usuário');
  }
}
