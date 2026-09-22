#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/common/constants
mkdir -p src/modules/{permissions,roles/dto,users/dto}

# ============================================================
# 1. CONSTANTES DE PERMISSÕES
# ============================================================
cat > src/common/constants/permissions.constants.ts <<'EOF'
export const PERMISSIONS = {
  // Empresas
  EMPRESA_CRIAR: 'empresa.criar',
  EMPRESA_EDITAR: 'empresa.editar',
  EMPRESA_EXCLUIR: 'empresa.excluir',
  EMPRESA_VER: 'empresa.ver',

  // Sócios
  SOCIO_CRIAR: 'socio.criar',
  SOCIO_EDITAR: 'socio.editar',
  SOCIO_EXCLUIR: 'socio.excluir',
  SOCIO_VER: 'socio.ver',

  // Plano de contas
  PLANO_CRIAR: 'plano.criar',
  PLANO_EDITAR: 'plano.editar',
  PLANO_VER: 'plano.ver',

  // Lançamentos
  LANCAMENTO_CRIAR: 'lancamento.criar',
  LANCAMENTO_EDITAR: 'lancamento.editar',
  LANCAMENTO_ESTORNAR: 'lancamento.estornar',
  LANCAMENTO_VER: 'lancamento.ver',

  // Documentos fiscais
  DOCUMENTO_IMPORTAR: 'documento.importar',
  DOCUMENTO_EXCLUIR: 'documento.excluir',
  DOCUMENTO_VER: 'documento.ver',

  // Conciliação
  CONCILIACAO_EXECUTAR: 'conciliacao.executar',
  CONCILIACAO_VER: 'conciliacao.ver',

  // Apuração
  APURACAO_CALCULAR: 'apuracao.calcular',
  APURACAO_VER: 'apuracao.ver',

  // Relatórios
  RELATORIO_GERAR: 'relatorio.gerar',
  RELATORIO_VER: 'relatorio.ver',

  // Administração
  USUARIO_GERENCIAR: 'usuario.gerenciar',
  USUARIO_VER: 'usuario.ver',
  ROLE_GERENCIAR: 'role.gerenciar',
  ROLE_VER: 'role.ver',
  AUDITORIA_VER: 'auditoria.ver',
} as const;

export type PermissionCode = (typeof PERMISSIONS)[keyof typeof PERMISSIONS];

export const TODAS_PERMISSOES: string[] = Object.values(PERMISSIONS);

// Descrições legíveis para exibir no frontend
export const PERMISSOES_DESCRICOES: Record<string, string> = {
  [PERMISSIONS.EMPRESA_CRIAR]: 'Criar empresas',
  [PERMISSIONS.EMPRESA_EDITAR]: 'Editar empresas',
  [PERMISSIONS.EMPRESA_EXCLUIR]: 'Excluir empresas',
  [PERMISSIONS.EMPRESA_VER]: 'Visualizar empresas',
  [PERMISSIONS.SOCIO_CRIAR]: 'Criar sócios',
  [PERMISSIONS.SOCIO_EDITAR]: 'Editar sócios',
  [PERMISSIONS.SOCIO_EXCLUIR]: 'Excluir sócios',
  [PERMISSIONS.SOCIO_VER]: 'Visualizar sócios',
  [PERMISSIONS.PLANO_CRIAR]: 'Criar planos de contas',
  [PERMISSIONS.PLANO_EDITAR]: 'Editar planos de contas',
  [PERMISSIONS.PLANO_VER]: 'Visualizar planos de contas',
  [PERMISSIONS.LANCAMENTO_CRIAR]: 'Criar lançamentos',
  [PERMISSIONS.LANCAMENTO_EDITAR]: 'Editar lançamentos',
  [PERMISSIONS.LANCAMENTO_ESTORNAR]: 'Estornar lançamentos',
  [PERMISSIONS.LANCAMENTO_VER]: 'Visualizar lançamentos',
  [PERMISSIONS.DOCUMENTO_IMPORTAR]: 'Importar documentos fiscais',
  [PERMISSIONS.DOCUMENTO_EXCLUIR]: 'Excluir documentos fiscais',
  [PERMISSIONS.DOCUMENTO_VER]: 'Visualizar documentos fiscais',
  [PERMISSIONS.CONCILIACAO_EXECUTAR]: 'Executar conciliação bancária',
  [PERMISSIONS.CONCILIACAO_VER]: 'Visualizar conciliação',
  [PERMISSIONS.APURACAO_CALCULAR]: 'Calcular apurações tributárias',
  [PERMISSIONS.APURACAO_VER]: 'Visualizar apurações',
  [PERMISSIONS.RELATORIO_GERAR]: 'Gerar relatórios',
  [PERMISSIONS.RELATORIO_VER]: 'Visualizar relatórios',
  [PERMISSIONS.USUARIO_GERENCIAR]: 'Gerenciar usuários',
  [PERMISSIONS.USUARIO_VER]: 'Visualizar usuários',
  [PERMISSIONS.ROLE_GERENCIAR]: 'Gerenciar perfis e permissões',
  [PERMISSIONS.ROLE_VER]: 'Visualizar perfis',
  [PERMISSIONS.AUDITORIA_VER]: 'Visualizar auditoria',
};

