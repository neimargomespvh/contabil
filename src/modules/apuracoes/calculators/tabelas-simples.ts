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
