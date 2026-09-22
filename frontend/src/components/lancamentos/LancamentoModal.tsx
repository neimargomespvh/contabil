import { Modal } from '@/components/ui/Modal';
import { LancamentoForm } from './LancamentoForm';
import { useCriarLancamento } from '@/hooks/useLancamentos';
import type { CreateLancamentoPayload } from '@/types';

interface LancamentoModalProps {
  isOpen: boolean;
  onClose: () => void;
  empresaIdInicial?: string;
}

export function LancamentoModal({ isOpen, onClose, empresaIdInicial }: LancamentoModalProps) {
  const criar = useCriarLancamento();

  const handleSubmit = (payload: CreateLancamentoPayload) => {
    criar.mutate(payload, { onSuccess: onClose });
  };

  return (
    <Modal
      isOpen={isOpen}
      onClose={onClose}
      title="Novo Lançamento Contábil"
      size="xl"
    >
      <LancamentoForm
        onSubmit={handleSubmit}
        onCancel={onClose}
        loading={criar.isPending}
        empresaIdInicial={empresaIdInicial}
      />
    </Modal>
  );
}