// Perfis padrão criados para cada novo tenant
export interface RolePadrao {
  nome: string;
  descricao: string;
  permissoes: string[];
}

export const ROLES_PADRAO: RolePadrao[] = [
  {
    nome: 'admin',
    descricao: 'Administrador — acesso total ao sistema',
    permissoes: TODAS_PERMISSOES,
  },
  {
    nome: 'contador',
    descricao: 'Contador — acesso contábil, fiscal e relatórios',
    permissoes: [
      PERMISSIONS.EMPRESA_CRIAR,
      PERMISSIONS.EMPRESA_EDITAR,
      PERMISSIONS.EMPRESA_VER,
      PERMISSIONS.SOCIO_CRIAR,
      PERMISSIONS.SOCIO_EDITAR,
      PERMISSIONS.SOCIO_VER,
      PERMISSIONS.PLANO_CRIAR,
      PERMISSIONS.PLANO_EDITAR,
      PERMISSIONS.PLANO_VER,
      PERMISSIONS.LANCAMENTO_CRIAR,
      PERMISSIONS.LANCAMENTO_EDITAR,
      PERMISSIONS.LANCAMENTO_ESTORNAR,
      PERMISSIONS.LANCAMENTO_VER,
      PERMISSIONS.DOCUMENTO_IMPORTAR,
      PERMISSIONS.DOCUMENTO_VER,
      PERMISSIONS.CONCILIACAO_EXECUTAR,
      PERMISSIONS.CONCILIACAO_VER,
      PERMISSIONS.APURACAO_CALCULAR,
      PERMISSIONS.APURACAO_VER,
      PERMISSIONS.RELATORIO_GERAR,
      PERMISSIONS.RELATORIO_VER,
      PERMISSIONS.USUARIO_VER,
      PERMISSIONS.ROLE_VER,
    ],
  },
  {
    nome: 'auxiliar',
    descricao: 'Auxiliar contábil — lançamentos e visualização',
    permissoes: [
      PERMISSIONS.EMPRESA_VER,
      PERMISSIONS.SOCIO_VER,
      PERMISSIONS.PLANO_VER,
      PERMISSIONS.LANCAMENTO_CRIAR,
      PERMISSIONS.LANCAMENTO_EDITAR,
      PERMISSIONS.LANCAMENTO_VER,
      PERMISSIONS.DOCUMENTO_IMPORTAR,
      PERMISSIONS.DOCUMENTO_VER,
      PERMISSIONS.CONCILIACAO_EXECUTAR,
      PERMISSIONS.CONCILIACAO_VER,
      PERMISSIONS.APURACAO_VER,
      PERMISSIONS.RELATORIO_VER,
    ],
  },
  {
    nome: 'leitura',
    descricao: 'Somente leitura — sem permissão de escrita',
    permissoes: [
      PERMISSIONS.EMPRESA_VER,
      PERMISSIONS.SOCIO_VER,
      PERMISSIONS.PLANO_VER,
      PERMISSIONS.LANCAMENTO_VER,
      PERMISSIONS.DOCUMENTO_VER,
      PERMISSIONS.CONCILIACAO_VER,
      PERMISSIONS.APURACAO_VER,
      PERMISSIONS.RELATORIO_VER,
    ],
  },
];
EOF

