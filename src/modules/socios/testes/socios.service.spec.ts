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
