import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { LinhaBalanco } from './tipos';

@Injectable()
export class BalancoGenerator {
  constructor(private readonly prisma: PrismaService) {}

  async gerar(tenantId: string, empresaId: string, dataFim: Date) {
    const plano = await this.prisma.planoContas.findFirst({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { versao: 'desc' },
    });
    if (!plano) return { ativo: [], passivo: [], patrimonioLiquido: [], totais: {} };

    const contas = await this.prisma.conta.findMany({
      where: {
        tenantId,
        planoContasId: plano.id,
        natureza: { in: ['ATIVO', 'PASSIVO', 'PATRIMONIO_LIQUIDO'] },
        status: 'ATIVO',
      },
      orderBy: { codigo: 'asc' },
    });

    // Saldo por conta até dataFim
    const partidas = await this.prisma.partida.groupBy({
      by: ['contaId', 'tipo'],
      where: {
        tenantId,
        lancamento: {
          empresaId,
          status: 'ATIVO',
          dataLancamento: { lte: dataFim },
        },
      },
      _sum: { valor: true },
    });

    const saldos = new Map<string, number>();
    for (const p of partidas) {
      const atual = saldos.get(p.contaId) ?? 0;
      const v = Number(p._sum.valor ?? 0);
      saldos.set(p.contaId, p.tipo === 'D' ? atual + v : atual - v);
    }

    // Calcular saldo hierárquico (soma filhos em pais)
    const saldosFinais = new Map<string, number>();
    for (const c of contas) {
      const saldoDireto = saldos.get(c.id) ?? 0;
      saldosFinais.set(c.id, saldoDireto);
    }

    // Propagação para cima (conta filha → pai)
    const contasOrdenadas = [...contas].sort((a, b) => b.grau - a.grau);
    for (const c of contasOrdenadas) {
      if (c.contaPaiId) {
        const saldoFilho = saldosFinais.get(c.id) ?? 0;
        // Só propaga se o pai não tem lançamento direto (analítica)
        const pai = contas.find((x) => x.id === c.contaPaiId);
        if (pai) {
          const saldoPai = saldosFinais.get(pai.id) ?? 0;
          saldosFinais.set(pai.id, saldoPai + saldoFilho);
        }
      }
    }

    const ativo: LinhaBalanco[] = [];
    const passivo: LinhaBalanco[] = [];
    const patrimonioLiquido: LinhaBalanco[] = [];

    for (const c of contas) {
      const saldo = saldosFinais.get(c.id) ?? 0;
      if (Math.abs(saldo) < 0.01) continue;

      const linha: LinhaBalanco = {
        grupo: c.natureza,
        contaId: c.id,
        codigo: c.codigo,
        nome: c.nome,
        valor: Number(saldo.toFixed(2)),
        nivel: c.grau,
      };

      if (c.natureza === 'ATIVO') ativo.push(linha);
      else if (c.natureza === 'PASSIVO') passivo.push(linha);
      else if (c.natureza === 'PATRIMONIO_LIQUIDO') patrimonioLiquido.push(linha);
    }

    const totalAtivo = ativo
      .filter((l) => l.nivel === 1)
      .reduce((s, l) => s + l.valor, 0);
    const totalPassivo = passivo
      .filter((l) => l.nivel === 1)
      .reduce((s, l) => s + l.valor, 0);
    const totalPL = patrimonioLiquido
      .filter((l) => l.nivel === 1)
      .reduce((s, l) => s + l.valor, 0);

    return {
      ativo,
      passivo,
      patrimonioLiquido,
      totais: {
        ativo: Number(totalAtivo.toFixed(2)),
        passivo: Number(totalPassivo.toFixed(2)),
        patrimonioLiquido: Number(totalPL.toFixed(2)),
        passivoMaisPL: Number((totalPassivo + totalPL).toFixed(2)),
        equilibrado: Math.abs(totalAtivo - (totalPassivo + totalPL)) < 0.01,
      },
    };
  }
}
