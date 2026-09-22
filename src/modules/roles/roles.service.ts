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
