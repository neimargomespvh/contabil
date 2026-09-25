import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUUID } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';

export enum StatusRegraEnum {
  ATIVO = 'ATIVO',
  INATIVO = 'INATIVO',
}

export class FilterRegraDto extends PaginationDto {
  @ApiProperty({ description: 'ID da empresa' })
  @IsUUID()
  empresaId: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  nome?: string;

  @ApiPropertyOptional({ enum: StatusRegraEnum })
  @IsOptional()
  @IsEnum(StatusRegraEnum)
  status?: StatusRegraEnum;

  @ApiPropertyOptional({ description: 'CFOP específico' })
  @IsOptional()
  @IsString()
  cfop?: string;

  @ApiPropertyOptional({ description: 'NCM específico' })
  @IsOptional()
  @IsString()
  ncm?: string;
}
