import { BadRequestException, Injectable } from '@nestjs/common';
import {
  TABELAS_SIMPLES,
  encontrarFaixa,
  LIMITE_SIMPLES,
  SUBLIMITE_ICMS_ISS,
} from './tabelas-simples';

export interface ResultadoSimples {
  anexo: string;
  anexoOriginal: string;
  rbt12: number;
  faixa: number;
  aliquotaNominal: number;
  aliquotaEfetiva: number;
  valorDevido: number;
  valorDeducao: number;
  valorAPagar: number;
  fatorR?: number;
  sublimiteExcedido: boolean;
  limiteExcedido: boolean;
  reparticao: Record<string, number>;
  valorPorTributo: Record<string, number>;
  alertas: string[];
}

@Injectable()
export class SimplesCalculator {
  calcular(input: {
    receitaBruta: number;
    receitaBruta12Meses: number;
    anexo: string;
    folha12Meses?: number;
    retencoes?: number;
  }): ResultadoSimples {
    const { receitaBruta, receitaBruta12Meses: rbt12, anexo, folha12Meses, retencoes } = input;

    if (receitaBruta <= 0) {
      throw new BadRequestException('Receita bruta deve ser maior que zero');
    }
    if (rbt12 < 0) {
      throw new BadRequestException('RBT12 inválida');
    }

    const alertas: string[] = [];

    // 1. Verificar limites
    const limiteExcedido = rbt12 > LIMITE_SIMPLES;
    const sublimiteExcedido = rbt12 > SUBLIMITE_ICMS_ISS;

    if (limiteExcedido) {
      alertas.push(
        `RBT12 (R$ ${rbt12.toFixed(2)}) excede o limite do Simples (R$ ${LIMITE_SIMPLES.toFixed(2)}). Empresa deve migrar para Lucro Presumido/Real.`,
      );
    }
    if (sublimiteExcedido && !limiteExcedido) {
      alertas.push(
        `RBT12 (R$ ${rbt12.toFixed(2)}) excede o sublimite de ICMS/ISS (R$ ${SUBLIMITE_ICMS_ISS.toFixed(2)}). ICMS/ISS serão recolhidos fora do DAS.`,
      );
    }

    // 2. Fator R (aplica em Anexo III e V)
    let anexoEfetivo = anexo;
    let fatorR: number | undefined;

    if (anexo === 'III' || anexo === 'V') {
      if (folha12Meses !== undefined && rbt12 > 0) {
        fatorR = folha12Meses / rbt12;
        if (fatorR < 0.28) {
          anexoEfetivo = 'V';
          if (anexo === 'III') {
            alertas.push(
              `Fator R = ${(fatorR * 100).toFixed(2)}% < 28%. Recolhimento migrado para Anexo V.`,
            );
          }
        } else {
          anexoEfetivo = 'III';
          if (anexo === 'V') {
            alertas.push(
              `Fator R = ${(fatorR * 100).toFixed(2)}% ≥ 28%. Recolhimento migrado para Anexo III.`,
            );
          }
        }
      } else {
        alertas.push('Fator R não calculado — folha dos últimos 12 meses não informada.');
      }
    }

    // 3. Encontrar faixa
    const faixa = encontrarFaixa(anexoEfetivo, rbt12);
    if (!faixa) {
      throw new BadRequestException(
        `Nenhuma faixa encontrada para anexo ${anexoEfetivo} com RBT12 R$ ${rbt12}`,
      );
    }

    // 4. Cálculo
    const aliquotaNominal = faixa.aliquota;
    const valorDeducao = faixa.parcelaDeduzir;

    // Alíquota efetiva = ((RBT12 × AliqNominal) - PD) / RBT12
    const aliquotaEfetiva = rbt12 > 0
      ? ((rbt12 * aliquotaNominal) - valorDeducao) / rbt12
      : aliquotaNominal;

    const valorDevido = receitaBruta * aliquotaEfetiva;
    const valorAPagar = Math.max(0, valorDevido - (retencoes ?? 0));

    // 5. Repartição por tributo
    const reparticao = faixa.reparticao ?? {};
    const valorPorTributo: Record<string, number> = {};
    for (const [tributo, percentual] of Object.entries(reparticao)) {
      valorPorTributo[tributo] = Number(((valorDevido * percentual) / 100).toFixed(2));
    }

    return {
      anexo: anexoEfetivo,
      anexoOriginal: anexo,
      rbt12,
      faixa: faixa.faixa,
      aliquotaNominal: Number((aliquotaNominal * 100).toFixed(4)),
      aliquotaEfetiva: Number((aliquotaEfetiva * 100).toFixed(4)),
      valorDevido: Number(valorDevido.toFixed(2)),
      valorDeducao,
      valorAPagar: Number(valorAPagar.toFixed(2)),
      fatorR: fatorR !== undefined ? Number((fatorR * 100).toFixed(4)) : undefined,
      sublimiteExcedido,
      limiteExcedido,
      reparticao,
      valorPorTributo,
      alertas,
    };
  }
}
