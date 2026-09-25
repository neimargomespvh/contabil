import {
  ConflictException,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

const PERMISSOES_PADRAO = [
  'empresa.criar', 'empresa.editar', 'empresa.excluir', 'empresa.ver',
  'lancamento.criar', 'lancamento.editar', 'lancamento.estornar', 'lancamento.ver',
  'documento.importar', 'documento.ver', 'documento.excluir',
  'conciliacao.executar', 'conciliacao.ver',
  'apuracao.calcular', 'apuracao.ver',
  'relatorio.gerar', 'relatorio.ver',
  'usuario.gerenciar', 'auditoria.ver',
  'regra.criar', 'regra.editar', 'regra.excluir', 'regra.ver',
  'socio.criar', 'socio.editar', 'socio.excluir', 'socio.ver',
  'plano.criar', 'plano.editar', 'plano.excluir', 'plano.ver',
  'plano-contas.criar', 'plano-contas.editar', 'plano-contas.excluir', 'plano-contas.ver',
  'conta.criar', 'conta.editar', 'conta.excluir', 'conta.ver',
  'centro-custo.criar', 'centro-custo.editar', 'centro-custo.excluir', 'centro-custo.ver',
  'conta-bancaria.criar', 'conta-bancaria.editar', 'conta-bancaria.excluir', 'conta-bancaria.ver',
];

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async login(dto: LoginDto) {
    const user = await this.prisma.user.findFirst({
      where: { email: dto.email },
      include: {
        tenant: true,
        userRoles: {
          include: {
            role: {
              include: {
                rolePermissions: { include: { permission: true } },
              },
            },
          },
        },
      },
    });

    if (!user || user.status !== 'ATIVO') {
      throw new UnauthorizedException('Credenciais inválidas');
    }

    const senhaOk = await argon2.verify(user.senhaHash, dto.senha);
    if (!senhaOk) throw new UnauthorizedException('Credenciais inválidas');

    const permissions = user.userRoles.flatMap((ur) =>
      ur.role.rolePermissions.map((rp) => rp.permission.codigo),
    );

    const payload = {
      sub: user.id,
      email: user.email,
      tenantId: user.tenantId,
      permissions,
    };

    const accessToken = await this.jwt.signAsync(payload);
    const refreshToken = await this.jwt.signAsync(payload, {
      secret: this.config.get('jwt.refreshSecret'),
      expiresIn: this.config.get('jwt.refreshExpiresIn'),
    });

    await this.prisma.user.update({
      where: { id: user.id },
      data: { ultimoAcesso: new Date() },
    });

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
    const existente = await this.prisma.tenant.findUnique({
      where: { cnpj: dto.cnpjTenant },
    });
    if (existente) throw new ConflictException('CNPJ já cadastrado');

    return this.prisma.$transaction(async (tx) => {
      const tenant = await tx.tenant.create({
        data: {
          nome: dto.nomeTenant,
          cnpj: dto.cnpjTenant,
          email: dto.email,
          status: 'ATIVO',
        },
      });

      for (const codigo of PERMISSOES_PADRAO) {
        await tx.permission.upsert({
          where: { codigo },
          update: {},
          create: { codigo },
        });
      }

      const role = await tx.role.create({
        data: { tenantId: tenant.id, nome: 'admin', descricao: 'Administrador' },
      });

      const todasPermissoes = await tx.permission.findMany({
        where: { codigo: { in: PERMISSOES_PADRAO } },
      });

      await tx.rolePermission.createMany({
        data: todasPermissoes.map((p) => ({
          roleId: role.id,
          permissionId: p.id,
        })),
        skipDuplicates: true,
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

      await tx.userRole.create({
        data: { userId: user.id, roleId: role.id },
      });

      return { tenantId: tenant.id, userId: user.id };
    });
  }

  async refresh(refreshToken: string) {
    try {
      const payload = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.get('jwt.refreshSecret'),
      });

      const accessToken = await this.jwt.signAsync({
        sub: payload.sub,
        email: payload.email,
        tenantId: payload.tenantId,
        permissions: payload.permissions,
      });

      return { accessToken };
    } catch {
      throw new UnauthorizedException('Refresh token inválido');
    }
  }
}
