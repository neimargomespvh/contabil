import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { IsOptional, IsString, IsUUID, MinLength } from 'class-validator';

export class ImportarOfxDto {
  @ApiProperty()
  @IsUUID()
  contaBancariaId: string;

  @ApiProperty({ description: 'Conteúdo do arquivo OFX' })
  @IsString()
  @MinLength(20)
  conteudo: string;

  @ApiPropertyOptional({ description: 'Tentar conciliar automaticamente' })
  @IsOptional()
  @IsString()
  conciliarAutomatico?: string;
}
