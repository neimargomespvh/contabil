import { useEmpresas } from '@/hooks/useEmpresas';

interface EmpresaSelectProps {
  value: string;
  onChange: (id: string) => void;
  disabled?: boolean;
  required?: boolean;
  className?: string;
}

export function EmpresaSelect({
  value,
  onChange,
  disabled,
  required,
  className,
}: EmpresaSelectProps) {
  // A API aceita no máximo 100 por página
  const { data, isLoading, error } = useEmpresas({ limit: 100, status: 'ATIVA' });

  if (error) {
    return (
      <select className={`input-base text-red-600 ${className ?? ''}`} disabled>
        <option>Erro ao carregar empresas</option>
      </select>
    );
  }

  const empresas = data?.data ?? [];

  return (
    <select
      className={`input-base ${className ?? ''}`}
      value={value}
      onChange={(e) => onChange(e.target.value)}
      disabled={disabled || isLoading}
      required={required}
    >
      <option value="">
        {isLoading
          ? 'Carregando...'
          : empresas.length === 0
            ? '— Nenhuma empresa ativa cadastrada —'
            : '— Selecione uma empresa —'}
      </option>
      {empresas.map((e) => (
        <option key={e.id} value={e.id}>
          {e.razaoSocial}
        </option>
      ))}
    </select>
  );
}
