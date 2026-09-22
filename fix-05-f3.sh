#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/common/utils
mkdir -p src/modules/empresas/dto
mkdir -p src/modules/empresas/testes
mkdir -p src/modules/socios/dto
mkdir -p src/modules/socios/testes

# ============================================================
# 1. UTILS — CNPJ, CPF e ViaCEP
# ============================================================
cat > src/common/utils/cnpj.util.ts <<'UTIL_EOF'
/**
 * Valida CNPJ usando o algoritmo oficial dos dígitos verificadores.
 */
export function validarCnpj(cnpj: string): boolean {
  const limpo = cnpj.replace(/\D/g, '');
  if (limpo.length !== 14) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcularDigito = (base: string, pesos: number[]): number => {
    const soma = base.split('').reduce((acc, d, i) => acc + parseInt(d, 10) * pesos[i], 0);
    const resto = soma % 11;
    return resto < 2 ? 0 : 11 - resto;
  };

  const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
  const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

  const d1 = calcularDigito(limpo.slice(0, 12), pesos1);
  const d2 = calcularDigito(limpo.slice(0, 13), pesos2);

  return limpo === limpo.slice(0, 12) + d1 + d2;
}

export function limparCnpj(cnpj: string): string {
  return cnpj.replace(/\D/g, '');
}

export function formatarCnpj(cnpj: string): string {
  const limpo = limparCnpj(cnpj);
  return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
}
UTIL_EOF

cat > src/common/utils/cpf.util.ts <<'UTIL_EOF'
/**
 * Valida CPF usando o algoritmo oficial dos dígitos verificadores.
 */
export function validarCpf(cpf: string): boolean {
  const limpo = cpf.replace(/\D/g, '');
  if (limpo.length !== 11) return false;
  if (/^(\d)\1+$/.test(limpo)) return false;

  const calcularDigito = (base: string): number => {
    const fator = base.length + 1;
    const soma = base
      .split('')
      .reduce((acc, d, i) => acc + parseInt(d, 10) * (fator - i), 0);
    const resto = (soma * 10) % 11;
    return resto === 10 ? 0 : resto;
  };

  const d1 = calcularDigito(limpo.slice(0, 9));
  const d2 = calcularDigito(limpo.slice(0, 10));

  return limpo === limpo.slice(0, 9) + d1 + d2;
}

export function limparCpf(cpf: string): string {
  return cpf.replace(/\D/g, '');
}

export function formatarCpf(cpf: string): string {
  const limpo = limparCpf(cpf);
  return limpo.replace(/^(\d{3})(\d{3})(\d{3})(\d{2})$/, '$1.$2.$3-$4');
}
UTIL_EOF

cat > src/common/utils/viacep.util.ts <<'UTIL_EOF'
export interface EnderecoViaCep {
  cep: string;
  logradouro: string;
  complemento: string;
  bairro: string;
  localidade: string;
  uf: string;
  ibge?: string;
  erro?: boolean;
}

export async function buscarCep(cep: string): Promise<EnderecoViaCep | null> {
  const limpo = cep.replace(/\D/g, '');
  if (limpo.length !== 8) return null;

  try {
    const res = await fetch(`https://viacep.com.br/ws/${limpo}/json/`);
    if (!res.ok) return null;
    const data = (await res.json()) as EnderecoViaCep;
    if (data.erro) return null;
    return data;
  } catch {
    return null;
  }
}
UTIL_EOF

# ============================================================
# 2. EMPRESAS — DTOs
# ============================================================
cat > src/modules/empresas/dto/create-empresa.dto.ts <<'DTO_EOF'
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
DTO_EOF

cat > src/modules/empresas/dto/update-empresa.dto.ts <<'DTO_EOF'
import { PartialType } from '@nestjs/swagger';
import { CreateEmpresaDto } from './create-empresa.dto';

export class UpdateEmpresaDto extends PartialType(CreateEmpresaDto) {}
DTO_EOF

