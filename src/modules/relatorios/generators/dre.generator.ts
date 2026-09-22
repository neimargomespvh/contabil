import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../../infra/prisma/prisma.service';
import { LinhaDre } from './tipos';

@Injectable()
export class DreGenerator {
  constructor(private readonly prisma: PrismaService) {}

  async gerar(
    tenantId: string,
    empresaId: string,
    dataInicio: Date,
    dataFim: Date,
  ): Promise<{ linhas: LinhaDre[]; totais: any }> {
    const plano = await this.prisma.planoContas.findFirst({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { versao: 'desc' },
    });
    if (!plano) return { linhas: [], totais: {} };

    // Buscar contas por dreLinha
    const contas = await this.prisma.conta.findMany({
      where: {
        tenantId,
        planoContasId: plano.id,
        dreLinha: { not: null },
      },
      orderBy: { codigo: 'asc' },
    });

    // Saldo por conta no período (movimentação)
    const partidas = await this.prisma.partida.groupBy({
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

    const movDeb = new Map<string, number>();
    const movCred = new Map<string, number>();
    for (const p of partidas) {
      const v = Number(p._sum.valor ?? 0);
      if (p.tipo === 'D') movDeb.set(p.contaId, v);
      else movCred.set(p.contaId, v);
    }

    // Agrupar por dreLinha
    const porLinha = new Map<string, number>();
    for (const c of contas) {
      const deb = movDeb.get(c.id) ?? 0;
      const cred = movCred.get(c.id) ?? 0;

      let valor: number;
      if (c.natureza === 'RECEITA') {
        valor = cred - deb; // receita aumenta com crédito
      } else {
        valor = deb - cred; // despesa/custo aumenta com débito
      }

      const atual = porLinha.get(c.dreLinha!) ?? 0;
      porLinha.set(c.dreLinha!, atual + valor);
    }

    // Estrutura DRE
    const get = (linha: string) => Number((porLinha.get(linha) ?? 0).toFixed(2));

    const receitaBruta = get('RECEITA_BRUTA');
    const deducoes = Math.abs(get('DEDUCOES'));
    const receitaLiquida = receitaBruta - deducoes;
    const custoProdutos = get('CUSTO_PRODUTOS');
    const custoServicos = get('CUSTO_SERVICOS');
    const lucroBruto = receitaLiquida - custoProdutos - custoServicos;
    const despesasPessoal = get('DESPESAS_PESSOAL');
    const despesasAdmin = get('DESPESAS_ADMIN');
    const despesasComerciais = get('DESPESAS_COMERCIAIS');
    const despesasTributarias = get('DESPESAS_TRIBUTARIAS');
    const despesasFinanceiras = get('DESPESAS_FINANCEIRAS');
    const outrasDespesas = get('OUTRAS_DESPESAS');
    const totalDespesas =
      despesasPessoal + despesasAdmin + despesasComerciais +
      despesasTributarias + despesasFinanceiras + outrasDespesas;
    const resultadoOperacional = lucroBruto - totalDespesas;
    const receitasFinanceiras = get('RECEITA_FINANCEIRA');
    const outrasReceitas = get('OUTRAS_RECEITAS');
    const resultadoAntesIR = resultadoOperacional + receitasFinanceiras + outrasReceitas;

    const pct = (v: number) => (receitaBruta > 0 ? Number(((v / receitaBruta) * 100).toFixed(2)) : 0);

    const linhas: LinhaDre[] = [
      { linha: 'RECEITA_BRUTA', descricao: 'RECEITA BRUTA', valor: receitaBruta, percentualReceita: pct(receitaBruta), destaque: 'negrito' },
      { linha: 'DEDUCOES', descricao: '(-) Deduções da Receita', valor: -deducoes, percentualReceita: pct(-deducoes) },
      { linha: 'RECEITA_LIQUIDA', descricao: '= RECEITA LÍQUIDA', valor: receitaLiquida, percentualReceita: pct(receitaLiquida), destaque: 'subtotal' },
      { linha: 'CUSTO_PRODUTOS', descricao: '(-) Custo dos Produtos Vendidos', valor: -custoProdutos, percentualReceita: pct(-custoProdutos) },
      { linha: 'CUSTO_SERVICOS', descricao: '(-) Custo dos Serviços Prestados', valor: -custoServicos, percentualReceita: pct(-custoServicos) },
      { linha: 'LUCRO_BRUTO', descricao: '= LUCRO BRUTO', valor: lucroBruto, percentualReceita: pct(lucroBruto), destaque: 'subtotal' },
      { linha: 'DESPESAS_PESSOAL', descricao: '(-) Despesas com Pessoal', valor: -despesasPessoal, percentualReceita: pct(-despesasPessoal) },
      { linha: 'DESPESAS_ADMIN', descricao: '(-) Despesas Administrativas', valor: -despesasAdmin, percentualReceita: pct(-despesasAdmin) },
      { linha: 'DESPESAS_COMERCIAIS', descricao: '(-) Despesas Comerciais', valor: -despesasComerciais, percentualReceita: pct(-despesasComerciais) },
      { linha: 'DESPESAS_TRIBUTARIAS', descricao: '(-) Despesas Tributárias', valor: -despesasTributarias, percentualReceita: pct(-despesasTributarias) },
      { linha: 'DESPESAS_FINANCEIRAS', descricao: '(-) Despesas Financeiras', valor: -despesasFinanceiras, percentualReceita: pct(-despesasFinanceiras) },
      { linha: 'OUTRAS_DESPESAS', descricao: '(-) Outras Despesas', valor: -outrasDespesas, percentualReceita: pct(-outrasDespesas) },
      { linha: 'RESULTADO_OPERACIONAL', descricao: '= RESULTADO OPERACIONAL', valor: resultadoOperacional, percentualReceita: pct(resultadoOperacional), destaque: 'subtotal' },
      { linha: 'RECEITA_FINANCEIRA', descricao: '(+) Receitas Financeiras', valor: receitasFinanceiras, percentualReceita: pct(receitasFinanceiras) },
      { linha: 'OUTRAS_RECEITAS', descricao: '(+) Outras Receitas', valor: outrasReceitas, percentualReceita: pct(outrasReceitas) },
      { linha: 'RESULTADO_ANTES_IR', descricao: '= RESULTADO ANTES DO IR/CSLL', valor: resultadoAntesIR, percentualReceita: pct(resultadoAntesIR), destaque: 'total' },
    ];

    return {
      linhas,
      totais: {
        receitaBruta,
        receitaLiquida,
        lucroBruto,
        resultadoOperacional,
        resultadoAntesIR,
        margemLiquida: receitaBruta > 0 ? Number(((resultadoAntesIR / receitaBruta) * 100).toFixed(2)) : 0,
      },
    };
  }
}
