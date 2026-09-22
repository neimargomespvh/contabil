import { Link } from 'react-router-dom';
import { Button } from '@/components/ui/Button';

export function NotFoundPage() {
  return (
    <div className="flex min-h-[60vh] flex-col items-center justify-center">
      <p className="text-6xl font-bold text-gray-300">404</p>
      <h1 className="mt-4 text-2xl font-bold text-gray-900">Página não encontrada</h1>
      <p className="mt-2 text-sm text-gray-500">
        A página que você está procurando não existe.
      </p>
      <Link to="/" className="mt-6">
        <Button>Voltar ao início</Button>
      </Link>
    </div>
  );
}
