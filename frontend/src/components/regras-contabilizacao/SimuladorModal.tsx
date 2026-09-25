import { useState, useRef } from 'react';
import { Upload, CheckCircle2, XCircle, FileCode } from 'lucide-react';
import { Modal } from '@/components/ui/Modal';
import { Button } from '@/components/ui/Button';
import { useSimularRegra } from '@/hooks/useRegrasContabilizacao';
import type { SimulacaoResultado } from '@/services/regras-contabilizacao.service';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  empresaId: string;
}

export function SimuladorModal({ isOpen, onClose, empresaId }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [xml, setXml] = useState('');
  const [nomeArquivo, setNomeArquivo] = useState('');
  const [resultado, setResultado] = useState<SimulacaoResultado | null>(null);
  const simular = useSimularRegra(empresaId);

  const handleFile = (files: FileList | null) => {
    if (!files || files.length === 0) return;
    const file = files[0];
    const reader = new FileReader();
    reader.onload = (e) => {
      setXml((e.target?.result as string) ?? '');
      setNomeArquivo(file.name);
      setResultado(null);
    };
    reader.readAsText(file);
  };

  const executar = async () => {
    if (!xml.trim()) return;
    const r = await simular.mutateAsync(xml);
    setResultado(r);
  };

  const limpar = () => {
    setXml('');
    setNomeArquivo('');
    setResultado(null);
    simular.reset();
    if (inputRef.current) inputRef.current.value = '';
  };

  return (
    <Modal isOpen={isOpen} onClose={onClose} title="Simulador de Regras" size="xl">
      <div className="space-y-5">
        <p className="text-sm text-gray-600">
          Importe um XML para testar qual regra de contabilização seria aplicada, sem
          persistir nada no banco.
        </p>

        <div
          onClick={() => inputRef.current?.click()}
          className="flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed border-gray-300 bg-gray-50 px-6 py-6 transition-colors hover:border-gray-400 hover:bg-gray-100"
        >
          <Upload className="mb-2 h-6 w-6 text-gray-400" />
          <p className="text-sm font-medium text-gray-700">
            Clique para selecionar um XML
          </p>
          {nomeArquivo && (
            <p className="mt-1 flex items-center gap-1 text-xs text-blue-600">
              <FileCode className="h-3 w-3" />
              {nomeArquivo}
            </p>
          )}
          <input
            ref={inputRef}
            type="file"
            accept=".xml,application/xml,text/xml"
            className="hidden"
            onChange={(e) => handleFile(e.target.files)}
          />
        </div>

        {xml && (
          <div className="rounded-lg bg-gray-900 p-3">
            <pre className="max-h-32 overflow-auto text-[10px] text-gray-300">
              {xml.slice(0, 500)}
              {xml.length > 500 ? '...' : ''}
            </pre>
          </div>
        )}

        <div className="flex justify-end gap-2">
          <Button variant="outline" onClick={limpar} disabled={!xml}>
            Limpar
          </Button>
          <Button onClick={executar} loading={simular.isPending} disabled={!xml}>
            Simular
          </Button>
        </div>

        {resultado && (
          <div
            className={`rounded-lg border-2 p-4 ${
              resultado.casou
                ? 'border-green-200 bg-green-50'
                : 'border-orange-200 bg-orange-50'
            }`}
          >
            <div className="flex items-start gap-3">
              {resultado.casou ? (
                <CheckCircle2 className="h-5 w-5 shrink-0 text-green-600" />
              ) : (
                <XCircle className="h-5 w-5 shrink-0 text-orange-600" />
              )}
              <div className="flex-1 space-y-3">
                <div>
                  <h4
                    className={`font-semibold ${
                      resultado.casou ? 'text-green-900' : 'text-orange-900'
                    }`}
                  >
                    {resultado.casou
                      ? 'Regra encontrada!'
                      : 'Nenhuma regra aplicável'}
                  </h4>
                  {resultado.motivo && (
                    <p className="mt-0.5 text-xs text-orange-700">
                      {resultado.motivo}
                    </p>
                  )}
                </div>

                {resultado.documento && (
                  <div className="rounded bg-white/70 p-3 text-xs">
                    <p className="mb-1 font-semibold text-gray-700">
                      Documento parseado:
                    </p>
                    <div className="grid grid-cols-2 gap-x-4 gap-y-0.5 text-gray-700">
                      <span>Tipo:</span>
                      <span className="font-mono">{resultado.documento.tipo}</span>
                      <span>CFOP:</span>
                      <span className="font-mono">{resultado.documento.cfop ?? '—'}</span>
                      <span>NCM:</span>
                      <span className="font-mono">{resultado.documento.ncm ?? '—'}</span>
                      <span>Emitente:</span>
                      <span className="font-mono">{resultado.documento.emitenteCnpj}</span>
                    </div>
                  </div>
                )}

                {resultado.casou && resultado.regra && (
                  <div className="rounded bg-white/70 p-3 text-xs">
                    <p className="mb-1 font-semibold text-gray-700">
                      Regra aplicada:
                    </p>
                    <div className="grid grid-cols-2 gap-x-4 gap-y-0.5 text-gray-700">
                      <span>Nome:</span>
                      <span className="font-medium">{resultado.regra.nome}</span>
                      <span>Prioridade:</span>
                      <span className="font-mono">{resultado.regra.prioridade}</span>
                      <span>Débito:</span>
                      <span className="font-mono text-blue-700">
                        {resultado.regra.contaDebito.codigo} — {resultado.regra.contaDebito.nome}
                      </span>
                      <span>Crédito:</span>
                      <span className="font-mono text-red-700">
                        {resultado.regra.contaCredito.codigo} — {resultado.regra.contaCredito.nome}
                      </span>
                    </div>
                    {resultado.historicoPreview && (
                      <div className="mt-2 rounded bg-gray-50 p-2">
                        <p className="text-[10px] uppercase text-gray-500">
                          Histórico gerado:
                        </p>
                        <p className="mt-0.5 font-mono text-xs text-gray-800">
                          {resultado.historicoPreview}
                        </p>
                      </div>
                    )}
                  </div>
                )}
              </div>
            </div>
          </div>
        )}
      </div>
    </Modal>
  );
}