# ============================================================
# 2. PERMISSIONS MODULE
# ============================================================
cat > src/modules/permissions/permissions.service.ts <<'EOF'
import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { PERMISSOES_DESCRICOES } from '../../common/constants/permissions.constants';

@Injectable()
export class PermissionsService {
  constructor(private readonly prisma: PrismaService) {}

  async listar() {
    const permissoes = await this.prisma.permission.findMany({
      orderBy: { codigo: 'asc' },
    });

    return permissoes.map((p) => ({
      id: p.id,
      codigo: p.codigo,
      descricao: p.descricao ?? PERMISSOES_DESCRICOES[p.codigo] ?? p.codigo,
    }));
  }
}
EOF

cat > src/modules/permissions/permissions.controller.ts <<'EOF'
import { Controller, Get } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { PermissionsService } from './permissions.service';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('permissions')
@ApiBearerAuth()
@Controller('permissions')
export class PermissionsController {
  constructor(private readonly service: PermissionsService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.ROLE_VER)
  @ApiOperation({ summary: 'Lista todas as permissões disponíveis' })
  listar() {
    return this.service.listar();
  }
}
EOF

cat > src/modules/permissions/permissions.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { PermissionsController } from './permissions.controller';
import { PermissionsService } from './permissions.service';

@Module({
  controllers: [PermissionsController],
  providers: [PermissionsService],
  exports: [PermissionsService],
})
export class PermissionsModule {}
EOF

# ============================================================
# 3. ROLES MODULE
# ============================================================
cat > src/modules/roles/dto/create-role.dto.ts <<'EOF'
import { ApiProperty } from '@nestjs/swagger';
import { ArrayUnique, IsArray, IsOptional, IsString, MaxLength, MinLength } from 'class-validator';

export class CreateRoleDto {
  @ApiProperty({ example: 'gerente' })
  @IsString()
  @MinLength(3)
  @MaxLength(50)
  nome: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MaxLength(200)
  descricao?: string;

  @ApiProperty({ type: [String], required: false })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  permissoes?: string[];
}
EOF

cat > src/modules/roles/dto/update-role.dto.ts <<'EOF'
import { PartialType } from '@nestjs/swagger';
import { CreateRoleDto } from './create-role.dto';

export class UpdateRoleDto extends PartialType(CreateRoleDto) {}
EOF

cat > src/modules/roles/dto/assign-permissions.dto.ts <<'EOF'
import { ApiProperty } from '@nestjs/swagger';
import { ArrayUnique, IsArray, IsString } from 'class-validator';

export class AssignPermissionsDto {
  @ApiProperty({ type: [String] })
  @IsArray()
  @ArrayUnique()
  @IsString({ each: true })
  permissoes: string[];
}
EOF

cat > src/modules/roles/roles.service.ts <<'EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { ROLES_PADRAO, RolePadrao } from '../../common/constants/permissions.constants';

@Injectable()
export class RolesService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string) {
    const roles = await this.prisma.role.findMany({
      where: { tenantId },
      include: {
        rolePermissions: { include: { permission: true } },
        _count: { select: { userRoles: true } },
      },
      orderBy: { nome: 'asc' },
    });

