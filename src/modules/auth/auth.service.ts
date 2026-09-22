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
