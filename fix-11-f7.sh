#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/modules/apuracoes/dto
mkdir -p src/modules/apuracoes/calculators
mkdir -p src/modules/apuracoes/guias
mkdir -p src/modules/apuracoes/testes

# ============================================================
# 1. INSTALAR PDFKIT
# ============================================================
echo "📦 Instalando pdfkit..."
npm install pdfkit --save
npm install @types/pdfkit --save-dev 2>/dev/null || true

# ============================================================
# 2. DTOs
# ============================================================
cat > src/modules/apuracoes/dto/calcular-apuracao.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsUUID, Min } from 'class-validator';

export enum RegimeTributarioEnum {
  SIMPLES = 'SIMPLES',
  PRESUMIDO = 'PRESUMIDO',
  REAL = 'REAL',
  MEI = 'MEI',
}

export enum AnexoSimplesEnum {
  I = 'I',
  II = 'II',
  III = 'III',
  IV = 'IV',
  V = 'V',
}

export enum TipoAtividadeEnum {
  COMERCIO = 'COMERCIO',
  INDUSTRIA = 'INDUSTRIA',
  SERVICOS = 'SERVICOS',
}

export class CalcularApuracaoDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Competência (YYYY-MM-DD, 1º dia do mês)' })
  @IsEnum({
    example: '2026-09-01',
  } as any)
  competencia: string;

  @ApiProperty({ enum: RegimeTributarioEnum })
  @IsEnum(RegimeTributarioEnum)
  regime: RegimeTributarioEnum;

  @ApiPropertyOptional({ enum: AnexoSimplesEnum })
  @IsOptional()
  @IsEnum(AnexoSimplesEnum)
  anexoSimples?: AnexoSimplesEnum;

  @ApiProperty({ description: 'Receita bruta do mês' })
  @IsNumber()
  @Min(0)
  receitaBruta: number;

  @ApiPropertyOptional({ description: 'Receita bruta acumulada dos últimos 12 meses' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  receitaBruta12Meses?: number;

  @ApiPropertyOptional({ description: 'Folha de pagamento 12 meses (para Fator R)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  folha12Meses?: number;

  @ApiPropertyOptional({ enum: TipoAtividadeEnum })
  @IsOptional()
  @IsEnum(TipoAtividadeEnum)
  tipoAtividade?: TipoAtividadeEnum;

  @ApiPropertyOptional({ description: 'Alíquota ISS (2 a 5%)', default: 5 })
  @IsOptional()
  @IsNumber()
  aliquotaIss?: number;

  @ApiPropertyOptional({ description: 'Alíquota ICMS (7 a 18%)', default: 18 })
  @IsOptional()
  @IsNumber()
  aliquotaIcms?: number;

  @ApiPropertyOptional({ description: 'Retenções sofridas (para dedução)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  retencoes?: number;
}
DTO_EOF

cat > src/modules/apuracoes/dto/filter-apuracao.dto.ts <<'DTO_EOF'
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsUUID } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';
import { RegimeTributarioEnum } from './calcular-apuracao.dto';

export class FilterApuracaoDto extends PaginationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  empresaId?: string;

  @ApiPropertyOptional({ enum: RegimeTributarioEnum })
  @IsOptional()
  @IsEnum(RegimeTributarioEnum)
  regime?: RegimeTributarioEnum;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  competenciaInicio?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  competenciaFim?: string;
}
DTO_EOF

# ============================================================
# 3. TABELAS SIMPLES NACIONAL (2026)
# ============================================================
cat > src/modules/apuracoes/calculators/tabelas-simples.ts <<'TABELAS_EOF'
export interface FaixaSimples {
  faixa: number;
  valorInicial: number;
  valorFinal: number;
  aliquota: number;         // alíquota nominal
  parcelaDeduzir: number;
  reparticao?: Record<string, number>; // % por tributo
}

export type TabelaAnexo = Record<string, FaixaSimples[]>;

/**
 * Tabelas do Simples Nacional vigentes em 2026.
 * Fonte: LC 123/2006, Anexos I a V, com atualizações.
 */
export const TABELAS_SIMPLES: Record<string, TabelaAnexo> = {
  I: {
    // Comércio
    '2026-01-01': [
      { faixa: 1, valorInicial: 0, valorFinal: 180000, aliquota: 0.04, parcelaDeduzir: 0,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 12.74, PIS: 2.76, CPP: 41.5, ICMS: 34 } },
      { faixa: 2, valorInicial: 180000.01, valorFinal: 360000, aliquota: 0.073, parcelaDeduzir: 5940,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 12.74, PIS: 2.76, CPP: 41.5, ICMS: 34 } },
      { faixa: 3, valorInicial: 360000.01, valorFinal: 720000, aliquota: 0.095, parcelaDeduzir: 13860,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 12.74, PIS: 2.76, CPP: 42, ICMS: 33.5 } },
      { faixa: 4, valorInicial: 720000.01, valorFinal: 1800000, aliquota: 0.107, parcelaDeduzir: 22500,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 12.74, PIS: 2.76, CPP: 42, ICMS: 33.5 } },
      { faixa: 5, valorInicial: 1800000.01, valorFinal: 3600000, aliquota: 0.143, parcelaDeduzir: 87300,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 12.74, PIS: 2.76, CPP: 42, ICMS: 33.5 } },
      { faixa: 6, valorInicial: 3600000.01, valorFinal: 4800000, aliquota: 0.19, parcelaDeduzir: 378000,
        reparticao: { IRPJ: 13.5, CSLL: 10, COFINS: 28.27, PIS: 6.13, CPP: 42.1, ICMS: 0 } },
    ],
  },
  II: {
    // Indústria
    '2026-01-01': [
      { faixa: 1, valorInicial: 0, valorFinal: 180000, aliquota: 0.045, parcelaDeduzir: 0,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 11.51, PIS: 2.49, CPP: 37.5, IPI: 7.5, ICMS: 32 } },
      { faixa: 2, valorInicial: 180000.01, valorFinal: 360000, aliquota: 0.078, parcelaDeduzir: 5940,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 11.51, PIS: 2.49, CPP: 37.5, IPI: 7.5, ICMS: 32 } },
      { faixa: 3, valorInicial: 360000.01, valorFinal: 720000, aliquota: 0.10, parcelaDeduzir: 13860,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 11.51, PIS: 2.49, CPP: 37.5, IPI: 7.5, ICMS: 32 } },
      { faixa: 4, valorInicial: 720000.01, valorFinal: 1800000, aliquota: 0.112, parcelaDeduzir: 22500,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 11.51, PIS: 2.49, CPP: 37.5, IPI: 7.5, ICMS: 32 } },
      { faixa: 5, valorInicial: 1800000.01, valorFinal: 3600000, aliquota: 0.147, parcelaDeduzir: 85500,
        reparticao: { IRPJ: 5.5, CSLL: 3.5, COFINS: 11.51, PIS: 2.49, CPP: 37.5, IPI: 7.5, ICMS: 32 } },
      { faixa: 6, valorInicial: 3600000.01, valorFinal: 4800000, aliquota: 0.30, parcelaDeduzir: 720000,
        reparticao: { IRPJ: 13.5, CSLL: 10, COFINS: 20.11, PIS: 4.36, CPP: 37.66, IPI: 14.37, ICMS: 0 } },
    ],
  },
  III: {
    // Serviços (locação, agência, etc.)
    '2026-01-01': [
      { faixa: 1, valorInicial: 0, valorFinal: 180000, aliquota: 0.06, parcelaDeduzir: 0,
        reparticao: { IRPJ: 4, CSLL: 3.5, COFINS: 12.82, PIS: 2.78, CPP: 43.4, ISS: 33.5 } },
      { faixa: 2, valorInicial: 180000.01, valorFinal: 360000, aliquota: 0.112, parcelaDeduzir: 9360,
        reparticao: { IRPJ: 4, CSLL: 3.5, COFINS: 14.05, PIS: 3.05, CPP: 43.4, ISS: 32 } },
      { faixa: 3, valorInicial: 360000.01, valorFinal: 720000, aliquota: 0.135, parcelaDeduzir: 17640,
        reparticao: { IRPJ: 4, CSLL: 3.5, COFINS: 13.64, PIS: 2.96, CPP: 43.4, ISS: 32.5 } },
      { faixa: 4, valorInicial: 720000.01, valorFinal: 1800000, aliquota: 0.16, parcelaDeduzir: 35640,
        reparticao: { IRPJ: 4, CSLL: 3.5, COFINS: 13.64, PIS: 2.96, CPP: 43.4, ISS: 32.5 } },
      { faixa: 5, valorInicial: 1800000.01, valorFinal: 3600000, aliquota: 0.21, parcelaDeduzir: 125640,
        reparticao: { IRPJ: 4, CSLL: 3.5, COFINS: 12.82, PIS: 2.78, CPP: 43.4, ISS: 33.5 } },
      { faixa: 6, valorInicial: 3600000.01, valorFinal: 4800000, aliquota: 0.33, parcelaDeduzir: 648000,
        reparticao: { IRPJ: 35.2, CSLL: 15.2, COFINS: 16.3, PIS: 3.5, CPP: 29.8, ISS: 0 } },
    ],
  },
  IV: {
    // Serviços (construção, vigilância, limpeza)
    '2026-01-01': [
      { faixa: 1, valorInicial: 0, valorFinal: 180000, aliquota: 0.045, parcelaDeduzir: 0,
        reparticao: { IRPJ: 18.8, CSLL: 15.2, COFINS: 17.67, PIS: 3.83, ISS: 44.5 } },
      { faixa: 2, valorInicial: 180000.01, valorFinal: 360000, aliquota: 0.09, parcelaDeduzir: 8100,
        reparticao: { IRPJ: 19.8, CSLL: 15.2, COFINS: 20.55, PIS: 4.45, ISS: 40 } },
      { faixa: 3, valorInicial: 360000.01, valorFinal: 720000, aliquota: 0.102, parcelaDeduzir: 12420,
        reparticao: { IRPJ: 20.8, CSLL: 15.2, COFINS: 19.73, PIS: 4.27, ISS: 40 } },
      { faixa: 4, valorInicial: 720000.01, valorFinal: 1800000, aliquota: 0.14, parcelaDeduzir: 39780,
        reparticao: { IRPJ: 17.8, CSLL: 19.2, COFINS: 20.55, PIS: 4.45, ISS: 38 } },
      { faixa: 5, valorInicial: 1800000.01, valorFinal: 3600000, aliquota: 0.22, parcelaDeduzir: 183780,
        reparticao: { IRPJ: 18.8, CSLL: 19.2, COFINS: 18.89, PIS: 4.11, ISS: 39 } },
      { faixa: 6, valorInicial: 3600000.01, valorFinal: 4800000, aliquota: 0.33, parcelaDeduzir: 828000,
        reparticao: { IRPJ: 53.5, CSLL: 21.5, COFINS: 20.55, PIS: 4.45, ISS: 0 } },
    ],
  },
  V: {
    // Serviços (auditoria, jornalismo, tecnologia, publicidade)
    '2026-01-01': [
      { faixa: 1, valorInicial: 0, valorFinal: 180000, aliquota: 0.155, parcelaDeduzir: 0,
        reparticao: { IRPJ: 25, CSLL: 15, COFINS: 14.1, PIS: 3.05, CPP: 28.85, ISS: 14 } },
      { faixa: 2, valorInicial: 180000.01, valorFinal: 360000, aliquota: 0.18, parcelaDeduzir: 4500,
        reparticao: { IRPJ: 23, CSLL: 15, COFINS: 14.1, PIS: 3.05, CPP: 27.85, ISS: 17 } },
      { faixa: 3, valorInicial: 360000.01, valorFinal: 720000, aliquota: 0.195, parcelaDeduzir: 9900,
        reparticao: { IRPJ: 24, CSLL: 15, COFINS: 14.92, PIS: 3.23, CPP: 23.85, ISS: 19 } },
      { faixa: 4, valorInicial: 720000.01, valorFinal: 1800000, aliquota: 0.205, parcelaDeduzir: 17100,
        reparticao: { IRPJ: 21, CSLL: 15, COFINS: 15.74, PIS: 3.41, CPP: 23.85, ISS: 21 } },
      { faixa: 5, valorInicial: 1800000.01, valorFinal: 3600000, aliquota: 0.23, parcelaDeduzir: 62100,
        reparticao: { IRPJ: 23, CSLL: 12.5, COFINS: 14.1, PIS: 3.05, CPP: 23.85, ISS: 23.5 } },
      { faixa: 6, valorInicial: 3600000.01, valorFinal: 4800000, aliquota: 0.305, parcelaDeduzir: 540000,
        reparticao: { IRPJ: 35, CSLL: 15.5, COFINS: 16.44, PIS: 3.56, CPP: 29.5, ISS: 0 } },
    ],
  },
};

