import { Test } from '@nestjs/testing';
import { BalanceteGenerator } from '../generators/balancete.generator';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('BalanceteGenerator', () => {
  let gen: BalanceteGenerator;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      planoContas: { findFirst: jest.fn() },
      conta: { findMany: jest.fn() },
      partida: { groupBy: jest.fn() },
    };

    const m = await Test.createTestingModule({
      providers: [BalanceteGenerator, { provide: PrismaService, useValue: prisma }],
    }).compile();
    gen = m.get(BalanceteGenerator);
  });

  it('retorna vazio se não há plano ativo', async () => {
    prisma.planoContas.findFirst.mockResolvedValue(null);
    const r = await gen.gerar('t1', 'e1', new Date(), new Date());
    expect(r.linhas).toEqual([]);
  });

  it('calcula débitos e créditos do período', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findMany.mockResolvedValue([
      { id: 'c1', codigo: '1.1.1.01', nome: 'Caixa', natureza: 'ATIVO', grau: 4, status: 'ATIVO' },
    ]);
    // Primeira chamada = saldo anterior; segunda = movimentação
    prisma.partida.groupBy
      .mockResolvedValueOnce([]) // saldo anterior vazio
      .mockResolvedValueOnce([
        { contaId: 'c1', tipo: 'D', _sum: { valor: 1000 } },
        { contaId: 'c1', tipo: 'C', _sum: { valor: 200 } },
      ]);

    const r = await gen.gerar('t1', 'e1', new Date('2026-09-01'), new Date('2026-09-30'));
    expect(r.linhas).toHaveLength(1);
    expect(r.linhas[0].debitos).toBe(1000);
    expect(r.linhas[0].creditos).toBe(200);
    expect(r.linhas[0].saldoAtual).toBe(800);
  });

  it('propaga saldo anterior', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findMany.mockResolvedValue([
      { id: 'c1', codigo: '1.1.1.01', nome: 'Caixa', natureza: 'ATIVO', grau: 4, status: 'ATIVO' },
    ]);
    prisma.partida.groupBy
      .mockResolvedValueOnce([
        { contaId: 'c1', tipo: 'D', _sum: { valor: 500 } },
      ])
      .mockResolvedValueOnce([
        { contaId: 'c1', tipo: 'D', _sum: { valor: 100 } },
      ]);

    const r = await gen.gerar('t1', 'e1', new Date('2026-09-01'), new Date('2026-09-30'));
    expect(r.linhas[0].saldoAnterior).toBe(500);
    expect(r.linhas[0].saldoAtual).toBe(600);
  });

  it('oculta contas zeradas quando solicitado', async () => {
    prisma.planoContas.findFirst.mockResolvedValue({ id: 'p1' });
    prisma.conta.findMany.mockResolvedValue([
      { id: 'c1', codigo: '1.1.1.01', nome: 'Caixa', natureza: 'ATIVO', grau: 4, status: 'ATIVO' },
    ]);
    prisma.partida.groupBy.mockResolvedValue([]);

    const r = await gen.gerar('t1', 'e1', new Date(), new Date(), false);
    expect(r.linhas).toHaveLength(0);
  });
});
