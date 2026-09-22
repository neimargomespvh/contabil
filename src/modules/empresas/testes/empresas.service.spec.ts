import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException } from '@nestjs/common';
import { EmpresasService } from '../empresas.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { RegimeTributarioEnum } from '../dto/create-empresa.dto';

describe('EmpresasService', () => {
  let service: EmpresasService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      empresa: {
        findFirst: jest.fn().mockResolvedValue(null),
        findMany: jest.fn().mockResolvedValue([]),
        count: jest.fn().mockResolvedValue(0),
        create: jest.fn(),
        update: jest.fn(),
      },
    };

    const module = await Test.createTestingModule({
      providers: [EmpresasService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(EmpresasService);
  });

  it('cria empresa com CNPJ válido', async () => {
    prisma.empresa.create.mockResolvedValue({ id: 'e1' });
    const r = await service.criar('t1', {
      razaoSocial: 'Empresa Teste LTDA',
      cnpj: '11222333000181',
      regimeTributario: RegimeTributarioEnum.SIMPLES,
    });
    expect(r.id).toBe('e1');
  });

  it('rejeita CNPJ inválido', async () => {
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000182',
        regimeTributario: RegimeTributarioEnum.SIMPLES,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita CNPJ duplicado', async () => {
    prisma.empresa.findFirst.mockResolvedValue({ id: 'existente' });
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000181',
        regimeTributario: RegimeTributarioEnum.SIMPLES,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('rejeita anexo Simples em regime não-SIMPLES', async () => {
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000181',
        regimeTributario: RegimeTributarioEnum.PRESUMIDO,
        anexoSimples: 'I' as any,
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita CPF de responsável inválido', async () => {
    await expect(
      service.criar('t1', {
        razaoSocial: 'Empresa Teste LTDA',
        cnpj: '11222333000181',
        regimeTributario: RegimeTributarioEnum.SIMPLES,
        responsavelCpf: '11111111111',
      }),
    ).rejects.toThrow(BadRequestException);
  });
});