cat > src/modules/empresas/dto/filter-empresa.dto.ts <<'DTO_EOF'
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
DTO_EOF

# ============================================================
# 3. EMPRESAS — SERVICE
# ============================================================
cat > src/modules/empresas/empresas.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateEmpresaDto } from './dto/create-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { FilterEmpresaDto } from './dto/filter-empresa.dto';
import { validarCnpj, limparCnpj } from '../../common/utils/cnpj.util';
import { validarCpf, limparCpf } from '../../common/utils/cpf.util';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class EmpresasService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string, filtros: FilterEmpresaDto) {
    const where: any = { tenantId, deletedAt: null };

    if (filtros.busca) {
      const busca = filtros.busca;
      where.OR = [
        { razaoSocial: { contains: busca, mode: 'insensitive' } },
        { nomeFantasia: { contains: busca, mode: 'insensitive' } },
        { cnpj: { contains: limparCnpj(busca) } },
      ];
    }

    if (filtros.regimeTributario) where.regimeTributario = filtros.regimeTributario;
    if (filtros.status) where.status = filtros.status;

    const [total, empresas] = await Promise.all([
      this.prisma.empresa.count({ where }),
      this.prisma.empresa.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { [filtros.orderBy ?? 'createdAt']: filtros.order },
        include: {
          _count: { select: { socios: true, lancamentos: true } },
        },
      }),
    ]);

    return paginar(empresas, total, filtros.page, filtros.limit);
  }

  async buscarPorId(tenantId: string, id: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: {
        socios: { where: { status: 'ativo' } },
      },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
    return empresa;
  }

  async criar(tenantId: string, dto: CreateEmpresaDto) {
    const cnpjLimpo = limparCnpj(dto.cnpj);

    if (!validarCnpj(cnpjLimpo)) {
      throw new BadRequestException('CNPJ inválido');
    }

    const existente = await this.prisma.empresa.findFirst({
      where: { tenantId, cnpj: cnpjLimpo, deletedAt: null },
    });
    if (existente) throw new ConflictException('CNPJ já cadastrado neste escritório');

    if (dto.responsavelCpf && !validarCpf(dto.responsavelCpf)) {
      throw new BadRequestException('CPF do responsável inválido');
    }

    if (dto.anexoSimples && dto.regimeTributario !== 'SIMPLES') {
      throw new BadRequestException('Anexo do Simples só é válido para regime SIMPLES');
    }

    return this.prisma.empresa.create({
      data: {
        tenantId,
        razaoSocial: dto.razaoSocial,
        nomeFantasia: dto.nomeFantasia,
        cnpj: cnpjLimpo,
        inscricaoEstadual: dto.inscricaoEstadual,
        inscricaoMunicipal: dto.inscricaoMunicipal,
        regimeTributario: dto.regimeTributario,
        anexoSimples: dto.anexoSimples,
        cnaePrincipal: dto.cnaePrincipal,
        cnaesSecundarios: dto.cnaesSecundarios ?? undefined,
        dataAbertura: dto.dataAbertura ? new Date(dto.dataAbertura) : undefined,
        dataRegimeAtual: dto.dataRegimeAtual ? new Date(dto.dataRegimeAtual) : undefined,
        endereco: dto.endereco ?? undefined,
        email: dto.email,
        telefone: dto.telefone,
        responsavelNome: dto.responsavelNome,
        responsavelCpf: dto.responsavelCpf ? limparCpf(dto.responsavelCpf) : undefined,
        observacoes: dto.observacoes,
      },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateEmpresaDto) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    if (dto.cnpj) {
      const cnpjLimpo = limparCnpj(dto.cnpj);
      if (!validarCnpj(cnpjLimpo)) throw new BadRequestException('CNPJ inválido');

      if (cnpjLimpo !== empresa.cnpj) {
        const existente = await this.prisma.empresa.findFirst({
          where: { tenantId, cnpj: cnpjLimpo, NOT: { id } },
        });
        if (existente) throw new ConflictException('CNPJ já cadastrado');
      }
    }

    if (dto.responsavelCpf && !validarCpf(dto.responsavelCpf)) {
      throw new BadRequestException('CPF do responsável inválido');
    }

    return this.prisma.empresa.update({
      where: { id },
      data: {
        razaoSocial: dto.razaoSocial,
        nomeFantasia: dto.nomeFantasia,
        cnpj: dto.cnpj ? limparCnpj(dto.cnpj) : undefined,
        inscricaoEstadual: dto.inscricaoEstadual,
        inscricaoMunicipal: dto.inscricaoMunicipal,
        regimeTributario: dto.regimeTributario,
        anexoSimples: dto.anexoSimples,
        cnaePrincipal: dto.cnaePrincipal,
        cnaesSecundarios: dto.cnaesSecundarios ?? undefined,
        dataAbertura: dto.dataAbertura ? new Date(dto.dataAbertura) : undefined,
        dataRegimeAtual: dto.dataRegimeAtual ? new Date(dto.dataRegimeAtual) : undefined,
        endereco: dto.endereco ?? undefined,
        email: dto.email,
        telefone: dto.telefone,
        responsavelNome: dto.responsavelNome,
        responsavelCpf: dto.responsavelCpf ? limparCpf(dto.responsavelCpf) : undefined,
        observacoes: dto.observacoes,
      },
    });
  }

  async remover(tenantId: string, id: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    // Soft delete — mantém histórico contábil
    await this.prisma.empresa.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'BAIXADA' },
    });
    return { message: 'Empresa removida' };
  }
}
SERVICE_EOF

