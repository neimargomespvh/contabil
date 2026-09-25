import { ApiProperty } from '@nestjs/swagger';
import { ArrayMinSize, IsArray, IsUUID, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';

export class ReordenarItemDto {
  @ApiProperty()
  @IsUUID()
  id: string;

  @ApiProperty({ description: 'Nova prioridade (menor = primeiro)' })
  @Type(() => Number)
  prioridade: number;
}

export class ReordenarRegrasDto {
  @ApiProperty({ type: [ReordenarItemDto] })
  @IsArray()
  @ArrayMinSize(1)
  @ValidateNested({ each: true })
  @Type(() => ReordenarItemDto)
  regras: ReordenarItemDto[];
}
