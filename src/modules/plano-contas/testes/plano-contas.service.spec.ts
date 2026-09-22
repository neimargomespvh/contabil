import { Test } from '@nestjs/testing';
import { BadRequestException, ConflictException, NotFoundException } from '@nestjs/common';
import { PlanoContasService } from '../plano-contas.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { NaturezaContaEnum, TipoContaEnum } from '../dto/create-conta.dto';

describe('PlanoContasService', () => {
  let service: PlanoContasService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      empresa: { findFirst: jest.fn().mockResolvedValue({ id: 'e1' }) },
      planoContas: {
        findFirst: jest.fn(),
        findMany: jest.fn(),
        create: jest.fn(),
      },
      conta: {
        findFirst: jest.fn(),
        findMany: jest.fn().mockResolvedValue([]),
        create: jest.fn(),
        count: jest.fn().mockResolvedValue(0),
        delete: jest.fn(),
        update: jest.fn(),
      },
      partida: { count: jest.fn().mockResolvedValue(0) },
      $transaction: jest.fn(async (fn: any) => fn(prisma)),
    };

    const module = await Test.createTestingModule({
      providers: [PlanoContasService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(PlanoContasService);
  });

  it('cria plano vazio com versão incremental', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ versao: 2 });
    prisma.planoContas.create.mockResolvedValue({ id: 'p3', versao: 3 });

    const r = await service.criarPlano('t1', 'e1', {
      nome: 'Plano 2026',
      vigenciaInicio: '2026-01-01',
    });
    expect(r.versao).toBe(3);
  });

  it('rejeita empresa inexistente', async () => {
    prisma.empresa.findFirst.mockResolvedValue(null);
    await expect(
      service.criarPlano('t1', 'inexistente', {
        nome: 'Plano',
        vigenciaInicio: '2026-01-01',
      }),
    ).rejects.toThrow(NotFoundException);
  });

  it('rejeita código duplicado ao criar conta', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findFirst.mockResolvedValue({ id: 'existente' });

    await expect(
      service.criarConta('t1', 'p1', {
        codigo: '1.1.1.01',
        nome: 'Caixa',
        natureza: NaturezaContaEnum.ATIVO,
        tipo: TipoContaEnum.ANALITICA,
      }),
    ).rejects.toThrow(ConflictException);
  });

  it('rejeita conta filha cujo código não começa com o do pai', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findFirst
      .mockResolvedValueOnce(null) // existe código?
      .mockResolvedValueOnce({ id: 'pai', codigo: '1.1', tipo: 'SINTETICA', grau: 2 });

    await expect(
      service.criarConta('t1', 'p1', {
        codigo: '2.1.1',
        nome: 'Errado',
        natureza: NaturezaContaEnum.ATIVO,
        tipo: TipoContaEnum.ANALITICA,
        contaPaiId: 'pai',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('rejeita conta filha de conta analítica', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findFirst
      .mockResolvedValueOnce(null)
      .mockResolvedValueOnce({ id: 'pai', codigo: '1.1', tipo: 'ANALITICA', grau: 2 });

    await expect(
      service.criarConta('t1', 'p1', {
        codigo: '1.1.1',
        nome: 'Errado',
        natureza: NaturezaContaEnum.ATIVO,
        tipo: TipoContaEnum.ANALITICA,
        contaPaiId: 'pai',
      }),
    ).rejects.toThrow(BadRequestException);
  });

  it('não remove conta com filhas', async () => {
    prisma.conta.findFirst.mockResolvedValue({ id: 'c1' });
    prisma.conta.count.mockResolvedValue(2);

    await expect(service.removerConta('t1', 'c1')).rejects.toThrow(BadRequestException);
  });

  it('não remove conta com partidas', async () => {
    prisma.conta.findFirst.mockResolvedValue({ id: 'c1' });
    prisma.conta.count.mockResolvedValue(0);
    prisma.partida.count.mockResolvedValue(5);

    await expect(service.removerConta('t1', 'c1')).rejects.toThrow(BadRequestException);
  });
});
