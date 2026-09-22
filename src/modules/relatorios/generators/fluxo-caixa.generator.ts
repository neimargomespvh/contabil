import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { LinhaFluxoCaixa } from './tipos';

@Injectable()
export class FluxoCaixaGenerator {
  constructor(private readonly prisma: PrismaService) {}

  async gerar(
    tenantId: string,
    empresaId: string,
    dataInicio: Date,
    dataFim: Date,
    contaBancariaId?: string,
  ) {
    const where: any = {
      tenantId,
      lancamento: {
        empresaId,
        status: 'ATIVO',
        dataLancamento: { gte: dataInicio, lte: dataFim },
      },
    };
    if (contaBancariaId) {
      where.contaBancariaId = contaBancariaId;
    }

    const movimentacoes = await this.prisma.extratoBancario.findMany({
      where: {
        tenantId,
        ...(contaBancariaId && { contaBancariaId }),
        dataMovimento: { gte: dataInicio, lte: dataFim },
      },
      orderBy: { dataMovimento: 'asc' },
    });

    // Saldo inicial (tudo antes do período)
    const anteriores = await this.prisma.extratoBancario.aggregate({
      where: {
        tenantId,
        ...(contaBancariaId && { contaBancariaId }),
        dataMovimento: { lt: dataInicio },
      },
      _sum: { valor: true },
    });

    let saldo = Number(anteriores._sum.valor ?? 0);
    const saldoInicial = saldo;

    let totEntradas = 0;
    let totSaidas = 0;

    const linhas: LinhaFluxoCaixa[] = movimentacoes.map((m) => {
      const v = Number(m.valor);
      const entrada = v > 0 ? v : 0;
      const saida = v < 0 ? Math.abs(v) : 0;
      saldo += v;
      totEntradas += entrada;
      totSaidas += saida;

      return {
        data: m.dataMovimento,
        descricao: m.descricao ?? '',
        entrada: Number(entrada.toFixed(2)),
        saida: Number(saida.toFixed(2)),
        saldoAcumulado: Number(saldo.toFixed(2)),
      };
    });

    return {
      linhas,
      totais: {
        saldoInicial: Number(saldoInicial.toFixed(2)),
        entradas: Number(totEntradas.toFixed(2)),
        saidas: Number(totSaidas.toFixed(2)),
        saldoFinal: Number(saldo.toFixed(2)),
      },
    };
  }
}
