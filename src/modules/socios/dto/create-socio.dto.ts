import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString, IsNumber, IsOptional, IsString, IsUUID,
  Length, Max, MaxLength, Min, MinLength,
} from 'class-validator';

export class CreateSocioDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ example: 'João Silva' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ example: '12345678909' })
  @IsString()
  @Length(11, 11)
  cpf: string;

  @ApiProperty({ description: 'Percentual de participação (0 a 100)', example: 50 })
  @IsNumber()
  @Min(0.000001)
  @Max(100)
  participacao: number;

  @ApiPropertyOptional({ example: 5000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  proLabore?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataEntrada?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataSaida?: string;
}
