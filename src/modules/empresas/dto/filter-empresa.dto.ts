import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsEnum, IsOptional, IsString } from 'class-validator';
import { PaginationDto } from '../../../common/dto/pagination.dto';
import { RegimeTributarioEnum } from './create-empresa.dto';

export enum EmpresaStatusEnum {
  ATIVA = 'ATIVA',
  INATIVA = 'INATIVA',
  BAIXADA = 'BAIXADA',
}

export class FilterEmpresaDto extends PaginationDto {
  @ApiPropertyOptional({ description: 'Busca por razão social, fantasia ou CNPJ' })
  @IsOptional()
  @IsString()
  busca?: string;

  @ApiPropertyOptional({ enum: RegimeTributarioEnum })
  @IsOptional()
  @IsEnum(RegimeTributarioEnum)
  regimeTributario?: RegimeTributarioEnum;

  @ApiPropertyOptional({ enum: EmpresaStatusEnum })
  @IsOptional()
  @IsEnum(EmpresaStatusEnum)
  status?: EmpresaStatusEnum;
}
