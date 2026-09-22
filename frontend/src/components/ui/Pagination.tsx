import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button } from './Button';

interface PaginationProps {
  page: number;
  totalPages: number;
  total: number;
  limit: number;
  onChange: (page: number) => void;
}

export function Pagination({ page, totalPages, total, limit, onChange }: PaginationProps) {
  if (totalPages <= 1) return null;

  const inicio = (page - 1) * limit + 1;
  const fim = Math.min(page * limit, total);

  return (
    <div className="flex flex-col items-center justify-between gap-4 sm:flex-row">
      <p className="text-sm text-gray-600">
        Mostrando <span className="font-medium">{inicio}</span> a{' '}
        <span className="font-medium">{fim}</span> de{' '}
        <span className="font-medium">{total}</span> resultados
      </p>

      <div className="flex items-center gap-2">
        <Button
          variant="outline"
          size="sm"
          disabled={page <= 1}
          onClick={() => onChange(page - 1)}
        >
          <ChevronLeft className="h-4 w-4" />
          Anterior
        </Button>

        <span className="px-3 text-sm text-gray-600">
          Página <span className="font-medium">{page}</span> de{' '}
          <span className="font-medium">{totalPages}</span>
        </span>

        <Button
          variant="outline"
          size="sm"
          disabled={page >= totalPages}
          onClick={() => onChange(page + 1)}
        >
          Próxima
          <ChevronRight className="h-4 w-4" />
        </Button>
      </div>
    </div>
  );
}
