import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import { Type } from 'class-transformer';
import {
  IsBoolean, IsDateString, IsEmail, IsEnum, IsOptional, IsString,
  Length, MaxLength, MinLength, ValidateNested,
} from 'class-validator';

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

export class EnderecoDto {
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(200) logradouro?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(20)  numero?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(100) complemento?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(100) bairro?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @MaxLength(100) cidade?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(2, 2)   uf?: string;
  @ApiPropertyOptional() @IsOptional() @IsString() @Length(8, 8)   cep?: string;
}

export class CreateEmpresaDto {
  @ApiProperty({ example: 'Empresa Teste LTDA' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  razaoSocial: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  nomeFantasia?: string;

  @ApiProperty({ example: '11222333000144' })
  @IsString()
  @Length(14, 14)
  cnpj: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(20)
  inscricaoEstadual?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(20)
  inscricaoMunicipal?: string;

  @ApiProperty({ enum: RegimeTributarioEnum })
  @IsEnum(RegimeTributarioEnum)
  regimeTributario: RegimeTributarioEnum;

  @ApiPropertyOptional({ enum: AnexoSimplesEnum })
  @IsOptional()
  @IsEnum(AnexoSimplesEnum)
  anexoSimples?: AnexoSimplesEnum;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(10)
  cnaePrincipal?: string;

  @ApiPropertyOptional({ type: [String] })
  @IsOptional()
  cnaesSecundarios?: string[];

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataAbertura?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataRegimeAtual?: string;

  @ApiPropertyOptional({ type: EnderecoDto })
  @IsOptional()
  @ValidateNested()
  @Type(() => EnderecoDto)
  endereco?: EnderecoDto;

  @ApiPropertyOptional()
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(20)
  telefone?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @MaxLength(200)
  responsavelNome?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  @Length(11, 11)
  responsavelCpf?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsString()
  observacoes?: string;
}
