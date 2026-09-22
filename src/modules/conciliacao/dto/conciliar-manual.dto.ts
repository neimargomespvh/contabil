import { ApiProperty } from '@nestjs/swagger';
import { IsUUID } from 'class-validator';

export class ConciliarManualDto {
  @ApiProperty({ description: 'ID do lançamento a vincular' })
  @IsUUID()
  lancamentoId: string;
}
