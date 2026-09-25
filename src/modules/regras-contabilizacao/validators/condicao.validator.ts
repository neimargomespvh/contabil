import { BadRequestException, Injectable } from '@nestjs/common';

const CAMPOS_PERMITIDOS = [
  'cfop',
  'cfopPrefix',
  'ncm',
  'ncmPrefix',
  'emitenteCnpj',
  'tipo',
  'destinatarioCnpj',
] as const;

const TIPOS_VALIDOS = ['NFE', 'NFCE', 'CTE', 'NFSE'] as const;

@Injectable()
export class CondicaoValidator {
  validar(condicao: Record<string, any>): void {
    if (!condicao || typeof condicao !== 'object') {
      throw new BadRequestException('Condição deve ser um objeto JSON');
    }

    const chaves = Object.keys(condicao);
    if (chaves.length === 0) {
      throw new BadRequestException(
        'Condição deve ter ao menos um critério (ex: cfop, ncm)',
      );
    }

    for (const chave of chaves) {
      if (!CAMPOS_PERMITIDOS.includes(chave as any)) {
        throw new BadRequestException(
          `Campo "${chave}" não é permitido. Permitidos: ${CAMPOS_PERMITIDOS.join(', ')}`,
        );
      }
    }

    if (condicao.cfop && !/^\d{4}$/.test(String(condicao.cfop))) {
      throw new BadRequestException('CFOP deve ter 4 dígitos');
    }

    if (condicao.cfopPrefix && !/^\d{1,3}$/.test(String(condicao.cfopPrefix))) {
      throw new BadRequestException('cfopPrefix deve ter 1 a 3 dígitos');
    }

    if (condicao.ncm && !/^\d{8}$/.test(String(condicao.ncm))) {
      throw new BadRequestException('NCM deve ter 8 dígitos');
    }

    if (condicao.ncmPrefix && !/^\d{1,7}$/.test(String(condicao.ncmPrefix))) {
      throw new BadRequestException('ncmPrefix deve ter 1 a 7 dígitos');
    }

    if (
      condicao.emitenteCnpj &&
      !/^\d{14}$/.test(String(condicao.emitenteCnpj))
    ) {
      throw new BadRequestException('emitenteCnpj deve ter 14 dígitos');
    }

    if (
      condicao.destinatarioCnpj &&
      !/^\d{14}$/.test(String(condicao.destinatarioCnpj))
    ) {
      throw new BadRequestException('destinatarioCnpj deve ter 14 dígitos');
    }

    if (condicao.tipo && !TIPOS_VALIDOS.includes(condicao.tipo)) {
      throw new BadRequestException(
        `Tipo inválido. Use: ${TIPOS_VALIDOS.join(', ')}`,
      );
    }
  }
}
