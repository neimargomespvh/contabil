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
