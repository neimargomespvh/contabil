import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';

const TOLERANCIA_VALOR = 0.01; // 1 centavo
const TOLERANCIA_DIAS = 3;

@Injectable()
export class MatchService {
  private readonly logger = new Logger(MatchService.name);

  constructor(private readonly prisma: PrismaService) {}

  /**
   * Tenta conciliar extratos pendentes com lançamentos contábeis.
   * Retorna quantos foram conciliados.
   */
  async conciliarAutomaticamente(tenantId: string, contaBancariaId: string): Promise<number> {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id: contaBancariaId, tenantId },
    });
    if (!conta) return 0;

    // Buscar extratos não conciliados
    const extratos = await this.prisma.extratoBancario.findMany({
      where: { tenantId, contaBancariaId, conciliado: false },
      orderBy: { dataMovimento: 'asc' },
    });

    if (extratos.length === 0) return 0;

    // Buscar lançamentos candidatos (últimos 90 dias)
    const dataMin = extratos[0].dataMovimento;
    dataMin.setDate(dataMin.getDate() - 90);

    const lancamentos = await this.prisma.lancamento.findMany({
      where: {
        tenantId,
        empresaId: conta.empresaId,
        status: 'ATIVO',
        dataLancamento: { gte: dataMin },
      },
      include: { partidas: true },
    });

    const usados = new Set<string>();
    let conciliados = 0;

    for (const extrato of extratos) {
      const candidato = this.encontrarCandidato(extrato, lancamentos, usados);
      if (!candidato) continue;

      await this.prisma.extratoBancario.update({
        where: { id: extrato.id },
        data: { conciliado: true, lancamentoId: candidato.id },
      });
      usados.add(candidato.id);
      conciliados++;
    }

    this.logger.log(
      `Conciliação automática: ${conciliados}/${extratos.length} extratos vinculados`,
    );
    return conciliados;
  }

  private encontrarCandidato(
    extrato: any,
    lancamentos: any[],
    usados: Set<string>,
  ): any | null {
    const valorExtrato = Math.abs(Number(extrato.valor));

    let melhorCandidato: any = null;
    let menorDiferenca = Infinity;

    for (const lanc of lancamentos) {
      if (usados.has(lanc.id)) continue;

      const valorLanc = Math.abs(Number(lanc.valorTotal));
      const difValor = Math.abs(valorLanc - valorExtrato);

      if (difValor > TOLERANCIA_VALOR) continue;

      const difDias = Math.abs(
        (lanc.dataLancamento.getTime() - extrato.dataMovimento.getTime()) /
          (1000 * 60 * 60 * 24),
      );

      if (difDias > TOLERANCIA_DIAS) continue;

      // Preferir candidatos com menor diferença de dias
      const score = difDias + difValor * 100;
      if (score < menorDiferenca) {
        menorDiferenca = score;
        melhorCandidato = lanc;
      }
    }

    return melhorCandidato;
  }
}
