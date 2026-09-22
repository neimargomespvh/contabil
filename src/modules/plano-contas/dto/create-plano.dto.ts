import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreatePlanoDto {
  @ApiProperty({ example: 'Plano 2026' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ description: 'Data de início da vigência (YYYY-MM-DD)' })
  @IsDateString()
  vigenciaInicio: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  vigenciaFim?: string;
}
