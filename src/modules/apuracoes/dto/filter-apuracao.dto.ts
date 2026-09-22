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
