import { ChaveInvalidaError } from '../parsers/interfaces';

export class ChaveNfeValidator {
  /**
   * Valida chave de acesso de 44 dígitos com dígito verificador (módulo 11).
   * Formato: cUF(2) + AAMM(4) + CNPJ(14) + mod(2) + serie(3) + nNF(9) + tpEmis(1) + cNF(8) + cDV(1)
   */
  static validar(chave: string): void {
    if (!chave) throw new ChaveInvalidaError(chave);
    if (!/^\d{44}$/.test(chave)) {
      throw new ChaveInvalidaError(chave);
    }

    const dv = parseInt(chave.charAt(43), 10);
    const base = chave.substring(0, 43);
    const dvCalculado = this.calcularDv(base);

    if (dv !== dvCalculado) {
      throw new ChaveInvalidaError(chave);
    }
  }

  private static calcularDv(base: string): number {
    const pesos = [2, 3, 4, 5, 6, 7, 8, 9];
    let soma = 0;
    let pesoIdx = 0;

    for (let i = base.length - 1; i >= 0; i--) {
      soma += parseInt(base.charAt(i), 10) * pesos[pesoIdx];
      pesoIdx = (pesoIdx + 1) % pesos.length;
    }

    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  }

  static extrairCnpj(chave: string): string {
    return chave.substring(6, 20);
  }

  static extrairModelo(chave: string): string {
    return chave.substring(20, 22);
  }
}