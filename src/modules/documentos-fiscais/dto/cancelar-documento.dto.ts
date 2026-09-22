import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class CancelarDocumentoDto {
  @ApiProperty({ description: 'Motivo do cancelamento' })
  @IsString()
  @MinLength(5)
  motivo: string;
}
