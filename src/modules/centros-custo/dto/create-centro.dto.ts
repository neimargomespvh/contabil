import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export class CreateCentroCustoDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ example: 'ADM' })
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  codigo: string;

  @ApiProperty({ example: 'Administrativo' })
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  nome: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  descricao?: string;
}
