import { MeiCalculator } from '../calculators/mei.calculator';

describe('MeiCalculator', () => {
  const calc = new MeiCalculator();

  it('calcula DAS de comércio (INSS + ICMS)', () => {
    const r = calc.calcular({ tipoAtividade: 'COMERCIO' });
    expect(r.valorDas).toBe(76.90); // 75.90 + 1.00
  });

  it('calcula DAS de serviços (INSS + ISS)', () => {
    const r = calc.calcular({ tipoAtividade: 'SERVICOS' });
    expect(r.valorDas).toBe(80.90); // 75.90 + 5.00
  });

  it('calcula DAS misto (INSS + ICMS + ISS)', () => {
    const r = calc.calcular({ tipoAtividade: 'MISTO' });
    expect(r.valorDas).toBe(81.90); // 75.90 + 1.00 + 5.00
  });

  it('emite alerta ao exceder limite', () => {
    const r = calc.calcular({ tipoAtividade: 'COMERCIO', receitaAcumulada: 90000 });
    expect(r.alertas.some((a) => a.includes('excede'))).toBe(true);
  });

  it('emite aviso próximo do limite', () => {
    const r = calc.calcular({ tipoAtividade: 'COMERCIO', receitaAcumulada: 70000 });
    expect(r.alertas.some((a) => a.includes('Atenção'))).toBe(true);
  });
});
