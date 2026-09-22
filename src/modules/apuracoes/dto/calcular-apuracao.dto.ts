import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsNumber, IsOptional, IsUUID, Min } from 'class-validator';

export enum RegimeTributarioEnum {
  SIMPLES = 'SIMPLES',
  PRESUMIDO = 'PRESUMIDO',
  REAL = 'REAL',
  MEI = 'MEI',
}

export enum AnexoSimplesEnum {
  I = 'I',
  II = 'II',
  III = 'III',
  IV = 'IV',
  V = 'V',
}

export enum TipoAtividadeEnum {
  COMERCIO = 'COMERCIO',
  INDUSTRIA = 'INDUSTRIA',
  SERVICOS = 'SERVICOS',
}

export class CalcularApuracaoDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Competência (YYYY-MM-DD, 1º dia do mês)' })
  @IsEnum({
    example: '2026-09-01',
  } as any)
  competencia: string;

  @ApiProperty({ enum: RegimeTributarioEnum })
  @IsEnum(RegimeTributarioEnum)
  regime: RegimeTributarioEnum;

  @ApiPropertyOptional({ enum: AnexoSimplesEnum })
  @IsOptional()
  @IsEnum(AnexoSimplesEnum)
  anexoSimples?: AnexoSimplesEnum;

  @ApiProperty({ description: 'Receita bruta do mês' })
  @IsNumber()
  @Min(0)
  receitaBruta: number;

  @ApiPropertyOptional({ description: 'Receita bruta acumulada dos últimos 12 meses' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  receitaBruta12Meses?: number;

  @ApiPropertyOptional({ description: 'Folha de pagamento 12 meses (para Fator R)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  folha12Meses?: number;

  @ApiPropertyOptional({ enum: TipoAtividadeEnum })
  @IsOptional()
  @IsEnum(TipoAtividadeEnum)
  tipoAtividade?: TipoAtividadeEnum;

  @ApiPropertyOptional({ description: 'Alíquota ISS (2 a 5%)', default: 5 })
  @IsOptional()
  @IsNumber()
  aliquotaIss?: number;

  @ApiPropertyOptional({ description: 'Alíquota ICMS (7 a 18%)', default: 18 })
  @IsOptional()
  @IsNumber()
  aliquotaIcms?: number;

  @ApiPropertyOptional({ description: 'Retenções sofridas (para dedução)' })
  @IsOptional()
  @IsNumber()
  @Min(0)
  retencoes?: number;
}
