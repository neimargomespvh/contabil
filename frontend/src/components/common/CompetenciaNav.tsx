import { ChevronLeft, ChevronRight, Calendar } from 'lucide-react';
import { Button } from '@/components/ui/Button';

interface CompetenciaNavProps {
  competencia: string; // YYYY-MM-DD
  onChange: (nova: string) => void;
}

function formatarCompetencia(data: string): string {
  const [ano, mes] = data.split('-');
  const nome = new Date(parseInt(ano), parseInt(mes) - 1, 1).toLocaleDateString('pt-BR', {
    month: 'long',
    year: 'numeric',
  });
  return nome.charAt(0).toUpperCase() + nome.slice(1);
}

export function CompetenciaNav({ competencia, onChange }: CompetenciaNavProps) {
  const mudarMes = (delta: number) => {
    const [ano, mes] = competencia.split('-').map(Number);
    const d = new Date(ano, mes - 1 + delta, 1);
    const novo = `${d.getFullYear()}-${String(d.getMonth() + 1).padStart(2, '0')}-01`;
    onChange(novo);
  };

  return (
    <div className="flex items-center gap-2">
      <Button variant="outline" size="sm" onClick={() => mudarMes(-1)} title="Mês anterior">
        <ChevronLeft className="h-4 w-4" />
      </Button>

      <div className="flex items-center gap-2 rounded-md border border-gray-300 bg-white px-3 py-2">
        <Calendar className="h-4 w-4 text-gray-500" />
        <input
          type="month"
          value={competencia.slice(0, 7)}
          onChange={(e) => onChange(`${e.target.value}-01`)}
          className="border-0 bg-transparent text-sm font-medium text-gray-900 focus:outline-none"
        />
      </div>

      <Button variant="outline" size="sm" onClick={() => mudarMes(1)} title="Próximo mês">
        <ChevronRight className="h-4 w-4" />
      </Button>
    </div>
  );
}