/**
 * Encontra a faixa aplicável para uma RBT12.
 */
export function encontrarFaixa(anexo: string, rbt12: number): FaixaSimples | null {
  const tabela = TABELAS_SIMPLES[anexo]?.['2026-01-01'];
  if (!tabela) return null;
  return tabela.find((f) => rbt12 >= f.valorInicial && rbt12 <= f.valorFinal) ?? null;
}

/**
 * Sublimites do Simples Nacional.
 */
export const SUBLIMITE_ICMS_ISS = 3_600_000;   // R$ 3,6 mi
export const LIMITE_SIMPLES = 4_800_000;        // R$ 4,8 mi
export const LIMITE_MEI = 81_000;               // R$ 81 mil/ano
TABELAS_EOF

# ============================================================
# 4. CALCULADORA SIMPLES NACIONAL
# ============================================================
cat > src/modules/apuracoes/calculators/simples.calculator.ts <<'CALC_EOF'
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
CALC_EOF

# ============================================================
# 5. CALCULADORA LUCRO PRESUMIDO
# ============================================================
cat > src/modules/apuracoes/calculators/presumido.calculator.ts <<'CALC_EOF'
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
CALC_EOF

# ============================================================
# 6. CALCULADORA MEI
# ============================================================
cat > src/modules/apuracoes/calculators/mei.calculator.ts <<'CALC_EOF'
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
CALC_EOF

