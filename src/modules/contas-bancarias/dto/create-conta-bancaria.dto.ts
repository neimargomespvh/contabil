import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsString, IsUUID, MaxLength, Min } from 'class-validator';

export enum TipoContaBancariaEnum {
  CORRENTE = 'CORRENTE',
  POUPANCA = 'POUPANCA',
  INVESTIMENTO = 'INVESTIMENTO',
}

export class CreateContaBancariaDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Código COMPE do banco (ex: 341)' })
  @IsString()
  @MaxLength(10)
  bancoCodigo: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(20)
  agencia?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(30)
  numeroConta?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(5)
  digito?: string;

  @ApiPropertyOptional({ enum: TipoContaBancariaEnum, default: 'CORRENTE' })
  @IsOptional()
  @IsEnum(TipoContaBancariaEnum)
  tipo?: TipoContaBancariaEnum;

  @ApiPropertyOptional({ description: 'ID da conta contábil vinculada' })
  @IsOptional()
  @IsUUID()
  contaContabilId?: string;

  @ApiPropertyOptional({ default: 0 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  saldoInicial?: number;
}
