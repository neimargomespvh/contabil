import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsBooleanString, IsDateString, IsOptional, IsUUID } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export class FilterExtratoDto extends PaginationDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  contaBancariaId?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataInicio?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataFim?: string;

  @ApiPropertyOptional({ description: 'Filtrar por status de conciliação (true/false)' })
  @IsOptional()
  @IsBooleanString()
  conciliado?: string;
}