# ============================================================
# 7. GERADOR DE GUIAS (PDF)
# ============================================================
cat > src/modules/apuracoes/guias/guia.generator.ts <<'GUIA_EOF'
import { Injectable, Logger } from '@nestjs/common';
import PDFDocument from 'pdfkit';

export interface DadosGuia {
  tipo: 'DAS' | 'DARF' | 'GPS' | 'ISS';
  numeroDocumento?: string;
  razaoSocial: string;
  cnpj: string;
  periodoApuracao: string;
  vencimento: string;
  valor: number;
  codigoReceita?: string;
  descricao?: string;
  detalhes?: Record<string, string | number>;
}

@Injectable()
export class GuiaGenerator {
  private readonly logger = new Logger(GuiaGenerator.name);

  /**
   * Gera o PDF de uma guia. Retorna o Buffer.
   */
  async gerar(dados: DadosGuia): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({ size: 'A4', margin: 40 });
        const chunks: Buffer[] = [];

        doc.on('data', (c) => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        this.renderizar(doc, dados);

        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  private renderizar(doc: PDFKit.PDFDocument, dados: DadosGuia) {
    const largura = doc.page.width - 80;

    // Cabeçalho
    doc.rect(40, 40, largura, 50).fillAndStroke('#003366', '#003366');
    doc.fillColor('#FFFFFF').fontSize(18).text('DOCUMENTO DE ARRECADAÇÃO', 40, 55, {
      width: largura,
      align: 'center',
    });

    // Tipo
    doc.moveDown(3);
    doc.fillColor('#000000').fontSize(12);

    let y = 110;

    // Bloco 1 — Tipo e Identificação
    this.linha(doc, y, 'Tipo de Guia:', dados.tipo);
    y += 20;
    if (dados.numeroDocumento) {
      this.linha(doc, y, 'Nº do Documento:', dados.numeroDocumento);
      y += 20;
    }
    if (dados.codigoReceita) {
      this.linha(doc, y, 'Código de Receita:', dados.codigoReceita);
      y += 20;
    }

    y += 10;
    doc.moveTo(40, y).lineTo(40 + largura, y).stroke('#CCCCCC');
    y += 15;

    // Bloco 2 — Contribuinte
    doc.fontSize(14).fillColor('#003366').text('CONTRIBUINTE', 40, y);
    y += 25;

    doc.fontSize(11).fillColor('#000000');
    this.linha(doc, y, 'Razão Social:', dados.razaoSocial);
    y += 20;
    this.linha(doc, y, 'CNPJ:', this.formatarCnpj(dados.cnpj));
    y += 30;

    // Bloco 3 — Período / Valores
    doc.fontSize(14).fillColor('#003366').text('PERÍODO E VALORES', 40, y);
    y += 25;

    doc.fontSize(11).fillColor('#000000');
    this.linha(doc, y, 'Período de Apuração:', dados.periodoApuracao);
    y += 20;
    this.linha(doc, y, 'Data de Vencimento:', dados.vencimento);
    y += 20;

    // Valor em destaque
    y += 10;
    doc.rect(40, y, largura, 40).fillAndStroke('#F0F0F0', '#003366');
    doc.fillColor('#003366').fontSize(14).text('VALOR TOTAL A PAGAR:', 55, y + 12);
    doc.fontSize(18).text(this.formatarMoeda(dados.valor), 40, y + 10, {
      width: largura - 20,
      align: 'right',
    });
    y += 55;

    // Detalhes
    if (dados.detalhes && Object.keys(dados.detalhes).length > 0) {
      doc.fontSize(14).fillColor('#003366').text('DETALHAMENTO', 40, y);
      y += 25;

      doc.fontSize(10).fillColor('#000000');
      for (const [chave, valor] of Object.entries(dados.detalhes)) {
        this.linha(doc, y, `${chave}:`, String(valor));
        y += 18;
      }
    }

    // Descrição livre
    if (dados.descricao) {
      y += 15;
      doc.fontSize(10).fillColor('#666666').text(dados.descricao, 40, y, { width: largura });
    }

    // Rodapé
    const rodapeY = doc.page.height - 60;
    doc.fontSize(8).fillColor('#999999').text(
      `Documento gerado em ${new Date().toLocaleString('pt-BR')} — Sistema Contábil`,
      40,
      rodapeY,
      { width: largura, align: 'center' },
    );
  }

  private linha(doc: PDFKit.PDFDocument, y: number, label: string, valor: string) {
    doc.font('Helvetica-Bold').text(label, 45, y, { continued: false, width: 180 });
    doc.font('Helvetica').text(valor, 230, y, { width: doc.page.width - 270 });
  }

  private formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }

