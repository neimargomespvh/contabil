import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsInt,
  IsObject,
  IsOptional,
  IsString,
  IsUUID,
  MaxLength,
  Min,
} from 'class-validator';

export class CreateRegraDto {
  @ApiProperty({ description: 'ID da empresa' })
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'Nome descritivo da regra', maxLength: 200 })
  @IsString()
  @MaxLength(200)
  nome: string;

  @ApiProperty({
    description: 'Prioridade (menor = mais prioritária)',
    minimum: 1,
  })
  @IsInt()
  @Min(1)
  prioridade: number;

  @ApiProperty({
    description: 'Condições em JSON',
    example: { cfop: '5102', ncm: '12345678' },
  })
  @IsObject()
  condicao: Record<string, any>;

  @ApiProperty({ description: 'Conta de débito' })
  @IsUUID()
  contaDebitoId: string;

  @ApiProperty({ description: 'Conta de crédito' })
  @IsUUID()
  contaCreditoId: string;

  @ApiPropertyOptional({
    description: 'Template do histórico',
    example: 'NF {numero} - {emitente}',
  })
  @IsOptional()
  @IsString()
  @MaxLength(500)
  historicoTemplate?: string;
}
