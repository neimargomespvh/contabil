import { Test } from '@nestjs/testing';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { UnauthorizedException } from '@nestjs/common';
import { AuthService } from '../auth.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { RolesService } from '../../roles/roles.service';

describe('AuthService', () => {
  let service: AuthService;
  let prisma: any;
  let roles: any;

  beforeEach(async () => {
    prisma = {
      user: {
        findFirst: jest.fn(),
        update: jest.fn(),
        create: jest.fn(),
      },
      tenant: {
        findUnique: jest.fn(),
        create: jest.fn(),
      },
      $transaction: jest.fn((fn: any) => fn(prisma)),
    };

    roles = {
      criarRolesPadrao: jest.fn().mockResolvedValue(undefined),
    };

    const module = await Test.createTestingModule({
      providers: [
        AuthService,
        { provide: PrismaService, useValue: prisma },
        { provide: JwtService, useValue: { signAsync: jest.fn().mockResolvedValue('token-jwt') } },
        {
          provide: ConfigService,
          useValue: { get: jest.fn().mockReturnValue('secret-de-teste') },
        },
        { provide: RolesService, useValue: roles },
      ],
    }).compile();

    service = module.get(AuthService);
  });

  it('compila com todas as dependências', () => {
    expect(service).toBeDefined();
  });

  it('login com sucesso retorna tokens e permissões', async () => {
    const senhaHash = await argon2.hash('SenhaForte@123');
    prisma.user.findFirst.mockResolvedValue({
      id: 'u1',
      email: 'teste@escritorio.com',
      senhaHash,
      status: 'ATIVO',
      tenantId: 't1',
      nome: 'Usuário Teste',
      tenant: { id: 't1', nome: 'Escritório Teste' },
      userRoles: [
        {
          role: {
            rolePermissions: [
              { permission: { codigo: 'empresa.ver' } },
              { permission: { codigo: 'lancamento.criar' } },
            ],
          },
        },
      ],
    });
    prisma.user.update.mockResolvedValue({});

    const resultado = await service.login({
      email: 'teste@escritorio.com',
      senha: 'SenhaForte@123',
    });

    expect(resultado.accessToken).toBe('token-jwt');
    expect(resultado.refreshToken).toBe('token-jwt');
    expect(resultado.user.permissions).toEqual(['empresa.ver', 'lancamento.criar']);
  });

  it('login com senha errada lança UnauthorizedException', async () => {
    const senhaHash = await argon2.hash('OutraSenha@123');
    prisma.user.findFirst.mockResolvedValue({
      id: 'u1',
      email: 'teste@escritorio.com',
      senhaHash,
      status: 'ATIVO',
      tenantId: 't1',
      tenant: {},
      userRoles: [],
    });

    await expect(
      service.login({ email: 'teste@escritorio.com', senha: 'SenhaForte@123' }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('login com usuário inativo lança UnauthorizedException', async () => {
    prisma.user.findFirst.mockResolvedValue({
      id: 'u1',
      email: 'teste@escritorio.com',
      senhaHash: 'x',
      status: 'INATIVO',
      tenantId: 't1',
      tenant: {},
      userRoles: [],
    });

    await expect(
      service.login({ email: 'teste@escritorio.com', senha: 'SenhaForte@123' }),
    ).rejects.toThrow(UnauthorizedException);
  });

  it('register cria tenant, usuário e roles padrão', async () => {
    prisma.tenant.findUnique.mockResolvedValue(null);
    prisma.tenant.create.mockResolvedValue({ id: 't-novo' });
    prisma.user.create.mockResolvedValue({ id: 'u-novo' });

    const resultado = await service.register({
      nome: 'Neimar',
      email: 'neimar@teste.com',
      senha: 'SenhaForte@123',
      nomeTenant: 'Escritório Novo',
      cnpjTenant: '11222333000144',
    });

    expect(resultado).toEqual({ tenantId: 't-novo', userId: 'u-novo' });
    expect(roles.criarRolesPadrao).toHaveBeenCalledWith(expect.anything(), 't-novo', 'u-novo');
  });

  it('register rejeita CNPJ duplicado', async () => {
    prisma.tenant.findUnique.mockResolvedValue({ id: 'existente' });

    await expect(
      service.register({
        nome: 'Neimar',
        email: 'neimar@teste.com',
        senha: 'SenhaForte@123',
        nomeTenant: 'Escritório Novo',
        cnpjTenant: '11222333000144',
      }),
    ).rejects.toThrow();
  });
});