    return roles.map((r) => ({
      id: r.id,
      nome: r.nome,
      descricao: r.descricao,
      permissoes: r.rolePermissions.map((rp) => rp.permission.codigo),
      usuarios: r._count.userRoles,
      createdAt: r.createdAt,
    }));
  }

  async buscarPorId(tenantId: string, id: string) {
    const role = await this.prisma.role.findFirst({
      where: { id, tenantId },
      include: { rolePermissions: { include: { permission: true } } },
    });
    if (!role) throw new NotFoundException('Perfil não encontrado');

    return {
      id: role.id,
      nome: role.nome,
      descricao: role.descricao,
      permissoes: role.rolePermissions.map((rp) => rp.permission.codigo),
    };
  }

  async criar(tenantId: string, dto: CreateRoleDto) {
    const existente = await this.prisma.role.findFirst({
      where: { tenantId, nome: dto.nome },
    });
    if (existente) throw new ConflictException('Já existe um perfil com esse nome');

    const permissoesValidas = await this.validarPermissoes(dto.permissoes ?? []);

    return this.prisma.$transaction(async (tx) => {
      const role = await tx.role.create({
        data: { tenantId, nome: dto.nome, descricao: dto.descricao },
      });

      if (permissoesValidas.length) {
        await tx.rolePermission.createMany({
          data: permissoesValidas.map((permissionId) => ({
            roleId: role.id,
            permissionId,
          })),
        });
      }

      return this.buscarPorId(tenantId, role.id);
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateRoleDto) {
    const role = await this.prisma.role.findFirst({ where: { id, tenantId } });
    if (!role) throw new NotFoundException('Perfil não encontrado');

    if (role.nome === 'admin' && dto.nome && dto.nome !== 'admin') {
      throw new BadRequestException('O perfil "admin" não pode ser renomeado');
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.role.update({
        where: { id },
        data: { nome: dto.nome, descricao: dto.descricao },
      });

      if (dto.permissoes) {
        const permissoesValidas = await this.validarPermissoes(dto.permissoes);

        await tx.rolePermission.deleteMany({ where: { roleId: id } });
        if (permissoesValidas.length) {
          await tx.rolePermission.createMany({
            data: permissoesValidas.map((permissionId) => ({ roleId: id, permissionId })),
          });
        }
      }

      return this.buscarPorId(tenantId, id);
    });
  }

  async remover(tenantId: string, id: string) {
    const role = await this.prisma.role.findFirst({
      where: { id, tenantId },
      include: { _count: { select: { userRoles: true } } },
    });
    if (!role) throw new NotFoundException('Perfil não encontrado');

    if (role.nome === 'admin') {
      throw new BadRequestException('O perfil "admin" não pode ser removido');
    }
    if (role._count.userRoles > 0) {
      throw new BadRequestException(
        `Perfil tem ${role._count.userRoles} usuário(s) vinculado(s). Remova-os antes.`,
      );
    }

    await this.prisma.role.delete({ where: { id } });
    return { message: 'Perfil removido' };
  }

  async atribuirPermissoes(tenantId: string, id: string, permissoes: string[]) {
    const role = await this.prisma.role.findFirst({ where: { id, tenantId } });
    if (!role) throw new NotFoundException('Perfil não encontrado');

    const permissoesValidas = await this.validarPermissoes(permissoes);

    return this.prisma.$transaction(async (tx) => {
      await tx.rolePermission.deleteMany({ where: { roleId: id } });
      if (permissoesValidas.length) {
        await tx.rolePermission.createMany({
          data: permissoesValidas.map((permissionId) => ({ roleId: id, permissionId })),
        });
      }
      return this.buscarPorId(tenantId, id);
    });
  }

  /**
   * Cria os perfis padrão para um novo tenant. Usado no fluxo de registro.
   */
  async criarRolesPadrao(tx: any, tenantId: string, userId: string) {
    const todasPermissoes = await tx.permission.findMany();
    const mapaPermissoes = new Map<string, string>(
      todasPermissoes.map((p: any) => [p.codigo, p.id]),
    );

    let adminRoleId: string | null = null;

    for (const rolePadrao of ROLES_PADRAO as RolePadrao[]) {
      const role = await tx.role.create({
        data: {
          tenantId,
          nome: rolePadrao.nome,
          descricao: rolePadrao.descricao,
        },
      });

      if (rolePadrao.nome === 'admin') adminRoleId = role.id;

      const permissoesIds = rolePadrao.permissoes
        .map((codigo) => mapaPermissoes.get(codigo))
        .filter((id): id is string => Boolean(id));

      if (permissoesIds.length) {
        await tx.rolePermission.createMany({
          data: permissoesIds.map((permissionId) => ({ roleId: role.id, permissionId })),
        });
      }
    }

    if (adminRoleId) {
      await tx.userRole.create({ data: { userId, roleId: adminRoleId } });
    }
  }

  private async validarPermissoes(codigos: string[]): Promise<string[]> {
    if (!codigos.length) return [];

    const permissoes = await this.prisma.permission.findMany({
      where: { codigo: { in: codigos } },
    });

    if (permissoes.length !== codigos.length) {
      const encontradas = new Set(permissoes.map((p) => p.codigo));
      const faltantes = codigos.filter((c) => !encontradas.has(c));
      throw new BadRequestException(`Permissões inválidas: ${faltantes.join(', ')}`);
    }

    return permissoes.map((p) => p.id);
  }
}
EOF

