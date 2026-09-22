import { SimplesCalculator } from '../calculators/simples.calculator';
import { BadRequestException } from '@nestjs/common';

describe('SimplesCalculator', () => {
  const calc = new SimplesCalculator();

  it('calcula faixa 1 do Anexo I (comércio)', () => {
    const r = calc.calcular({
      receitaBruta: 10000,
      receitaBruta12Meses: 120000,
      anexo: 'I',
    });
    expect(r.anexo).toBe('I');
    expect(r.faixa).toBe(1);
    expect(r.aliquotaEfetiva).toBeCloseTo(4, 2);
    expect(r.valorDevido).toBeCloseTo(400, 2);
  });

  it('calcula faixa 2 do Anexo I com dedução', () => {
    const r = calc.calcular({
      receitaBruta: 20000,
      receitaBruta12Meses: 240000,
      anexo: 'I',
    });
    expect(r.faixa).toBe(2);
    expect(r.valorDeducao).toBe(5940);
    // Alíquota efetiva = ((240000 × 0.073) - 5940) / 240000 = 0.048275 = 4.8275%
    expect(r.aliquotaEfetiva).toBeCloseTo(4.83, 1);
  });

  it('aplica Fator R ≥ 28% → Anexo III', () => {
    const r = calc.calcular({
      receitaBruta: 20000,
      receitaBruta12Meses: 240000,
      anexo: 'V',
      folha12Meses: 80000, // 33%
    });
    expect(r.anexo).toBe('III');
    expect(r.fatorR).toBeCloseTo(33.33, 1);
  });

  it('aplica Fator R < 28% → Anexo V', () => {
    const r = calc.calcular({
      receitaBruta: 20000,
      receitaBruta12Meses: 240000,
      anexo: 'III',
      folha12Meses: 40000, // 16.67%
    });
    expect(r.anexo).toBe('V');
    expect(r.fatorR).toBeCloseTo(16.67, 1);
  });

  it('emite alerta ao ultrapassar sublimite', () => {
    const r = calc.calcular({
      receitaBruta: 400000,
      receitaBruta12Meses: 4000000,
      anexo: 'I',
    });
    expect(r.sublimiteExcedido).toBe(true);
    expect(r.alertas.some((a) => a.includes('sublimite'))).toBe(true);
  });

  it('rejeita receita bruta negativa', () => {
    expect(() =>
      calc.calcular({ receitaBruta: -100, receitaBruta12Meses: 120000, anexo: 'I' }),
    ).toThrow(BadRequestException);
  });

  it('reparte tributos corretamente no Anexo I', () => {
    const r = calc.calcular({
      receitaBruta: 100000,
      receitaBruta12Meses: 1200000,
      anexo: 'I',
    });
    expect(r.valorPorTributo.IRPJ).toBeDefined();
    expect(r.valorPorTributo.ICMS).toBeDefined();
    expect(r.valorPorTributo.COFINS).toBeDefined();
  });
});
