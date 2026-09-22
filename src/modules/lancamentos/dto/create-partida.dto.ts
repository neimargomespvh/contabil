import { IsEnum, IsNumber, IsOptional, IsUUID, Min } from 'class-validator';
export enum TipoPartidaDto { D = 'D', C = 'C' }
export class CreatePartidaDto {
  @IsUUID() contaId: string;
  @IsOptional() @IsUUID() centroCustoId?: string;
  @IsEnum(TipoPartidaDto) tipo: TipoPartidaDto;
  @IsNumber() @Min(0.01) valor: number;
}