# ============================================================
# 4. EMPRESAS — CONTROLLER
# ============================================================
cat > src/modules/empresas/empresas.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post, Query,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { EmpresasService } from './empresas.service';
import { CreateEmpresaDto } from './dto/create-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { FilterEmpresaDto } from './dto/filter-empresa.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('empresas')
@ApiBearerAuth()
@Controller('empresas')
export class EmpresasController {
  constructor(private readonly service: EmpresasService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.EMPRESA_VER)
  @ApiOperation({ summary: 'Lista empresas com filtros e paginação' })
  listar(@CurrentTenant() t: string, @Query() filtros: FilterEmpresaDto) {
    return this.service.listar(t, filtros);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.EMPRESA_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.EMPRESA_CRIAR)
  @ApiOperation({ summary: 'Cria nova empresa' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateEmpresaDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.EMPRESA_EDITAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateEmpresaDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.EMPRESA_EXCLUIR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
CTRL_EOF

cat > src/modules/empresas/empresas.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { EmpresasController } from './empresas.controller';
import { EmpresasService } from './empresas.service';

@Module({
  controllers: [EmpresasController],
  providers: [EmpresasService],
  exports: [EmpresasService],
})
export class EmpresasModule {}
MOD_EOF

# ============================================================
# 5. SÓCIOS — DTOs
# ============================================================
cat > src/modules/socios/dto/create-socio.dto.ts <<'DTO_EOF'
import { ApiProperty, ApiPropertyOptional } from '@nestjs/swagger';
import {
  IsDateString, IsNumber, IsOptional, IsString, IsUUID,
  Length, Max, MaxLength, Min, MinLength,
} from 'class-validator';

export class CreateSocioDto {
  @ApiProperty()
  @IsUUID()
  empresaId: string;

  @ApiProperty({ example: 'João Silva' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ example: '12345678909' })
  @IsString()
  @Length(11, 11)
  cpf: string;

  @ApiProperty({ description: 'Percentual de participação (0 a 100)', example: 50 })
  @IsNumber()
  @Min(0.000001)
  @Max(100)
  participacao: number;

  @ApiPropertyOptional({ example: 5000 })
  @IsOptional()
  @IsNumber()
  @Min(0)
  proLabore?: number;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataEntrada?: string;

  @ApiPropertyOptional()
  @IsOptional()
  @IsDateString()
  dataSaida?: string;
}
DTO_EOF

cat > src/modules/socios/dto/update-socio.dto.ts <<'DTO_EOF'
import { PartialType } from '@nestjs/swagger';
import { CreateSocioDto } from './create-socio.dto';

export class UpdateSocioDto extends PartialType(CreateSocioDto) {}
DTO_EOF

# ============================================================
# 6. SÓCIOS — SERVICE
# ============================================================
cat > src/modules/socios/socios.service.ts <<'SERVICE_EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateSocioDto } from './dto/create-socio.dto';
import { UpdateSocioDto } from './dto/update-socio.dto';
import { validarCpf, limparCpf } from '../../common/utils/cpf.util';

@Injectable()
export class SociosService {
  constructor(private readonly prisma: PrismaService) {}

  async listarPorEmpresa(tenantId: string, empresaId: string) {
    await this.validarEmpresa(tenantId, empresaId);

    const socios = await this.prisma.socio.findMany({
      where: { tenantId, empresaId, status: 'ativo' },
      orderBy: { nome: 'asc' },
    });

    const totalParticipacao = socios.reduce(
      (acc, s) => acc + Number(s.participacao),
      0,
    );

    return {
      data: socios,
      resumo: {
        total: socios.length,
        participacaoTotal: Number(totalParticipacao.toFixed(6)),
        participacaoCompleta: Math.abs(totalParticipacao - 100) < 0.0001,
      },
    };
  }

  async buscarPorId(tenantId: string, id: string) {
    const socio = await this.prisma.socio.findFirst({
      where: { id, tenantId },
    });
    if (!socio) throw new NotFoundException('Sócio não encontrado');
    return socio;
  }

  async criar(tenantId: string, dto: CreateSocioDto) {
    await this.validarEmpresa(tenantId, dto.empresaId);

    const cpfLimpo = limparCpf(dto.cpf);
    if (!validarCpf(cpfLimpo)) throw new BadRequestException('CPF inválido');

    const existente = await this.prisma.socio.findFirst({
      where: { empresaId: dto.empresaId, cpf: cpfLimpo },
    });
    if (existente) throw new ConflictException('CPF já cadastrado nesta empresa');

    await this.validarSomaParticipacao(dto.empresaId, dto.participacao, null);

    return this.prisma.socio.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        nome: dto.nome,
        cpf: cpfLimpo,
        participacao: dto.participacao,
        proLabore: dto.proLabore,
        dataEntrada: dto.dataEntrada ? new Date(dto.dataEntrada) : undefined,
        dataSaida: dto.dataSaida ? new Date(dto.dataSaida) : undefined,
      },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateSocioDto) {
    const socio = await this.prisma.socio.findFirst({ where: { id, tenantId } });
    if (!socio) throw new NotFoundException('Sócio não encontrado');

    if (dto.cpf) {
      const cpfLimpo = limparCpf(dto.cpf);
      if (!validarCpf(cpfLimpo)) throw new BadRequestException('CPF inválido');

      if (cpfLimpo !== socio.cpf) {
        const existente = await this.prisma.socio.findFirst({
          where: { empresaId: socio.empresaId, cpf: cpfLimpo, NOT: { id } },
        });
        if (existente) throw new ConflictException('CPF já cadastrado');
      }
    }

    if (dto.participacao !== undefined) {
      await this.validarSomaParticipacao(socio.empresaId, dto.participacao, id);
    }

    return this.prisma.socio.update({
      where: { id },
      data: {
        nome: dto.nome,
        cpf: dto.cpf ? limparCpf(dto.cpf) : undefined,
        participacao: dto.participacao,
        proLabore: dto.proLabore,
        dataEntrada: dto.dataEntrada ? new Date(dto.dataEntrada) : undefined,
        dataSaida: dto.dataSaida ? new Date(dto.dataSaida) : undefined,
      },
    });
  }

  async remover(tenantId: string, id: string) {
    const socio = await this.prisma.socio.findFirst({ where: { id, tenantId } });
    if (!socio) throw new NotFoundException('Sócio não encontrado');

    await this.prisma.socio.update({
      where: { id },
      data: { status: 'inativo', dataSaida: new Date() },
    });
    return { message: 'Sócio removido' };
  }

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }

  private async validarSomaParticipacao(
    empresaId: string,
    novaParticipacao: number,
    socioIdExistente: string | null,
  ) {
    const sociosAtivos = await this.prisma.socio.findMany({
      where: {
        empresaId,
        status: 'ativo',
        ...(socioIdExistente ? { NOT: { id: socioIdExistente } } : {}),
      },
      select: { participacao: true },
    });

    const somaAtual = sociosAtivos.reduce(
      (acc, s) => acc + Number(s.participacao),
      0,
    );
    const somaTotal = somaAtual + novaParticipacao;

    if (somaTotal > 100.0001) {
      throw new BadRequestException(
        `Soma das participações ultrapassaria 100%. Atual: ${somaAtual.toFixed(4)}%, ` +
        `nova: ${novaParticipacao}%, total: ${somaTotal.toFixed(4)}%`,
      );
    }
  }
}
SERVICE_EOF

# ============================================================
# 7. SÓCIOS — CONTROLLER
# ============================================================
cat > src/modules/socios/socios.controller.ts <<'CTRL_EOF'
import {
  Body, Controller, Delete, Get, Param, ParseUUIDPipe, Patch, Post,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { SociosService } from './socios.service';
import { CreateSocioDto } from './dto/create-socio.dto';
import { UpdateSocioDto } from './dto/update-socio.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('socios')
@ApiBearerAuth()
@Controller('socios')
export class SociosController {
  constructor(private readonly service: SociosService) {}

  @Get('empresa/:empresaId')
  @RequirePermissions(PERMISSIONS.SOCIO_VER)
  @ApiOperation({ summary: 'Lista sócios de uma empresa com resumo de participação' })
  listarPorEmpresa(
    @CurrentTenant() t: string,
    @Param('empresaId', ParseUUIDPipe) empresaId: string,
  ) {
    return this.service.listarPorEmpresa(t, empresaId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.SOCIO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.SOCIO_CRIAR)
  @ApiOperation({ summary: 'Cria novo sócio' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateSocioDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.SOCIO_EDITAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateSocioDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.SOCIO_EXCLUIR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }
}
CTRL_EOF

cat > src/modules/socios/socios.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { SociosController } from './socios.controller';
import { SociosService } from './socios.service';

@Module({
  controllers: [SociosController],
  providers: [SociosService],
  exports: [SociosService],
})
export class SociosModule {}
MOD_EOF

# ============================================================
# 8. TESTES — CNPJ, CPF e validação de participação
# ============================================================
cat > src/common/utils/testes/cnpj-cpf.spec.ts <<'TEST_EOF'
import { validarCnpj, limparCnpj, formatarCnpj } from '../cnpj.util';
import { validarCpf, limparCpf, formatarCpf } from '../cpf.util';

describe('Validação de CNPJ', () => {
  it('aceita CNPJ válido (sem máscara)', () => {
    expect(validarCnpj('11222333000181')).toBe(true);
  });

  it('aceita CNPJ válido (com máscara)', () => {
    expect(validarCnpj('11.222.333/0001-81')).toBe(true);
  });

  it('rejeita CNPJ com dígito verificador errado', () => {
    expect(validarCnpj('11222333000182')).toBe(false);
  });

  it('rejeita CNPJ com todos os dígitos iguais', () => {
    expect(validarCnpj('11111111111111')).toBe(false);
  });

  it('rejeita CNPJ com tamanho inválido', () => {
    expect(validarCnpj('123')).toBe(false);
  });

  it('limparCnpj remove máscara', () => {
    expect(limparCnpj('11.222.333/0001-81')).toBe('11222333000181');
  });

  it('formatarCnpj adiciona máscara', () => {
    expect(formatarCnpj('11222333000181')).toBe('11.222.333/0001-81');
  });
});

describe('Validação de CPF', () => {
  it('aceita CPF válido (sem máscara)', () => {
    expect(validarCpf('12345678909')).toBe(true);
  });

  it('aceita CPF válido (com máscara)', () => {
    expect(validarCpf('123.456.789-09')).toBe(true);
  });

  it('rejeita CPF com dígito verificador errado', () => {
    expect(validarCpf('12345678908')).toBe(false);
  });

  it('rejeita CPF com todos os dígitos iguais', () => {
    expect(validarCpf('11111111111')).toBe(false);
  });

  it('rejeita CPF com tamanho inválido', () => {
    expect(validarCpf('123')).toBe(false);
  });

  it('limparCpf remove máscara', () => {
    expect(limparCpf('123.456.789-09')).toBe('12345678909');
  });

  it('formatarCpf adiciona máscara', () => {
    expect(formatarCpf('12345678909')).toBe('123.456.789-09');
  });
});
TEST_EOF

mkdir -p src/common/utils/testes

cat > src/modules/socios/testes/socios.service.spec.ts <<'TEST_EOF'
import { Test } from '@nestjs/testing';
import { BadRequestException, NotFoundException } from '@nestjs/common';
import { SociosService } from '../socios.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('SociosService', () => {
  let service: SociosService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      empresa: { findFirst: jest.fn().mockResolvedValue({ id: 'e1' }) },
      socio: {
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const module = await Test.createTestingModule({
      providers: [SociosService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(SociosService);
  });

  it('cria sócio com CPF válido e participação OK', async () => {
    prisma.socio.create.mockResolvedValue({ id: 's1' });
    const r = await service.criar('t1', {
      empresaId: 'e1',
      nome: 'João Silva',
      cpf: '12345678909',
      participacao: 50,
    });
    expect(r.id).toBe('s1');
  });

  it('rejeita CPF inválido', async () => {
    await expect(
      service.criar('t1', {
        empresaId: 'e1',
        nome: 'João',
        cpf: '11111111111',
        participacao: 50,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita quando soma de participação ultrapassa 100%', async () => {
    prisma.socio.findMany.mockResolvedValue([{ participacao: 80 }]);
    await expect(
      service.criar('t1', {
        empresaId: 'e1',
        nome: 'João',
        cpf: '12345678909',
        participacao: 30,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita sócio de empresa inexistente', async () => {
    prisma.empresa.findFirst.mockResolvedValue(null);
    await expect(
      service.criar('t1', {
        empresaId: 'inexistente',
        nome: 'João',
        cpf: '12345678909',
        participacao: 50,
      }),
    ).rejects.toThrow(NotFoundException);
  });
});
TEST_EOF

# ============================================================
# 9. REGISTRAR MÓDULOS NO APP.MODULE
# ============================================================
python3 <<'PYEOF'
import re
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'EmpresasModule' not in content:
    # Adicionar imports
    content = content.replace(
        "import { PermissionsModule } from './modules/permissions/permissions.module';",
        "import { PermissionsModule } from './modules/permissions/permissions.module';\n"
        "import { EmpresasModule } from './modules/empresas/empresas.module';\n"
        "import { SociosModule } from './modules/socios/socios.module';"
    )

    # Adicionar nos imports do @Module
    content = content.replace(
        "    PermissionsModule,\n    HealthModule,",
        "    PermissionsModule,\n    EmpresasModule,\n    SociosModule,\n    HealthModule,"
    )

    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado")
else:
    print("ℹ️  AppModule já contém EmpresasModule")
PYEOF

echo ""
echo "✅ Pacote F3 instalado!"
echo ""
echo "Rode agora:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"
EOF