cat > src/modules/roles/roles.controller.ts <<'EOF'
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RolesService } from './roles.service';
import { CreateRoleDto } from './dto/create-role.dto';
import { UpdateRoleDto } from './dto/update-role.dto';
import { AssignPermissionsDto } from './dto/assign-permissions.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('roles')
@ApiBearerAuth()
@Controller('roles')
export class RolesController {
  constructor(private readonly service: RolesService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.ROLE_VER)
  @ApiOperation({ summary: 'Lista perfis do tenant' })
  listar(@CurrentTenant() tenantId: string) {
    return this.service.listar(tenantId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.ROLE_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  @ApiOperation({ summary: 'Cria novo perfil' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateRoleDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateRoleDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Delete(':id')
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  remover(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.remover(t, id);
  }

  @Put(':id/permissoes')
  @RequirePermissions(PERMISSIONS.ROLE_GERENCIAR)
  @ApiOperation({ summary: 'Substitui as permissões do perfil' })
  atribuir(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: AssignPermissionsDto,
  ) {
    return this.service.atribuirPermissoes(t, id, dto.permissoes);
  }
}
EOF

cat > src/modules/roles/roles.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { RolesController } from './roles.controller';
import { RolesService } from './roles.service';

@Module({
  controllers: [RolesController],
  providers: [RolesService],
  exports: [RolesService],
})
export class RolesModule {}
EOF

# ============================================================
# 4. USERS MODULE
# ============================================================
cat > src/modules/users/dto/create-user.dto.ts <<'EOF'
import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayUnique, IsArray, IsEmail, IsOptional, IsString, IsUUID, MaxLength, MinLength,
} from 'class-validator';

export class CreateUserDto {
  @ApiProperty({ example: 'Maria Silva' })
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  nome: string;

  @ApiProperty({ example: 'maria@escritorio.com' })
  @IsEmail()
  email: string;

  @ApiProperty({ minLength: 8 })
  @IsString()
  @MinLength(8)
  senha: string;

  @ApiProperty({ type: [String], required: false })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  roleIds?: string[];
}
EOF

cat > src/modules/users/dto/update-user.dto.ts <<'EOF'
import { ApiProperty } from '@nestjs/swagger';
import {
  ArrayUnique, IsArray, IsEmail, IsOptional, IsString, IsUUID, MaxLength, MinLength,
} from 'class-validator';

export class UpdateUserDto {
  @ApiProperty({ required: false })
  @IsOptional()
  @IsString()
  @MinLength(3)
  @MaxLength(200)
  nome?: string;

  @ApiProperty({ required: false })
  @IsOptional()
  @IsEmail()
  email?: string;

  @ApiProperty({ type: [String], required: false })
  @IsOptional()
  @IsArray()
  @ArrayUnique()
  @IsUUID('4', { each: true })
  roleIds?: string[];
}
EOF

cat > src/modules/users/dto/change-password.dto.ts <<'EOF'
import { ApiProperty } from '@nestjs/swagger';
import { IsString, MinLength } from 'class-validator';

export class ChangePasswordDto {
  @ApiProperty()
  @IsString()
  @MinLength(8)
  senhaAtual: string;

  @ApiProperty()
  @IsString()
  @MinLength(8)
  novaSenha: string;
}
EOF

cat > src/modules/users/users.service.ts <<'EOF'
import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
  UnauthorizedException,
} from '@nestjs/common';
import * as argon2 from 'argon2';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';

@Injectable()
export class UsersService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string) {
    const users = await this.prisma.user.findMany({
      where: { tenantId },
      include: {
        userRoles: { include: { role: true } },
      },
      orderBy: { nome: 'asc' },
    });

