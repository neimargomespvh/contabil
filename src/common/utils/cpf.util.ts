/**
 * Valida CPF usando o algoritmo oficial dos dígitos verificadores.
 */
export function validarCpf(cpf: string): boolean {
  const limpo = cpf.replace(/\D/g, '');
  if (limpo.length !== 11) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcularDigito = (base: string): number => {
    const fator = base.length + 1;
    const soma = base
      .split('')
      .reduce((acc, d, i) => acc + parseInt(d, 10) * (fator - i), 0);
    const resto = (soma * 10) % 11;
    return resto === 10 ? 0 : resto;
  };

  const d1 = calcularDigito(limpo.slice(0, 9));
  const d2 = calcularDigito(limpo.slice(0, 10));

  return limpo === limpo.slice(0, 9) + d1 + d2;
}

export function limparCpf(cpf: string): string {
  return cpf.replace(/\D/g, '');
}

export function formatarCpf(cpf: string): string {
  const limpo = limparCpf(cpf);
  return limpo.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, '$1.$2.$3-$4');
}
