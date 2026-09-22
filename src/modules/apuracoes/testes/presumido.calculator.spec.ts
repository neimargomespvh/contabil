import { PresumidoCalculator } from '../calculators/presumido.calculator';
import { BadRequestException } from '@nestjs/common';

describe('PresumidoCalculator', () => {
  const calc = new PresumidoCalculator();

  it('calcula serviços com presunção 32%', () => {
    const r = calc.calcular({ receitaBruta: 100000, tipoAtividade: 'SERVICOS' });
    expect(r.irpj.base).toBe(32000);
    expect(r.irpj.valor).toBe(4800);           // 32000 × 15%
    expect(r.irpj.adicional).toBe(1200);       // (32000-20000) × 10%
    expect(r.csll.valor).toBe(2880);           // 32000 × 9%
  });

  it('calcula comércio com presunção 8%', () => {
    const r = calc.calcular({ receitaBruta: 100000, tipoAtividade: 'COMERCIO' });
    expect(r.irpj.base).toBe(8000);
    expect(r.irpj.valor).toBe(1200);
    expect(r.irpj.adicional).toBe(0);
    expect(r.csll.base).toBe(12000);
    expect(r.csll.valor).toBe(1080);
  });

  it('não aplica adicional quando base ≤ R$ 20k', () => {
    const r = calc.calcular({ receitaBruta: 50000, tipoAtividade: 'COMERCIO' });
    expect(r.irpj.base).toBe(4000);
    expect(r.irpj.adicional).toBe(0);
  });

  it('inclui PIS/COFINS cumulativos', () => {
    const r = calc.calcular({ receitaBruta: 100000, tipoAtividade: 'SERVICOS' });
    expect(r.pis.valor).toBe(650);
    expect(r.cofins.valor).toBe(3000);
  });

  it('inclui ISS para serviços', () => {
    const r = calc.calcular({
      receitaBruta: 100000,
      tipoAtividade: 'SERVICOS',
      aliquotaIss: 5,
    });
    expect(r.iss?.valor).toBe(5000);
  });

  it('inclui ICMS para comércio', () => {
    const r = calc.calcular({
      receitaBruta: 100000,
      tipoAtividade: 'COMERCIO',
      aliquotaIcms: 18,
    });
    expect(r.icms?.valor).toBe(18000);
  });

  it('rejeita receita zero', () => {
    expect(() => calc.calcular({ receitaBruta: 0, tipoAtividade: 'SERVICOS' })).toThrow(
      BadRequestException,
    );
  });
});