    return users.map((u) => ({
      id: u.id,
      nome: u.nome,
      email: u.email,
      status: u.status,
      ultimoAcesso: u.ultimoAcesso,
      roles: u.userRoles.map((ur) => ({
        id: ur.role.id,
        nome: ur.role.nome,
      })),
      createdAt: u.createdAt,
    }));
  }

  async buscarPorId(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({
      where: { id, tenantId },
      include: { userRoles: { include: { role: true } } },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    return {
      id: user.id,
      nome: user.nome,
      email: user.email,
      status: user.status,
      ultimoAcesso: user.ultimoAcesso,
      roles: user.userRoles.map((ur) => ({ id: ur.role.id, nome: ur.role.nome })),
    };
  }

  async criar(tenantId: string, dto: CreateUserDto) {
    const existente = await this.prisma.user.findFirst({
      where: { tenantId, email: dto.email },
    });
    if (existente) throw new ConflictException('Email já cadastrado neste tenant');

    if (dto.roleIds?.length) {
      await this.validarRoles(tenantId, dto.roleIds);
    }

    const senhaHash = await argon2.hash(dto.senha);

    const user = await this.prisma.$transaction(async (tx) => {
      const novo = await tx.user.create({
        data: {
          tenantId,
          nome: dto.nome,
          email: dto.email,
          senhaHash,
          status: 'ATIVO',
        },
      });

      if (dto.roleIds?.length) {
        await tx.userRole.createMany({
          data: dto.roleIds.map((roleId) => ({ userId: novo.id, roleId })),
        });
      }

      return novo;
    });

    return this.buscarPorId(tenantId, user.id);
  }

  async atualizar(tenantId: string, id: string, dto: UpdateUserDto) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    if (dto.email && dto.email !== user.email) {
      const existente = await this.prisma.user.findFirst({
        where: { tenantId, email: dto.email, NOT: { id } },
      });
      if (existente) throw new ConflictException('Email já cadastrado');
    }

    if (dto.roleIds?.length) {
      await this.validarRoles(tenantId, dto.roleIds);
    }

    return this.prisma.$transaction(async (tx) => {
      await tx.user.update({
        where: { id },
        data: { nome: dto.nome, email: dto.email },
      });

      if (dto.roleIds) {
        await tx.userRole.deleteMany({ where: { userId: id } });
        if (dto.roleIds.length) {
          await tx.userRole.createMany({
            data: dto.roleIds.map((roleId) => ({ userId: id, roleId })),
          });
        }
      }

      return this.buscarPorId(tenantId, id);
    });
  }

  async ativar(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    await this.prisma.user.update({ where: { id }, data: { status: 'ATIVO' } });
    return { message: 'Usuário ativado' };
  }

  async desativar(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    await this.prisma.user.update({ where: { id }, data: { status: 'INATIVO' } });
    return { message: 'Usuário desativado' };
  }

  async alterarSenha(tenantId: string, userId: string, dto: ChangePasswordDto) {
    const user = await this.prisma.user.findFirst({
      where: { id: userId, tenantId },
    });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const confere = await argon2.verify(user.senhaHash, dto.senhaAtual);
    if (!confere) throw new UnauthorizedException('Senha atual incorreta');

    await this.prisma.user.update({
      where: { id: userId },
      data: { senhaHash: await argon2.hash(dto.novaSenha) },
    });

    return { message: 'Senha alterada com sucesso' };
  }

  async resetarSenha(tenantId: string, id: string) {
    const user = await this.prisma.user.findFirst({ where: { id, tenantId } });
    if (!user) throw new NotFoundException('Usuário não encontrado');

    const senhaTemporaria = this.gerarSenhaTemporaria();
    await this.prisma.user.update({
      where: { id },
      data: { senhaHash: await argon2.hash(senhaTemporaria) },
    });

    return {
      message: 'Senha resetada. Envie a senha temporária ao usuário.',
      senhaTemporaria,
    };
  }

  private async validarRoles(tenantId: string, roleIds: string[]) {
    const roles = await this.prisma.role.findMany({
      where: { tenantId, id: { in: roleIds } },
    });
    if (roles.length !== roleIds.length) {
      throw new BadRequestException('Um ou mais perfis são inválidos');
    }
  }

  private gerarSenhaTemporaria(): string {
    const chars = 'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnpqrstuvwxyz23456789';
    let senha = '';
    for (let i = 0; i < 12; i++) {
      senha += chars.charAt(Math.floor(Math.random() * chars.length));
    }
    return senha;
  }
}
EOF

cat > src/modules/users/users.controller.ts <<'EOF'
import {
  Body,
  Controller,
  Delete,
  Get,
  Param,
  ParseUUIDPipe,
  Patch,
  Post,
  Put,
} from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { UsersService } from './users.service';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { ChangePasswordDto } from './dto/change-password.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { CurrentUser } from '../../common/decorators/current-user.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('users')
@ApiBearerAuth()
@Controller('users')
export class UsersController {
  constructor(private readonly service: UsersService) {}

