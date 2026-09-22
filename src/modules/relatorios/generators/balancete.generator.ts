import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { LinhaBalancete } from './tipos';

@Injectable()
export class BalanceteGenerator {
  constructor(private readonly prisma: PrismaService) {}

  async gerar(
    tenantId: string,
    empresaId: string,
    dataInicio: Date,
    dataFim: Date,
    incluirZeradas = false,
  ): Promise<{ linhas: LinhaBalancete[]; totais: any }> {
    // 1. Buscar contas do plano ativo
    const plano = await this.prisma.planoContas.findFirst({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { versao: 'desc' },
    });
    if (!plano) return { linhas: [], totais: {} };

    const contas = await this.prisma.conta.findMany({
      where: { tenantId, planoContasId: plano.id, status: 'ATIVO' },
      orderBy: { codigo: 'asc' },
    });

    // 2. Saldo anterior (tudo antes de dataInicio)
    const saldoAnterior = await this.calcularSaldoPorConta(
      tenantId,
      empresaId,
      undefined,
      new Date(dataInicio.getTime() - 1),
    );

    // 3. Movimentação do período
    const movimentacao = await this.prisma.partida.groupBy({
      by: ['contaId', 'tipo'],
      where: {
        tenantId,
        lancamento: {
          empresaId,
          status: 'ATIVO',
          dataLancamento: { gte: dataInicio, lte: dataFim },
        },
      },
      _sum: { valor: true },
    });

    const mapaDeb = new Map<string, number>();
    const mapaCred = new Map<string, number>();
    for (const m of movimentacao) {
      const v = Number(m._sum.valor ?? 0);
      if (m.tipo === 'D') mapaDeb.set(m.contaId, v);
      else mapaCred.set(m.contaId, v);
    }

    // 4. Montar linhas
    const linhas: LinhaBalancete[] = [];
    let totAnterior = 0;
    let totDeb = 0;
    let totCred = 0;

    for (const conta of contas) {
      const saldoAnt = saldoAnterior.get(conta.id) ?? 0;
      const deb = mapaDeb.get(conta.id) ?? 0;
      const cred = mapaCred.get(conta.id) ?? 0;

      // Saldo atual: débito aumenta ativo/despesa; crédito aumenta passivo/receita
      const saldoAtual = this.calcularSaldo(conta.natureza, saldoAnt + deb - cred);

      if (!incluirZeradas && saldoAnt === 0 && deb === 0 && cred === 0) continue;

      linhas.push({
        contaId: conta.id,
        codigo: conta.codigo,
        nome: conta.nome,
        natureza: conta.natureza,
        grau: conta.grau,
        saldoAnterior: Number(saldoAnt.toFixed(2)),
        debitos: Number(deb.toFixed(2)),
        creditos: Number(cred.toFixed(2)),
        saldoAtual: Number(saldoAtual.toFixed(2)),
      });

      totAnterior += saldoAnt;
      totDeb += deb;
      totCred += cred;
    }

    return {
      linhas,
      totais: {
        saldoAnterior: Number(totAnterior.toFixed(2)),
        debitos: Number(totDeb.toFixed(2)),
        creditos: Number(totCred.toFixed(2)),
        saldoAtual: Number((totAnterior + totDeb - totCred).toFixed(2)),
      },
    };
  }

  private async calcularSaldoPorConta(
    tenantId: string,
    empresaId: string,
    dataInicio: Date | undefined,
    dataFim: Date,
  ): Promise<Map<string, number>> {
    const partidas = await this.prisma.partida.groupBy({
      by: ['contaId', 'tipo'],
      where: {
        tenantId,
        lancamento: {
          empresaId,
          status: 'ATIVO',
          ...(dataInicio && { dataLancamento: { gte: dataInicio } }),
          dataLancamento: { lte: dataFim },
        },
      },
      _sum: { valor: true },
    });

    const saldo = new Map<string, number>();
    for (const p of partidas) {
      const atual = saldo.get(p.contaId) ?? 0;
      const v = Number(p._sum.valor ?? 0);
      saldo.set(p.contaId, p.tipo === 'D' ? atual + v : atual - v);
    }
    return saldo;
  }

  private calcularSaldo(natureza: string, movDebMenosCred: number): number {
    if (natureza === 'ATIVO' || natureza === 'DESPESA' || natureza === 'CUSTO') {
      return movDebMenosCred;
    }
    // PASSIVO, PL, RECEITA → saldo credor (inverte)
    return -movDebMenosCred;
  }
}
