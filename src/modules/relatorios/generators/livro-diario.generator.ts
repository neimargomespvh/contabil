import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { LinhaLivroDiario } from './tipos';

@Injectable()
export class LivroDiarioGenerator {
  constructor(private readonly prisma: PrismaService) {}

  async gerar(
    tenantId: string,
    empresaId: string,
    dataInicio: Date,
    dataFim: Date,
  ): Promise<{ linhas: LinhaLivroDiario[]; totais: any }> {
    const lancamentos = await this.prisma.lancamento.findMany({
      where: {
        tenantId,
        empresaId,
        status: 'ATIVO',
        dataLancamento: { gte: dataInicio, lte: dataFim },
      },
      include: {
        partidas: {
          include: { conta: { select: { codigo: true, nome: true } } },
          orderBy: { tipo: 'asc' },
        },
      },
      orderBy: [{ dataLancamento: 'asc' }, { numero: 'asc' }],
    });

    let totDeb = 0;
    let totCred = 0;

    const linhas: LinhaLivroDiario[] = lancamentos.map((l) => {
      const partidas = l.partidas.map((p) => {
        const v = Number(p.valor);
        if (p.tipo === 'D') totDeb += v;
        else totCred += v;
        return {
          conta: p.conta.codigo,
          nomeConta: p.conta.nome,
          tipo: p.tipo as 'D' | 'C',
          valor: Number(v.toFixed(2)),
        };
      });

      return {
        numero: Number(l.numero),
        data: l.dataLancamento,
        historico: l.historico,
        documentoRef: l.documentoRef ?? undefined,
        partidas,
        valorTotal: Number(Number(l.valorTotal).toFixed(2)),
      };
    });

    return {
      linhas,
      totais: {
        lancamentos: linhas.length,
        debitos: Number(totDeb.toFixed(2)),
        creditos: Number(totCred.toFixed(2)),
        equilibrado: Math.abs(totDeb - totCred) < 0.01,
      },
    };
  }
}
