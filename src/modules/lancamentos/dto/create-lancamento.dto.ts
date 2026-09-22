import { ArrayMinSize, IsArray, IsDateString, IsOptional, IsString, IsUUID, ValidateNested } from 'class-validator';
import { Type } from 'class-transformer';
import { CreatePartidaDto } from './create-partida.dto';
export class CreateLancamentoDto {
  @IsUUID() empresaId: string;
  @IsOptional() @IsUUID() loteId?: string;
  @IsDateString() dataLancamento: string;
  @IsDateString() competencia: string;
  @IsString() historico: string;
  @IsOptional() @IsString() documentoRef?: string;
  @IsArray() @ArrayMinSize(2) @ValidateNested({ each: true }) @Type(() => CreatePartidaDto)
  partidas: CreatePartidaDto[];
}
