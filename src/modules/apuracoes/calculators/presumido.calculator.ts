import { BadRequestException, Injectable } from '@nestjs/common';

export interface ResultadoPresumido {
  receitaBruta: number;
  irpj: { base: number; aliquota: number; valor: number; adicional: number };
  csll: { base: number; aliquota: number; valor: number };
  pis: { base: number; aliquota: number; valor: number };
  cofins: { base: number; aliquota: number; valor: number };
  iss?: { base: number; aliquota: number; valor: number };
  icms?: { base: number; aliquota: number; valor: number };
  total: number;
  alertas: string[];
}

@Injectable()
export class PresumidoCalculator {
  calcular(input: {
    receitaBruta: number;
    tipoAtividade: 'COMERCIO' | 'INDUSTRIA' | 'SERVICOS';
    aliquotaIss?: number;
    aliquotaIcms?: number;
    retencoes?: number;
  }): ResultadoPresumido {
    const { receitaBruta, tipoAtividade, aliquotaIss, aliquotaIcms, retencoes } = input;

    if (receitaBruta <= 0) {
      throw new BadRequestException('Receita bruta deve ser maior que zero');
    }

    const alertas: string[] = [];

    // Percentuais de presunção
    const percIRPJ = tipoAtividade === 'SERVICOS' ? 0.32 : 0.08;   // serviços 32%, comércio/indústria 8%
    const percCSLL = tipoAtividade === 'SERVICOS' ? 0.32 : 0.12;   // serviços 32%, comércio/indústria 12%

    // IRPJ
    const baseIRPJ = receitaBruta * percIRPJ;
    const irpjNormal = baseIRPJ * 0.15;
    const adicional = baseIRPJ > 20000 ? (baseIRPJ - 20000) * 0.10 : 0;
    const irpjTotal = irpjNormal + adicional;

    // CSLL
    const baseCSLL = receitaBruta * percCSLL;
    const csllTotal = baseCSLL * 0.09;

    // PIS/COFINS (regime cumulativo)
    const pisTotal = receitaBruta * 0.0065;
    const cofinsTotal = receitaBruta * 0.03;

    // ISS (se serviços)
    let iss: any = undefined;
    if (tipoAtividade === 'SERVICOS') {
      const aliq = (aliquotaIss ?? 5) / 100;
      if (aliq < 0.02 || aliq > 0.05) {
        alertas.push('Alíquota ISS fora do intervalo legal (2% a 5%)');
      }
      iss = { base: receitaBruta, aliquota: aliq * 100, valor: Number((receitaBruta * aliq).toFixed(2)) };
    }

    // ICMS (se comércio/indústria)
    let icms: any = undefined;
    if (tipoAtividade !== 'SERVICOS') {
      const aliq = (aliquotaIcms ?? 18) / 100;
      icms = { base: receitaBruta, aliquota: aliq * 100, valor: Number((receitaBruta * aliq).toFixed(2)) };
    }

    const totalBruto =
      irpjTotal + csllTotal + pisTotal + cofinsTotal + (iss?.valor ?? 0) + (icms?.valor ?? 0);
    const total = Math.max(0, totalBruto - (retencoes ?? 0));

    if (adicional > 0) {
      alertas.push('IRPJ adicional de 10% aplicado sobre base que excede R$ 20.000/mês');
    }

    return {
      receitaBruta,
      irpj: {
        base: Number(baseIRPJ.toFixed(2)),
        aliquota: 15,
        valor: Number(irpjNormal.toFixed(2)),
        adicional: Number(adicional.toFixed(2)),
      },
      csll: { base: Number(baseCSLL.toFixed(2)), aliquota: 9, valor: Number(csllTotal.toFixed(2)) },
      pis: { base: receitaBruta, aliquota: 0.65, valor: Number(pisTotal.toFixed(2)) },
      cofins: { base: receitaBruta, aliquota: 3, valor: Number(cofinsTotal.toFixed(2)) },
      iss,
      icms,
      total: Number(total.toFixed(2)),
      alertas,
    };
  }
}
