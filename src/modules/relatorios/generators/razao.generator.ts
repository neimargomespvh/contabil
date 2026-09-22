import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { LinhaRazao } from './tipos';

@Injectable()
export class RazaoGenerator {
  constructor(private readonly prisma: PrismaService) {}

  async gerar(
    tenantId: string,
    contaId: string,
    dataInicio: Date,
    dataFim: Date,
  ): Promise<{ conta: any; linhas: LinhaRazao[]; saldoFinal: number }> {
    const conta = await this.prisma.conta.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta não encontrada');

    // Saldo anterior
    const anteriores = await this.prisma.partida.findMany({
      where: {
        tenantId,
        contaId,
        lancamento: {
          status: 'ATIVO',
          dataLancamento: { lt: dataInicio },
        },
      },
      include: { lancamento: true },
    });

    let saldoInicial = 0;
    for (const p of anteriores) {
      const v = Number(p.valor);
      saldoInicial += p.tipo === 'D' ? v : -v;
    }

    // Movimentação no período
    const partidas = await this.prisma.partida.findMany({
      where: {
        tenantId,
        contaId,
        lancamento: {
          status: 'ATIVO',
          dataLancamento: { gte: dataInicio, lte: dataFim },
        },
      },
      include: {
        lancamento: {
          select: { id: true, dataLancamento: true, historico: true, documentoRef: true },
        },
      },
      orderBy: { lancamento: { dataLancamento: 'asc' } },
    });

    let saldo = saldoInicial;
    const linhas: LinhaRazao[] = partidas.map((p) => {
      const v = Number(p.valor);
      const debito = p.tipo === 'D' ? v : 0;
      const credito = p.tipo === 'C' ? v : 0;
      saldo += debito - credito;

      return {
        data: p.lancamento.dataLancamento,
        lancamentoId: p.lancamento.id,
        historico: p.lancamento.historico,
        documentoRef: p.lancamento.documentoRef ?? undefined,
        debito: Number(debito.toFixed(2)),
        credito: Number(credito.toFixed(2)),
        saldoAcumulado: Number(saldo.toFixed(2)),
      };
    });

    return {
      conta: {
        id: conta.id,
        codigo: conta.codigo,
        nome: conta.nome,
        natureza: conta.natureza,
      },
      linhas,
      saldoFinal: Number(saldo.toFixed(2)),
    };
  }
}
