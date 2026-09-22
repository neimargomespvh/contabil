import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export enum TipoDocumentoFiscalEnum {
  NFE = 'NFE',
  NFCE = 'NFCE',
  CTE = 'CTE',
  NFSE = 'NFSE',
}

export enum SituacaoDocumentoFiscalEnum {
  AUTORIZADA = 'AUTORIZADA',
  CANCELADA = 'CANCELADA',
  DENEGADA = 'DENEGADA',
  INUTILIZADA = 'INUTILIZADA',
}

export class FilterDocumentoDto extends PaginationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  empresaId?: string;

  @ApiPropertyOptional({ enum: TipoDocumentoFiscalEnum })
  @IsOptional()
  @IsEnum(TipoDocumentoFiscalEnum)
  tipo?: TipoDocumentoFiscalEnum;

  @ApiPropertyOptional({ enum: SituacaoDocumentoFiscalEnum })
  @IsOptional()
  @IsEnum(SituacaoDocumentoFiscalEnum)
  situacao?: SituacaoDocumentoFiscalEnum;

  @ApiPropertyOptional({ description: 'Chave de acesso (44 dígitos)' })
  @IsOptional()
  @IsString()
  chaveAcesso?: string;

  @ApiPropertyOptional({ description: 'CNPJ do emitente' })
  @IsOptional()
  @IsString()
  emitenteCnpj?: string;

  @ApiPropertyOptional({ description: 'Data inicial de emissão (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataInicio?: string;

  @ApiPropertyOptional({ description: 'Data final de emissão (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataFim?: string;

  @ApiPropertyOptional({
    description: 'Filtrar apenas documentos sem contabilização',
  })
  @IsOptional()
  @IsString()
  semContabilizacao?: string;
}
