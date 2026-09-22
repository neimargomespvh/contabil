export function validarCnpj(cnpj: string): boolean {
  const limpo = cnpj.replace(/\D/g, '');
  if (limpo.length !== 14) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcular = (base: string, pesos: number[]): number => {
    const soma = base.split('').reduce((acc, d, i) => acc + parseInt(d, 10) * pesos[i], 0);
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };

  const p1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const p2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  const d1 = calcular(limpo.slice(0, 12), p1);
  const d2 = calcular(limpo.slice(0, 13), p2);

  return limpo === limpo.slice(0, 12) + d1 + d2;
}

export function validarCpf(cpf: string): boolean {
  const limpo = cpf.replace(/\D/g, '');
  if (limpo.length !== 11) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcular = (base: string): number => {
    const fator = base.length + 1;
    const soma = base.split('').reduce((acc, d, i) => acc + parseInt(d, 10) * (fator - i), 0);
    const resto = (soma * 10) % 11;
    return resto === 10 ? 0 : resto;
  };

  const d1 = calcular(limpo.slice(0, 9));
  const d2 = calcular(limpo.slice(0, 10));

  return limpo === limpo.slice(0, 9) + d1 + d2;
}

export function mascararCnpj(v: string): string {
  const limpo = v.replace(/\D/g, '').slice(0, 14);
  return limpo
    .replace(/^(\d{2})(\d)/, '$1.$2')
    .replace(/^(\d{2})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1/$2')
    .replace(/(\d{4})(\d)/, '$1-$2');
}

export function mascararCpf(v: string): string {
  const limpo = v.replace(/\D/g, '').slice(0, 11);
  return limpo
    .replace(/^(\d{3})(\d)/, '$1.$2')
    .replace(/^(\d{3})\.(\d{3})(\d)/, '$1.$2.$3')
    .replace(/\.(\d{3})(\d)/, '.$1-$2');
}

export function mascararCep(v: string): string {
  const limpo = v.replace(/\D/g, '').slice(0, 8);
  return limpo.replace(/^(\d{5})(\d)/, '$1-$2');
}
