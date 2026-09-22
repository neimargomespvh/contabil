import { Test } from '@nestjs/testing';
import { DreGenerator } from '../generators/dre.generator';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('DreGenerator', () => {
  let gen: DreGenerator;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      planoContas: { findFirst: jest.fn() },
      conta: { findMany: jest.fn() },
      partida: { groupBy: jest.fn() },
    };

    const m = await Test.createTestingModule({
      providers: [DreGenerator, { provide: PrismaService, useValue: prisma }],
    }).compile();
    gen = m.get(DreGenerator);
  });

  it('retorna linhas vazias se não há plano', async () => {
    prisma.planoContas.findFirst.mockResolvedValue(null);
    const r = await gen.gerar('t1', 'e1', new Date(), new Date());
    expect(r.linhas).toEqual([]);
  });

  it('calcula DRE com receitas e despesas', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findMany.mockResolvedValue([
      { id: 'c1', natureza: 'RECEITA', dreLinha: 'RECEITA_BRUTA', codigo: '3.1.1' },
      { id: 'c2', natureza: 'DESPESA', dreLinha: 'DESPESAS_ADMIN', codigo: '5.1.2' },
    ]);
    prisma.partida.groupBy.mockResolvedValue([
      { contaId: 'c1', tipo: 'C', _sum: { valor: 10000 } },
      { contaId: 'c2', tipo: 'D', _sum: { valor: 3000 } },
    ]);

    const r = await gen.gerar('t1', 'e1', new Date('2026-09-01'), new Date('2026-09-30'));
    expect(r.totais.receitaBruta).toBe(10000);
    const linhaDesp = r.linhas.find((l) => l.linha === 'DESPESAS_ADMIN');
    expect(linhaDesp?.valor).toBe(-3000);
  });

  it('calcula margem líquida', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findMany.mockResolvedValue([
      { id: 'c1', natureza: 'RECEITA', dreLinha: 'RECEITA_BRUTA', codigo: '3.1.1' },
    ]);
    prisma.partida.groupBy.mockResolvedValue([
      { contaId: 'c1', tipo: 'C', _sum: { valor: 1000 } },
    ]);

    const r = await gen.gerar('t1', 'e1', new Date(), new Date());
    expect(r.totais.margemLiquida).toBe(100);
  });
});
