import { validarCnpj, limparCnpj, formatarCnpj } from '../cnpj.util';
import { validarCpf, limparCpf, formatarCpf } from '../cpf.util';

describe('Validação de CNPJ', () => {
  it('aceita CNPJ válido (sem máscara)', () => {
    expect(validarCnpj('11222333000181')).toBe(true);
  });

  it('aceita CNPJ válido (com máscara)', () => {
    expect(validarCnpj('11.222.333/0001-81')).toBe(true);
  });

  it('rejeita CNPJ com dígito verificador errado', () => {
    expect(validarCnpj('11222333000182')).toBe(false);
  });

  it('rejeita CNPJ com todos os dígitos iguais', () => {
    expect(validarCnpj('11111111111111')).toBe(false);
  });

  it('rejeita CNPJ com tamanho inválido', () => {
    expect(validarCnpj('123')).toBe(false);
  });

  it('limparCnpj remove máscara', () => {
    expect(limparCnpj('11.222.333/0001-81')).toBe('11222333000181');
  });

  it('formatarCnpj adiciona máscara', () => {
    expect(formatarCnpj('11222333000181')).toBe('11.222.333/0001-81');
  });
});

describe('Validação de CPF', () => {
  it('aceita CPF válido (sem máscara)', () => {
    expect(validarCpf('12345678909')).toBe(true);
  });

  it('aceita CPF válido (com máscara)', () => {
    expect(validarCpf('123.456.789-09')).toBe(true);
  });

  it('rejeita CPF com dígito verificador errado', () => {
    expect(validarCpf('12345678908')).toBe(false);
  });

  it('rejeita CPF com todos os dígitos iguais', () => {
    expect(validarCpf('11111111111')).toBe(false);
  });

  it('rejeita CPF com tamanho inválido', () => {
    expect(validarCpf('123')).toBe(false);
  });

  it('limparCpf remove máscara', () => {
    expect(limparCpf('123.456.789-09')).toBe('12345678909');
  });

  it('formatarCpf adiciona máscara', () => {
    expect(formatarCpf('12345678909')).toBe('123.456.789-09');
  });
});
