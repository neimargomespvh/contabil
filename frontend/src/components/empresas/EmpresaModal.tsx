import { Modal } from '@/components/ui/Modal';
import { EmpresaForm } from './EmpresaForm';
import { useCriarEmpresa, useAtualizarEmpresa } from '@/hooks/useEmpresas';
import type { Empresa, CreateEmpresaPayload } from '@/types';

interface EmpresaModalProps {
  isOpen: boolean;
  onClose: () => void;
  empresa?: Empresa | null;
}

export function EmpresaModal({ isOpen, onClose, empresa }: EmpresaModalProps) {
  const criar = useCriarEmpresa();
  const atualizar = useAtualizarEmpresa();

  const handleSubmit = (payload: CreateEmpresaPayload) => {
    if (empresa) {
      atualizar.mutate(
        { id: empresa.id, payload },
        { onSuccess: onClose },
      );
    } else {
      criar.mutate(payload, { onSuccess: onClose });
    }
  };

  const loading = criar.isPending || atualizar.isPending;

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={empresa ? `Editar — ${empresa.razaoSocial}` : 'Nova Empresa'}
      size="lg"
    >
      <EmpresaForm
        empresa={empresa ?? undefined}
        onSubmit={handleSubmit}
        onCancel={onClose}
        loading={loading}
      />
    </Modal>
  );
}