  @Get()
  @RequirePermissions(PERMISSIONS.USUARIO_VER)
  @ApiOperation({ summary: 'Lista usuários do tenant' })
  listar(@CurrentTenant() tenantId: string) {
    return this.service.listar(tenantId);
  }

  @Get(':id')
  @RequirePermissions(PERMISSIONS.USUARIO_VER)
  buscar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.buscarPorId(t, id);
  }

  @Post()
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  @ApiOperation({ summary: 'Cria novo usuário' })
  criar(@CurrentTenant() t: string, @Body() dto: CreateUserDto) {
    return this.service.criar(t, dto);
  }

  @Patch(':id')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  atualizar(
    @CurrentTenant() t: string,
    @Param('id', ParseUUIDPipe) id: string,
    @Body() dto: UpdateUserDto,
  ) {
    return this.service.atualizar(t, id, dto);
  }

  @Post(':id/ativar')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  ativar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.ativar(t, id);
  }

  @Post(':id/desativar')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  desativar(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.desativar(t, id);
  }

  @Post(':id/resetar-senha')
  @RequirePermissions(PERMISSIONS.USUARIO_GERENCIAR)
  @ApiOperation({ summary: 'Reseta a senha do usuário (retorna senha temporária)' })
  resetarSenha(@CurrentTenant() t: string, @Param('id', ParseUUIDPipe) id: string) {
    return this.service.resetarSenha(t, id);
  }

  @Put('me/senha')
  @ApiOperation({ summary: 'Usuário altera a própria senha' })
  alterarMinhaSenha(
    @CurrentTenant() t: string,
    @CurrentUser('id') userId: string,
    @Body() dto: ChangePasswordDto,
  ) {
    return this.service.alterarSenha(t, userId, dto);
  }
}
EOF

cat > src/modules/users/users.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { UsersController } from './users.controller';
import { UsersService } from './users.service';

@Module({
  controllers: [UsersController],
  providers: [UsersService],
  exports: [UsersService],
})
export class UsersModule {}
EOF

