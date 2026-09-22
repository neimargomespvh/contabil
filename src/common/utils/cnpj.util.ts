/**
 * Valida CNPJ usando o algoritmo oficial dos dígitos verificadores.
 */
export function validarCnpj(cnpj: string): boolean {
  const limpo = cnpj.replace(/\D/g, '');
  if (limpo.length !== 14) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcularDigito = (base: string, pesos: number[]): number => {
    const soma = base.split('').reduce((acc, d, i) => acc + parseInt(d, 10) * pesos[i], 0);
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };

  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  const d1 = calcularDigito(limpo.slice(0, 12), pesos1);
  const d2 = calcularDigito(limpo.slice(0, 13), pesos2);

  return limpo === limpo.slice(0, 12) + d1 + d2;
}

export function limparCnpj(cnpj: string): string {
  return cnpj.replace(/\D/g, '');
}

export function formatarCnpj(cnpj: string): string {
  const limpo = limparCnpj(cnpj);
  return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
}
