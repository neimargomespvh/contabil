import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean, IsEnum, IsOptional, IsString, IsUUID, MinLength, ValidateNested,
} from 'class-validator';

export enum FormatoDataEnum {
  DDMMYYYY = 'DD/MM/YYYY',
  YYYYMMDD = 'YYYY-MM-DD',
  DDMMYYYY_HIFEN = 'DD-MM-YYYY',
}

export class MapeamentoCsvDto {
  @ApiPropertyOptional({ default: ';' })
  @IsOptional()
  @IsString()
  separador?: string;

  @ApiProperty({ example: 'Data' })
  @IsString()
  data: string;

  @ApiProperty({ example: 'Descrição' })
  @IsString()
  descricao: string;

  @ApiProperty({ example: 'Valor' })
  @IsString()
  valor: string;

  @ApiPropertyOptional({ example: 'Documento' })
  @IsOptional()
  @IsString()
  documento?: string;

  @ApiPropertyOptional({ enum: FormatoDataEnum, default: FormatoDataEnum.DDMMYYYY })
  @IsOptional()
  @IsEnum(FormatoDataEnum)
  formatoData?: FormatoDataEnum;

  @ApiPropertyOptional({ default: true })
  @IsOptional()
  @IsBoolean()
  decimalVirgula?: boolean;
}

export class ImportarCsvDto {
  @ApiProperty()
  @IsUUID()
  contaBancariaId: string;

  @ApiProperty({ description: 'Conteúdo do arquivo CSV' })
  @IsString()
  @MinLength(10)
  conteudo: string;

  @ApiProperty({ type: MapeamentoCsvDto })
  @ValidateNested()
  @Type(() => MapeamentoCsvDto)
  mapeamento: MapeamentoCsvDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  conciliarAutomatico?: string;
}
