import { ApiProperty } from '@nestjs/swagger';
import { IsString, IsUUID } from 'class-validator';

export class SimularRegraDto {
  @ApiProperty({ description: 'ID da empresa' })
  @IsUUID()
  empresaId: string;

  @ApiProperty({ description: 'XML do documento fiscal' })
  @IsString()
  xml: string;
}
