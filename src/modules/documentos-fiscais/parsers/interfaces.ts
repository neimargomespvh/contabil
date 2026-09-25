export type TipoDocumento = 'NFE' | 'NFCE' | 'CTE' | 'NFSE';
export type SituacaoDocumento = 'AUTORIZADA' | 'CANCELADA' | 'DENEGADA' | 'INUTILIZADA';

export interface DocumentoFiscalParseado {
  tipo: TipoDocumento;
  chaveAcesso: string;
  numero: string;
  serie: string;
  modelo: string;
  emitenteCnpj: string;
  emitenteNome: string;
  destinatarioCnpj?: string;
  destinatarioNome?: string;
  dataEmissao: Date;
  valorTotal: number;
  valorIcms?: number;
  valorPis?: number;
  valorCofins?: number;
  valorIss?: number;
  cfopPrincipal?: string;
  ncmPrincipal?: string;
  situacao: SituacaoDocumento;
  itens: ItemDocumentoParseado[];
  xmlRaw: string;
}

export interface ItemDocumentoParseado {
  numeroItem: number;
  codigoProduto?: string;
  descricao?: string;
  ncm?: string;
  cfop?: string;
  quantidade?: number;
  valorUnitario?: number;
  valorTotal?: number;
  valorIcms?: number;
  aliquotaIcms?: number;
  valorPis?: number;
  valorCofins?: number;
}

export class XmlMalformadoError extends Error {
  constructor(message = 'XML malformado') {
    super(message);
    this.name = 'XmlMalformadoError';
  }
}

export class DocumentoDuplicadoError extends Error {
  constructor(chave: string) {
    super(`Chave ${chave} já importada`);
    this.name = 'DocumentoDuplicadoError';
  }
}

export class SchemaInvalidoError extends Error {
  constructor(message = 'Schema inválido') {
    super(message);
    this.name = 'SchemaInvalidoError';
  }
}

export class CamposObrigatoriosError extends Error {
  constructor(campos: string[]) {
    super(`Campos obrigatórios faltantes: ${campos.join(', ')}`);
    this.name = 'CamposObrigatoriosError';
  }
}

export class ChaveInvalidaError extends Error {
  constructor(chave: string) {
    super(`Chave de acesso inválida: ${chave}`);
    this.name = 'ChaveInvalidaError';
  }
}