  private formatarCnpj(cnpj: string): string {
    const limpo = cnpj.replace(/\D/g, '');
    return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
  }
}
GUIA_EOF

# ============================================================
# 8. SERVIÇO PRINCIPAL
# ============================================================
cat > src/modules/apuracoes/apuracoes.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { S3Service } from '../../infra/s3/s3.service';
import { SimplesCalculator } from './calculators/simples.calculator';
import { PresumidoCalculator } from './calculators/presumido.calculator';
import { MeiCalculator } from './calculators/mei.calculator';
import { GuiaGenerator } from './guias/guia.generator';
import { CalcularApuracaoDto, RegimeTributarioEnum } from './dto/calcular-apuracao.dto';
import { FilterApuracaoDto } from './dto/filter-apuracao.dto';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class ApuracoesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
    private readonly simples: SimplesCalculator,
    private readonly presumido: PresumidoCalculator,
    private readonly mei: MeiCalculator,
    private readonly guiaGen: GuiaGenerator,
  ) {}

  async calcular(tenantId: string, dto: CalcularApuracaoDto) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: dto.empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    const competencia = new Date(dto.competencia);

    // Verificar se já existe apuração nessa competência
    const existente = await this.prisma.apuracao.findFirst({
      where: {
        tenantId,
        empresaId: dto.empresaId,
        competencia,
        regime: dto.regime as any,
      },
    });
    if (existente) {
      throw new ConflictException(
        `Já existe apuração para ${competencia.toISOString().slice(0, 10)} no regime ${dto.regime}`,
      );
    }

    // Rotear para calculadora correta
    let resultado: any;
    switch (dto.regime) {
      case RegimeTributarioEnum.SIMPLES:
        if (!dto.anexoSimples) {
          throw new BadRequestException('Anexo do Simples é obrigatório');
        }
        resultado = this.simples.calcular({
          receitaBruta: dto.receitaBruta,
          receitaBruta12Meses: dto.receitaBruta12Meses ?? dto.receitaBruta * 12,
          anexo: dto.anexoSimples,
          folha12Meses: dto.folha12Meses,
          retencoes: dto.retencoes,
        });
        break;

      case RegimeTributarioEnum.PRESUMIDO:
        resultado = this.presumido.calcular({
          receitaBruta: dto.receitaBruta,
          tipoAtividade: dto.tipoAtividade ?? 'SERVICOS',
          aliquotaIss: dto.aliquotaIss,
          aliquotaIcms: dto.aliquotaIcms,
          retencoes: dto.retencoes,
        });
        break;

      case RegimeTributarioEnum.MEI:
        resultado = this.mei.calcular({
          tipoAtividade: dto.tipoAtividade ?? 'COMERCIO',
          receitaAcumulada: dto.receitaBruta12Meses,
        });
        break;

      case RegimeTributarioEnum.REAL:
        throw new BadRequestException(
          'Regime Lucro Real será implementado em versão futura',
        );

      default:
        throw new BadRequestException('Regime tributário inválido');
    }

    // Persistir apuração
    const apuracao = await this.prisma.$transaction(async (tx) => {
      const valorAPagar = this.extrairValorAPagar(resultado);
      const baseCalculo = this.extrairBaseCalculo(resultado, dto.receitaBruta);

      const apuracaoCriada = await tx.apuracao.create({
        data: {
          tenantId,
          empresaId: dto.empresaId,
          competencia,
          regime: dto.regime as any,
          anexoSimples: dto.anexoSimples as any,
          receitaBruta: dto.receitaBruta,
          baseCalculo,
          aliquota: resultado.aliquotaEfetiva
            ? Number(resultado.aliquotaEfetiva) / 100
            : resultado.irpj?.aliquota
              ? Number(resultado.irpj.aliquota) / 100
              : null,
          valorDevido: this.extrairValorDevido(resultado),
          valorDeducao: resultado.valorDeducao ?? null,
          valorAPagar,
          status: 'CALCULADA',
        },
      });

      // Persistir impostos individuais
      const impostos = this.extrairImpostos(resultado);
      for (const imp of impostos) {
        await tx.apuracaoImposto.create({
          data: {
            tenantId,
            apuracaoId: apuracaoCriada.id,
            imposto: imp.imposto as any,
            baseCalculo: imp.base,
            aliquota: imp.aliquota ? imp.aliquota / 100 : null,
            valor: imp.valor,
          },
        });
      }

      return apuracaoCriada;
    });

    return {
      apuracao,
      detalhamento: resultado,
    };
  }

  async listar(tenantId: string, filtros: FilterApuracaoDto) {
    const where: Prisma.ApuracaoWhereInput = { tenantId };
    if (filtros.empresaId) where.empresaId = filtros.empresaId;
    if (filtros.regime) where.regime = filtros.regime as any;

    if (filtros.competenciaInicio || filtros.competenciaFim) {
      where.competencia = {};
      if (filtros.competenciaInicio) (where.competencia as any).gte = new Date(filtros.competenciaInicio);
      if (filtros.competenciaFim) (where.competencia as any).lte = new Date(filtros.competenciaFim);
    }

    const [total, data] = await Promise.all([
      this.prisma.apuracao.count({ where }),
      this.prisma.apuracao.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { competencia: filtros.order },
        include: {
          impostos: true,
          empresa: { select: { razaoSocial: true, cnpj: true } },
        },
      }),
    ]);

    return paginar(data, total, filtros.page, filtros.limit);
  }

  async buscarPorId(tenantId: string, id: string) {
    const apuracao = await this.prisma.apuracao.findFirst({
      where: { id, tenantId },
      include: {
        impostos: true,
        guias: true,
        empresa: { select: { id: true, razaoSocial: true, cnpj: true } },
      },
    });
    if (!apuracao) throw new NotFoundException('Apuração não encontrada');
    return apuracao;
  }

  async gerarGuia(tenantId: string, apuracaoId: string) {
    const apuracao = await this.buscarPorId(tenantId, apuracaoId);

    const tipoGuia = this.definirTipoGuia(apuracao.regime);
    const vencimento = this.calcularVencimento(apuracao.competencia, apuracao.regime);

    const dadosGuia = {
      tipo: tipoGuia,
      razaoSocial: apuracao.empresa.razaoSocial,
      cnpj: apuracao.empresa.cnpj,
      periodoApuracao: this.formatarCompetencia(apuracao.competencia),
      vencimento: vencimento.toLocaleDateString('pt-BR'),
      valor: Number(apuracao.valorAPagar),
      codigoReceita: this.codigoReceita(tipoGuia),
      detalhes: apuracao.impostos.reduce(
        (acc, i) => ({ ...acc, [i.imposto]: this.formatarMoeda(Number(i.valor)) }),
        {} as Record<string, string>,
      ),
    };

    // Gerar PDF
    const pdfBuffer = await this.guiaGen.gerar(dadosGuia);

    // Upload para S3
    const s3Key = `tenants/${tenantId}/guias/${apuracaoId}-${tipoGuia}.pdf`;
    await this.s3.upload(s3Key, pdfBuffer, 'application/pdf');

    // Persistir guia
    const guia = await this.prisma.guia.create({
      data: {
        tenantId,
        empresaId: apuracao.empresaId,
        apuracaoId: apuracao.id,
        tipo: tipoGuia as any,
        codigoReceita: dadosGuia.codigoReceita,
        periodoApuracao: apuracao.competencia,
        vencimento,
        valor: apuracao.valorAPagar,
        status: 'GERADA',
        pdfS3Key: s3Key,
      },
    });

    return {
      guia,
      url: await this.s3.presignedUrl(s3Key, 3600),
    };
  }

  async listarGuias(tenantId: string, empresaId?: string) {
    const where: any = { tenantId };
    if (empresaId) where.empresaId = empresaId;

    return this.prisma.guia.findMany({
      where,
      orderBy: { vencimento: 'desc' },
      include: { empresa: { select: { razaoSocial: true, cnpj: true } } },
      take: 100,
    });
  }

  async urlGuia(tenantId: string, guiaId: string) {
    const guia = await this.prisma.guia.findFirst({
      where: { id: guiaId, tenantId },
    });
    if (!guia || !guia.pdfS3Key) throw new NotFoundException('Guia não encontrada');

    return {
      url: await this.s3.presignedUrl(guia.pdfS3Key, 3600),
      guia,
    };
  }

  // ============================================================
  // Helpers
  // ============================================================

  private extrairValorAPagar(resultado: any): number {
    if (resultado.valorAPagar !== undefined) return resultado.valorAPagar;
    if (resultado.total !== undefined) return resultado.total;
    if (resultado.valorDas !== undefined) return resultado.valorDas;
    return 0;
  }

  private extrairValorDevido(resultado: any): number {
    if (resultado.valorDevido !== undefined) return resultado.valorDevido;
    if (resultado.total !== undefined) return resultado.total;
    if (resultado.valorDas !== undefined) return resultado.valorDas;
    return 0;
  }

  private extrairBaseCalculo(resultado: any, receitaBruta: number): number {
    if (resultado.rbt12) return resultado.rbt12;
    if (resultado.irpj?.base) return resultado.irpj.base;
    return receitaBruta;
  }

  private extrairImpostos(resultado: any): Array<{ imposto: string; base: number; aliquota?: number; valor: number }> {
    const impostos: Array<{ imposto: string; base: number; aliquota?: number; valor: number }> = [];

    // Simples: repartição
    if (resultado.valorPorTributo) {
      const mapa: Record<string, string> = {
        IRPJ: 'IRPJ',
        CSLL: 'CSLL',
        PIS: 'PIS',
        COFINS: 'COFINS',
        ISS: 'ISS',
        ICMS: 'ICMS',
        CPP: 'IRPJ', // CPP não tem enum próprio, usamos IRPJ
        IPI: 'IRPJ',
      };
      for (const [tributo, valor] of Object.entries(resultado.valorPorTributo)) {
        const impostoEnum = mapa[tributo];
        if (impostoEnum) {
          impostos.push({ imposto: impostoEnum, base: 0, valor: Number(valor) });
        }
      }
      return impostos;
    }

    // Presumido
    if (resultado.irpj) {
      impostos.push({ imposto: 'IRPJ', base: resultado.irpj.base, aliquota: 15, valor: resultado.irpj.valor + resultado.irpj.adicional });
    }
    if (resultado.csll) {
      impostos.push({ imposto: 'CSLL', base: resultado.csll.base, aliquota: 9, valor: resultado.csll.valor });
    }
    if (resultado.pis) {
      impostos.push({ imposto: 'PIS', base: resultado.pis.base, aliquota: 0.65, valor: resultado.pis.valor });
    }
    if (resultado.cofins) {
      impostos.push({ imposto: 'COFINS', base: resultado.cofins.base, aliquota: 3, valor: resultado.cofins.valor });
    }
    if (resultado.iss) {
      impostos.push({ imposto: 'ISS', base: resultado.iss.base, aliquota: resultado.iss.aliquota, valor: resultado.iss.valor });
    }
    if (resultado.icms) {
      impostos.push({ imposto: 'ICMS', base: resultado.icms.base, aliquota: resultado.icms.aliquota, valor: resultado.icms.valor });
    }

    // MEI
    if (resultado.valorDas !== undefined) {
      impostos.push({ imposto: 'DAS', base: 0, valor: resultado.valorDas });
    }

    return impostos;
  }

  private definirTipoGuia(regime: string): 'DAS' | 'DARF' {
    return regime === 'SIMPLES' || regime === 'MEI' ? 'DAS' : 'DARF';
  }

  private codigoReceita(tipo: 'DAS' | 'DARF'): string {
    return tipo === 'DAS' ? '1004' : '2089';
  }

  private calcularVencimento(competencia: Date, regime: string): Date {
    const proximoMes = new Date(competencia);
    proximoMes.setMonth(proximoMes.getMonth() + 1);

    if (regime === 'SIMPLES' || regime === 'MEI') {
      // DAS: dia 20 do mês seguinte
      return new Date(proximoMes.getFullYear(), proximoMes.getMonth(), 20);
    }

    // DARF: último dia do mês seguinte
    return new Date(proximoMes.getFullYear(), proximoMes.getMonth() + 1, 0);
  }

  private formatarCompetencia(data: Date): string {
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    return `${mes}/${data.getFullYear()}`;
  }

  private formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }
}
SERVICE_EOF

