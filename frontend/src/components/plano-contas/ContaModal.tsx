import { Modal } from '@/components/ui/Modal';
import { ContaForm } from './ContaForm';
import type { ContaArvore } from '@/types';
import type { CreateContaPayload } from '@/services/plano-contas.service';

interface Props {
  open: boolean;
  onClose: () => void;
  conta?: ContaArvore | null;
  contaPai?: ContaArvore | null;
  onSubmit: (payload: CreateContaPayload) => void;
  loading?: boolean;
}

export function ContaModal({ open, onClose, conta, contaPai, onSubmit, loading }: Props) {
  const titulo = conta ? 'Editar conta' : contaPai ? 'Nova subconta' : 'Nova conta';

  return (
    <Modal isOpen={open} onClose={onClose} title={titulo} size="lg">
      <ContaForm
        conta={conta}
        contaPai={contaPai}
        onSubmit={onSubmit}
        onCancel={onClose}
        loading={loading}
      />
    </Modal>
  );
}
