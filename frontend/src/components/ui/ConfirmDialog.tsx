import { AlertTriangle } from 'lucide-react';
import { Modal } from './Modal';
import { Button } from './Button';

interface ConfirmDialogProps {
  isOpen: boolean;
  onClose: () => void;
  onConfirm: () => void;
  title: string;
  message: string;
  confirmText?: string;
  variant?: 'danger' | 'primary';
  loading?: boolean;
}

export function ConfirmDialog({
  isOpen,
  onClose,
  onConfirm,
  title,
  message,
  confirmText = 'Confirmar',
  variant = 'danger',
  loading,
}: ConfirmDialogProps) {
  return (
    <Modal isOpen={isOpen} onClose={onClose} title={title} size="sm">
      <div className="flex gap-4">
        <div
          className={`flex h-10 w-10 flex-shrink-0 items-center justify-center rounded-full ${
            variant === 'danger' ? 'bg-red-100' : 'bg-blue-100'
          }`}
        >
          <AlertTriangle
            className={`h-5 w-5 ${variant === 'danger' ? 'text-red-600' : 'text-blue-600'}`}
          />
        </div>
        <p className="flex-1 pt-2 text-sm text-gray-700">{message}</p>
      </div>
      <div className="mt-6 flex justify-end gap-2">
        <Button variant="outline" onClick={onClose} disabled={loading}>
          Cancelar
        </Button>
        <Button
          variant={variant === 'danger' ? 'danger' : 'primary'}
          onClick={onConfirm}
          loading={loading}
        >
          {confirmText}
        </Button>
      </div>
    </Modal>
  );
}
