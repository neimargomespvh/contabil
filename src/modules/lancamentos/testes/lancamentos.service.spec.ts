import { Test } from '@nestjs/testing';
import { BadRequestException } from '@nestjs/common';
import { LancamentosService } from '../lancamentos.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { PartidasDobradasValidator } from '../validators/partidas-dobradas.validator';
import { TipoPartidaDto } from '../dto/create-partida.dto';
import { CreateLancamentoDto } from '../dto/create-lancamento.dto';

describe('LancamentosService', () => {
  let service: LancamentosService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      lancamento: {
        create: jest.fn(),
        findFirst: jest.fn(),
        findMany: jest.fn(),
      },
      fechamentoPeriodo: { findUnique: jest.fn().mockResolvedValue(null) },
      $transaction: jest.fn((fn: any) => fn(prisma)),
    };

    const module = await Test.createTestingModule({
      providers: [
        LancamentosService,
        PartidasDobradasValidator,
        { provide: PrismaService, useValue: prisma },
      ],
    }).compile();

    service = module.get(LancamentosService);
  });

  const dtoValido: CreateLancamentoDto = {
    empresaId: 'e1',
    dataLancamento: '2026-09-18',
    competencia: '2026-09-01',
    historico: 'Lançamento de teste',
    partidas: [
      { contaId: 'c1', tipo: TipoPartidaDto.D, valor: 100 },
      { contaId: 'c2', tipo: TipoPartidaDto.C, valor: 100 },
    ],
  };

  it('cria lançamento válido', async () => {
    prisma.lancamento.create.mockResolvedValue({ id: 'l1' });
    const resultado = await service.criar('t1', dtoValido);
    expect(resultado.id).toBe('l1');
  });

  it('rejeita partidas desbalanceadas', async () => {
    const dtoInvalido: CreateLancamentoDto = {
      ...dtoValido,
      partidas: [
        { contaId: 'c1', tipo: TipoPartidaDto.D, valor: 100 },
        { contaId: 'c2', tipo: TipoPartidaDto.C, valor: 50 },
      ],
    };

    await expect(service.criar('t1', dtoInvalido)).rejects.toThrow(BadRequestException);
  });

  it('rejeita lançamento com menos de 2 partidas', async () => {
    const dtoInvalido: CreateLancamentoDto = {
      ...dtoValido,
      partidas: [{ contaId: 'c1', tipo: TipoPartidaDto.D, valor: 100 }],
    };

    await expect(service.criar('t1', dtoInvalido)).rejects.toThrow(BadRequestException);
  });

  it('rejeita período fechado', async () => {
    prisma.fechamentoPeriodo.findUnique.mockResolvedValue({ status: 'FECHADO' });
    await expect(service.criar('t1', dtoValido)).rejects.toThrow(BadRequestException);
  });
});
