import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString, IsUUID, MaxLength, MinLength } from 'class-validator';

export enum NaturezaContaEnum {
  ATIVO = 'ATIVO',
  PASSIVO = 'PASSIVO',
  PATRIMONIO_LIQUIDO = 'PATRIMONIO_LIQUIDO',
  RECEITA = 'RECEITA',
  DESPESA = 'DESPESA',
  CUSTO = 'CUSTO',
}

export enum TipoContaEnum {
  SINTETICA = 'SINTETICA',
  ANALITICA = 'ANALITICA',
}

export class CreateContaDto {
  @ApiProperty({ example: '1.1.1.01' })
  @IsString()
  @MinLength(1)
  @MaxLength(30)
  codigo: string;

  @ApiProperty()
  @IsString()
  @MinLength(2)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ enum: NaturezaContaEnum })
  @IsEnum(NaturezaContaEnum)
  natureza: NaturezaContaEnum;

  @ApiProperty({ enum: TipoContaEnum })
  @IsEnum(TipoContaEnum)
  tipo: TipoContaEnum;

  @ApiPropertyOptional({ description: 'ID da conta pai (opcional)' })
  @IsOptional()
  @IsUUID()
  contaPaiId?: string;

  @ApiPropertyOptional({ example: 'RECEITA_BRUTA' })
  @IsOptional()
  @IsString()
  @MaxLength(50)
  dreLinha?: string;
}
