import { Test } from '@nestjs/testing';
import { MatchService } from '../services/match.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('MatchService', () => {
  let service: MatchService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      contaBancaria: { findFirst: jest.fn().mockResolvedValue({ id: 'cb1', empresaId: 'e1' }) },
      extratoBancario: {
        findMany: jest.fn().mockResolvedValue([]),
        update: jest.fn(),
      },
      lancamento: { findMany: jest.fn().mockResolvedValue([]) },
    };

    const module = await Test.createTestingModule({
      providers: [MatchService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(MatchService);
  });

  it('retorna 0 quando não há extratos pendentes', async () => {
    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(0);
  });

  it('concilia quando valor e data batem', async () => {
    const data = new Date('2026-09-15');
    prisma.extratoBancario.findMany.mockResolvedValue([
      { id: 'ex1', valor: 100, dataMovimento: data, conciliado: false, descricao: 'X' },
    ]);
    prisma.lancamento.findMany.mockResolvedValue([
      { id: 'l1', valorTotal: 100, dataLancamento: data },
    ]);
    prisma.extratoBancario.update.mockResolvedValue({});

    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(1);
  });

  it('não concilia valores diferentes', async () => {
    const data = new Date('2026-09-15');
    prisma.extratoBancario.findMany.mockResolvedValue([
      { id: 'ex1', valor: 100, dataMovimento: data, conciliado: false, descricao: 'X' },
    ]);
    prisma.lancamento.findMany.mockResolvedValue([
      { id: 'l1', valorTotal: 200, dataLancamento: data },
    ]);

    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(0);
  });

  it('não concilia datas distantes (>3 dias)', async () => {
    const extratoData = new Date('2026-09-15');
    const lancData = new Date('2026-09-25');
    prisma.extratoBancario.findMany.mockResolvedValue([
      { id: 'ex1', valor: 100, dataMovimento: extratoData, conciliado: false, descricao: 'X' },
    ]);
    prisma.lancamento.findMany.mockResolvedValue([
      { id: 'l1', valorTotal: 100, dataLancamento: lancData },
    ]);

    const r = await service.conciliarAutomaticamente('t1', 'cb1');
    expect(r).toBe(0);
  });
});