# ============================================================
# 5. ATUALIZAR AUTH.SERVICE (criar roles padrão no registro)
# ============================================================
cat > src/modules/auth/auth.service.ts <<'EOF'
import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RolesService } from '../roles/roles.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
    private readonly roles: RolesService,
  ) {}

  async login(dto: LoginDto) {
    const user: any = await this.prisma.user.findFirst({
      where: { email: dto.email },
      include: {
        tenant: true,
        userRoles: {
          include: { role: { include: { rolePermissions: { include: { permission: true } } } } },
        },
      },
    });

    if (!user || user.status !== 'ATIVO') throw new UnauthorizedException('Credenciais inválidas');
    if (!(await argon2.verify(user.senhaHash, dto.senha))) throw new UnauthorizedException('Credenciais inválidas');

    const permissions: string[] = user.userRoles.flatMap((ur: any) =>
      ur.role.rolePermissions.map((rp: any) => rp.permission.codigo),
    );

    const payload = { sub: user.id, email: user.email, tenantId: user.tenantId, permissions };
    const accessToken = await this.jwt.signAsync(payload);
    const refreshToken = await this.jwt.signAsync(payload, {
      secret: this.config.get<string>('jwt.refreshSecret'),
      expiresIn: this.config.get<string>('jwt.refreshExpiresIn'),
    });

    await this.prisma.user.update({ where: { id: user.id }, data: { ultimoAcesso: new Date() } });

    return {
      accessToken,
      refreshToken,
      user: {
        id: user.id,
        nome: user.nome,
        email: user.email,
        tenantId: user.tenantId,
        tenantNome: user.tenant.nome,
        permissions,
      },
    };
  }

  async register(dto: RegisterDto) {
    if (await this.prisma.tenant.findUnique({ where: { cnpj: dto.cnpjTenant } }))
      throw new ConflictException('CNPJ já cadastrado');

    return this.prisma.$transaction(async (tx) => {
      const tenant = await tx.tenant.create({
        data: { nome: dto.nomeTenant, cnpj: dto.cnpjTenant, email: dto.email, status: 'ATIVO' },
      });

      const user = await tx.user.create({
        data: {
          tenantId: tenant.id,
          nome: dto.nome,
          email: dto.email,
          senhaHash: await argon2.hash(dto.senha),
          status: 'ATIVO',
        },
      });

      // Cria os 4 perfis padrão e vincula o usuário ao admin
      await this.roles.criarRolesPadrao(tx, tenant.id, user.id);

      return { tenantId: tenant.id, userId: user.id };
    });
  }

  async refresh(refreshToken: string) {
    try {
      const p: any = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.get<string>('jwt.refreshSecret'),
      });
      return {
        accessToken: await this.jwt.signAsync({
          sub: p.sub, email: p.email, tenantId: p.tenantId, permissions: p.permissions,
        }),
      };
    } catch {
      throw new UnauthorizedException('Refresh token inválido');
    }
  }
}
EOF

# Ajustar o AuthModule para importar RolesModule
cat > src/modules/auth/auth.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { JwtModule } from '@nestjs/jwt';
import { PassportModule } from '@nestjs/passport';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { AuthController } from './auth.controller';
import { AuthService } from './auth.service';
import { JwtStrategy } from './strategies/jwt.strategy';
import { RefreshStrategy } from './strategies/refresh.strategy';
import { RolesModule } from '../roles/roles.module';

@Module({
  imports: [
    PassportModule,
    RolesModule,
    JwtModule.registerAsync({
      imports: [ConfigModule],
      inject: [ConfigService],
      useFactory: (config: ConfigService) => ({
        secret: config.get<string>('jwt.secret'),
        signOptions: { expiresIn: config.get<string>('jwt.expiresIn') },
      }),
    }),
  ],
  controllers: [AuthController],
  providers: [AuthService, JwtStrategy, RefreshStrategy],
  exports: [AuthService],
})
export class AuthModule {}
EOF

# ============================================================
# 6. ATUALIZAR APP.MODULE
# ============================================================
cat > src/app.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

import configuration from './config/configuration';
import { PrismaModule } from './infra/prisma/prisma.module';
import { RedisModule } from './infra/redis/redis.module';
import { S3Module } from './infra/s3/s3.module';
import { QueueModule } from './infra/queue/queue.module';

import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { RolesModule } from './modules/roles/roles.module';
import { PermissionsModule } from './modules/permissions/permissions.module';
import { AuditModule } from './modules/audit/audit.module';
import { HealthModule } from './modules/health/health.module';

import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { PermissionsGuard } from './common/guards/permissions.guard';
import { TenantContextInterceptor } from './common/interceptors/tenant-context.interceptor';
import { AuditInterceptor } from './common/interceptors/audit.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, load: [configuration],
      envFilePath: ['.env', '.env.local'], cache: true,
    }),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [{
        ttl: (config.get<number>('throttle.ttl') ?? 60) * 1000,
        limit: config.get<number>('throttle.limit') ?? 120,
      }],
    }),
    PrismaModule, RedisModule, S3Module, QueueModule,
    AuditModule,
    AuthModule,
    UsersModule,
    RolesModule,
    PermissionsModule,
    HealthModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
    { provide: APP_INTERCEPTOR, useClass: TenantContextInterceptor },
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ],
})
export class AppModule {}
EOF

echo ""
echo "✅ Pacote F2 instalado!"
echo ""
echo "Próximos passos:"
echo "  1. npx prisma generate"
echo "  2. npm run build"
echo "  3. npm run dev"
echo "  4. Testar endpoints de users, roles e permissions"
EOF