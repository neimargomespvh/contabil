import { Modal } from '@/components/ui/Modal';
import { RegraForm } from './RegraForm';
import type {
  RegraContabilizacao,
  CreateRegraPayload,
} from '@/services/regras-contabilizacao.service';

interface Props {
  isOpen: boolean;
  onClose: () => void;
  empresaId: string;
  regra?: RegraContabilizacao | null;
  onSubmit: (payload: CreateRegraPayload) => void;
  loading?: boolean;
}

export function RegraModal({
  isOpen,
  onClose,
  empresaId,
  regra,
  onSubmit,
  loading,
}: Props) {
  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title={regra ? 'Editar regra' : 'Nova regra de contabilização'}
      size="xl"
    >
      <RegraForm
        empresaId={empresaId}
        regra={regra}
        onSubmit={onSubmit}
        onCancel={onClose}
        loading={loading}
      />
    </Modal>
  );
}
