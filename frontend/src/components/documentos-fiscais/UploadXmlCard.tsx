import { useRef, useState } from 'react';
import { Upload, FileCode, X } from 'lucide-react';
import { Button } from '@/components/ui/Button';
import { useUploadXml, useUploadLote } from '@/hooks/useDocumentosFiscais';

interface Props {
  empresaId: string;
}

export function UploadXmlCard({ empresaId }: Props) {
  const inputRef = useRef<HTMLInputElement>(null);
  const [selecionados, setSelecionados] = useState<File[]>([]);
  const [arrastando, setArrastando] = useState(false);

  const upload1 = useUploadXml(empresaId);
  const uploadLote = useUploadLote(empresaId);
  const enviando = upload1.isPending || uploadLote.isPending;

  const handleFiles = (files: FileList | null) => {
    if (!files) return;
    const validos = Array.from(files).filter(
      (f) => f.name.endsWith('.xml') || f.type === 'text/xml' || f.type === 'application/xml',
    );
    if (validos.length === 0) {
      alert('Selecione arquivos .xml');
      return;
    }
    setSelecionados((prev) => [...prev, ...validos]);
  };

  const handleDrop = (e: React.DragEvent) => {
    e.preventDefault();
    setArrastando(false);
    handleFiles(e.dataTransfer.files);
  };

  const remover = (idx: number) => {
    setSelecionados((prev) => prev.filter((_, i) => i !== idx));
  };

  const enviar = async () => {
    if (selecionados.length === 0) return;

    if (selecionados.length === 1) {
      await upload1.mutateAsync(selecionados[0]);
    } else {
      await uploadLote.mutateAsync(selecionados);
    }

    setSelecionados([]);
    if (inputRef.current) inputRef.current.value = '';
  };

  return (
    <div className="space-y-3">
      <div
        onDragOver={(e) => { e.preventDefault(); setArrastando(true); }}
        onDragLeave={() => setArrastando(false)}
        onDrop={handleDrop}
        onClick={() => inputRef.current?.click()}
        className={`flex cursor-pointer flex-col items-center justify-center rounded-lg border-2 border-dashed px-6 py-8 transition-colors ${
          arrastando
            ? 'border-brand-500 bg-brand-50'
            : 'border-gray-300 bg-gray-50 hover:border-gray-400 hover:bg-gray-100'
        }`}
      >
        <Upload className="mb-2 h-8 w-8 text-gray-400" />
        <p className="text-sm font-medium text-gray-700">
          Arraste arquivos XML ou clique para selecionar
        </p>
        <p className="mt-1 text-xs text-gray-500">
          NFe, NFCe, CT-e ou NFS-e — até 100 arquivos
        </p>
        <input
          ref={inputRef}
          type="file"
          multiple
          accept=".xml,application/xml,text/xml"
          className="hidden"
          onChange={(e) => handleFiles(e.target.files)}
        />
      </div>

      {selecionados.length > 0 && (
        <div className="rounded-md border border-gray-200 bg-white">
          <div className="flex items-center justify-between border-b border-gray-100 px-3 py-2">
            <span className="text-xs font-medium text-gray-600">
              {selecionados.length} arquivo{selecionados.length !== 1 ? 's' : ''} selecionado{selecionados.length !== 1 ? 's' : ''}
            </span>
            <button
              type="button"
              onClick={() => setSelecionados([])}
              className="text-xs text-gray-500 hover:text-red-600"
              disabled={enviando}
            >
              Limpar
            </button>
          </div>

          <ul className="max-h-48 overflow-y-auto divide-y divide-gray-100">
            {selecionados.map((f, idx) => (
              <li key={idx} className="flex items-center gap-2 px-3 py-1.5">
                <FileCode className="h-4 w-4 shrink-0 text-gray-400" />
                <span className="flex-1 truncate text-xs text-gray-700">{f.name}</span>
                <span className="shrink-0 text-[10px] text-gray-400">
                  {(f.size / 1024).toFixed(1)} KB
                </span>
                <button
                  type="button"
                  onClick={() => remover(idx)}
                  className="rounded p-0.5 text-gray-400 hover:bg-gray-100 hover:text-red-600"
                  disabled={enviando}
                >
                  <X className="h-3.5 w-3.5" />
                </button>
              </li>
            ))}
          </ul>

          <div className="flex justify-end border-t border-gray-100 px-3 py-2">
            <Button onClick={enviar} loading={enviando} size="sm">
              Importar {selecionados.length === 1 ? 'XML' : `${selecionados.length} XMLs`}
            </Button>
          </div>
        </div>
      )}
    </div>
  );
}