# ============================================================
# 9. CONTROLLER
# ============================================================
cat > src/modules/apuracoes/apuracoes.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Get, Param, ParseUUIDPipe, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { ApuracoesService } from './apuracoes.service';
import { CalcularApuracaoDto } from './dto/calcular-apuracao.dto';
import { FilterApuracaoDto } from './dto/filter-apuracao.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('apuracoes')
@ApiBearerAuth()
@Controller('apuracoes')
export class ApuracoesController {
  constructor(private readonly service: ApuracoesService) {}

  @Post('calcular')
  @RequirePermissions(PERMISSIONS.APURACAO_CALCULAR)
  @ApiOperation({ summary: 'Calcula apuração tributária' })
  calcular(@CurrentTenant() t: string, @Body() dto: CalcularApuracaoDto) {
    return this.service.calcular(t, dto);
  }

  @Get()
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  @ApiOperation({ summary: 'Lista apurações' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterApuracaoDto) {
    return this.service.listar(t, filtros);
  }

  @Get('guias')
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  @ApiOperation({ summary: 'Lista guias geradas' })
  listarGuias(
    @CurrentTenant() t: string,
    @Query('empresaId') empresaId?: string,
  ) {
    return this.service.listarGuias(t, empresaId);
  }

  @Get('guias/:id/url')
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  @ApiOperation({ summary: 'URL assinada do PDF da guia' })
  urlGuia(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.urlGuia(t, id);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.APURACAO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post(':id/gerar-guia')
  @RequirePermissions(PERMISSIONS.APURACAO_CALCULAR)
  @ApiOperation({ summary: 'Gera guia em PDF (DAS/DARF)' })
  gerarGuia(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.gerarGuia(t, id);
  }
}
CTRL_EOF

cat > src/modules/apuracoes/apuracoes.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { ApuracoesController } from './apuracoes.controller';
import { ApuracoesService } from './apuracoes.service';
import { SimplesCalculator } from './calculators/simples.calculator';
import { PresumidoCalculator } from './calculators/presumido.calculator';
import { MeiCalculator } from './calculators/mei.calculator';
import { GuiaGenerator } from './guias/guia.generator';

@Module({
  controllers: [ApuracoesController],
  providers: [
    ApuracoesService,
    SimplesCalculator,
    PresumidoCalculator,
    MeiCalculator,
    GuiaGenerator,
  ],
  exports: [ApuracoesService],
})
export class ApuracoesModule {}
MOD_EOF

# ============================================================
# 10. TESTES
# ============================================================
cat > src/modules/apuracoes/testes/simples.calculator.spec.ts <<'TEST_EOF'
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
TEST_EOF

cat > src/modules/apuracoes/testes/presumido.calculator.spec.ts <<'TEST_EOF'
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
TEST_EOF

cat > src/modules/apuracoes/testes/mei.calculator.spec.ts <<'TEST_EOF'
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
TEST_EOF

# ============================================================
# 11. REGISTRAR NO APP.MODULE
# ============================================================
python3 <<'PYEOF'
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'ApuracoesModule' not in content:
    content = content.replace(
        "import { ConciliacaoModule } from './modules/conciliacao/conciliacao.module';",
        "import { ConciliacaoModule } from './modules/conciliacao/conciliacao.module';\n"
        "import { ApuracoesModule } from './modules/apuracoes/apuracoes.module';"
    )
    content = content.replace(
        "    ConciliacaoModule,\n    HealthModule,",
        "    ConciliacaoModule,\n    ApuracoesModule,\n    HealthModule,"
    )
    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado com ApuracoesModule")
else:
    print("ℹ️  AppModule já contém ApuracoesModule")
PYEOF

echo ""
echo "✅ Pacote F7 instalado!"
echo ""
echo "Próximos passos:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"