import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsUUID } from 'class-validator';

export enum FormatoExportacaoEnum {
  JSON = 'JSON',
  PDF = 'PDF',
  EXCEL = 'EXCEL',
}

export class FilterRelatorioDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  empresaId?: string;

  @ApiPropertyOptional({ description: 'Data inicial (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataInicio?: string;

  @ApiPropertyOptional({ description: 'Data final (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataFim?: string;

  @ApiPropertyOptional({ enum: FormatoExportacaoEnum, default: 'JSON' })
  @IsOptional()
  @IsEnum(FormatoExportacaoEnum)
  formato?: FormatoExportacaoEnum;

  @ApiPropertyOptional({ description: 'Incluir contas com saldo zero', default: false })
  @IsOptional()
  incluirZeradas?: string;

  @ApiPropertyOptional({ description: 'Nível máximo de profundidade' })
  @IsOptional()
  nivel?: string;
}

export class ComparativoDto extends FilterRelatorioDto {
  @ApiPropertyOptional({ description: 'Data inicial do período anterior' })
  @IsOptional()
  @IsDateString()
  dataInicioAnterior?: string;

  @ApiPropertyOptional({ description: 'Data final do período anterior' })
  @IsOptional()
  @IsDateString()
  dataFimAnterior?: string;
}
