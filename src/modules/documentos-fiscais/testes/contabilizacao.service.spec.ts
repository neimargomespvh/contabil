import { Test } from '@nestjs/testing';
import { ContabilizacaoService } from '../services/contabilizacao.service';
import { PrismaService } from '../../../infra/prisma/prisma.service';

describe('ContabilizacaoService', () => {
  let service: ContabilizacaoService;
  let prisma: any;

  beforeEach(async () => {
    prisma = {
      regraContabilizacao: { findMany: jest.fn() },
      lancamento: { create: jest.fn() },
      documentoFiscal: { update: jest.fn() },
      $transaction: jest.fn(async (fn: any) => fn(prisma)),
    };

    const module = await Test.createTestingModule({
      providers: [ContabilizacaoService, { provide: PrismaService, useValue: prisma }],
    }).compile();

    service = module.get(ContabilizacaoService);
  });

  const docFake = {
    tipo: 'NFE' as const,
    chaveAcesso: '35240612345678901234550010000001231234567890',
    numero: '123',
    serie: '1',
    modelo: '55',
    emitenteCnpj: '12345678901234',
    emitenteNome: 'Fornecedor X',
    dataEmissao: new Date('2026-09-15'),
    valorTotal: 1000,
    cfopPrincipal: '5102',
    ncmPrincipal: '12345678',
    itens: [],
    xmlRaw: '',
  };

  it('retorna null quando não há regra aplicável', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([]);
    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);
    expect(r).toBeNull();
  });

  it('contabiliza com regra por CFOP', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'Compra mercadoria',
        prioridade: 1,
        condicao: { tipo: 'NFE', cfop: ['5102', '6102'] },
        contaDebitoId: 'c-estoque',
        contaCreditoId: 'c-fornecedor',
        historicoTemplate: 'NF {numero}/{serie} - {emitente}',
      },
    ]);
    prisma.lancamento.create.mockResolvedValue({ id: 'l1' });
    prisma.documentoFiscal.update.mockResolvedValue({});

    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);

    expect(r).toBe('l1');
    const chamada = prisma.lancamento.create.mock.calls[0][0];
    expect(chamada.data.historico).toContain('123/1');
    expect(chamada.data.historico).toContain('Fornecedor X');
    expect(chamada.data.partidas.create).toHaveLength(2);
  });

  it('não contabiliza se CFOP do doc não bate com a regra', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'Serviço',
        prioridade: 1,
        condicao: { tipo: 'NFE', cfop: ['5933'] },
        contaDebitoId: 'c1',
        contaCreditoId: 'c2',
        historicoTemplate: null,
      },
    ]);

    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);
    expect(r).toBeNull();
  });

  it('aplica regra por tipo mesmo sem CFOP', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'NFE genérica',
        prioridade: 10,
        condicao: { tipo: 'NFE' },
        contaDebitoId: 'c1',
        contaCreditoId: 'c2',
        historicoTemplate: null,
      },
    ]);
    prisma.lancamento.create.mockResolvedValue({ id: 'l2' });
    prisma.documentoFiscal.update.mockResolvedValue({});

    const r = await service.contabilizar('t1', 'e1', 'doc1', docFake);
    expect(r).toBe('l2');
  });

  it('usa competência = primeiro dia do mês da emissão', async () => {
    prisma.regraContabilizacao.findMany.mockResolvedValue([
      {
        id: 'r1',
        nome: 'X',
        prioridade: 1,
        condicao: {},
        contaDebitoId: 'c1',
        contaCreditoId: 'c2',
        historicoTemplate: null,
      },
    ]);
    prisma.lancamento.create.mockResolvedValue({ id: 'l3' });
    prisma.documentoFiscal.update.mockResolvedValue({});

    await service.contabilizar('t1', 'e1', 'doc1', docFake);

    const chamada = prisma.lancamento.create.mock.calls[0][0];
    const competencia = chamada.data.competencia as Date;
    expect(competencia.getDate()).toBe(1);
    expect(competencia.getMonth()).toBe(8); // setembro (0-indexed)
  });
});
