import { BadRequestException, Injectable } from '@nestjs/common';
import { LIMITE_MEI } from './tabelas-simples';

export interface ResultadoMei {
  tipoAtividade: 'COMERCIO' | 'SERVICOS' | 'MISTO';
  valorDas: number;
  composicao: { inss: number; icms?: number; iss?: number };
  receitaAcumulada: number;
  limiteAnual: number;
  proximoLimite: number;
  alertas: string[];
}

const VALOR_INSS_2026 = 75.90;
const VALOR_ICMS_2026 = 1.00;
const VALOR_ISS_2026 = 5.00;

@Injectable()
export class MeiCalculator {
  calcular(input: {
    tipoAtividade: 'COMERCIO' | 'SERVICOS' | 'MISTO';
    receitaAcumulada?: number;
  }): ResultadoMei {
    const { tipoAtividade, receitaAcumulada = 0 } = input;
    const alertas: string[] = [];

    if (receitaAcumulada < 0) {
      throw new BadRequestException('Receita acumulada inválida');
    }

    const inss = VALOR_INSS_2026;
    let icms: number | undefined;
    let iss: number | undefined;

    if (tipoAtividade === 'COMERCIO' || tipoAtividade === 'MISTO') icms = VALOR_ICMS_2026;
    if (tipoAtividade === 'SERVICOS' || tipoAtividade === 'MISTO') iss = VALOR_ISS_2026;

    const valorDas = inss + (icms ?? 0) + (iss ?? 0);
    const proximoLimite = LIMITE_MEI - receitaAcumulada;

    if (receitaAcumulada > LIMITE_MEI) {
      alertas.push(
        `Receita acumulada (R$ ${receitaAcumulada.toFixed(2)}) excede o limite do MEI (R$ ${LIMITE_MEI.toFixed(2)}). Desenquadramento obrigatório.`,
      );
    } else if (receitaAcumulada > LIMITE_MEI * 0.8) {
      alertas.push(
        `Atenção: você já utilizou ${((receitaAcumulada / LIMITE_MEI) * 100).toFixed(1)}% do limite anual do MEI.`,
      );
    }

    return {
      tipoAtividade,
      valorDas: Number(valorDas.toFixed(2)),
      composicao: {
        inss,
        icms,
        iss,
      },
      receitaAcumulada,
      limiteAnual: LIMITE_MEI,
      proximoLimite: Number(proximoLimite.toFixed(2)),
      alertas,
    };
  }
}
