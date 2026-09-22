#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/modules/relatorios/{dto,generators,exporters,testes}

# ============================================================
# 1. INSTALAR EXCELJS
# ============================================================
echo "📦 Instalando exceljs..."
npm install exceljs --save

# ============================================================
# 2. DTOs
# ============================================================
cat > src/modules/relatorios/dto/filter-relatorio.dto.ts <<'DTO_EOF'
import { ApiPropertyOptional } from '@nestjs/swagger';
import { IsDateString, IsEnum, IsOptional, IsUUID } from 'class-validator';

export enum FormatoExportacaoEnum {
  JSON = 'JSON',
  PDF = 'PDF',
  EXCEL = 'EXCEL',
}

export class FilterRelatorioDto {
  @ApiPropertyOptional()
  @IsOptional()
  @IsUUID()
  empresaId?: string;

  @ApiPropertyOptional({ description: 'Data inicial (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataInicio?: string;

  @ApiPropertyOptional({ description: 'Data final (YYYY-MM-DD)' })
  @IsOptional()
  @IsDateString()
  dataFim?: string;

  @ApiPropertyOptional({ enum: FormatoExportacaoEnum, default: 'JSON' })
  @IsOptional()
  @IsEnum(FormatoExportacaoEnum)
  formato?: FormatoExportacaoEnum;

  @ApiPropertyOptional({ description: 'Incluir contas com saldo zero', default: false })
  @IsOptional()
  incluirZeradas?: string;

  @ApiPropertyOptional({ description: 'Nível máximo de profundidade' })
  @IsOptional()
  nivel?: string;
}

export class ComparativoDto extends FilterRelatorioDto {
  @ApiPropertyOptional({ description: 'Data inicial do período anterior' })
  @IsOptional()
  @IsDateString()
  dataInicioAnterior?: string;

  @ApiPropertyOptional({ description: 'Data final do período anterior' })
  @IsOptional()
  @IsDateString()
  dataFimAnterior?: string;
}
DTO_EOF

# ============================================================
# 3. TIPOS COMPARTILHADOS
# ============================================================
cat > src/modules/relatorios/generators/tipos.ts <<'TIPOS_EOF'
export interface LinhaBalancete {
  contaId: string;
  codigo: string;
  nome: string;
  natureza: string;
  grau: number;
  saldoAnterior: number;
  debitos: number;
  creditos: number;
  saldoAtual: number;
}

export interface LinhaBalanco {
  grupo: string;
  subgrupo?: string;
  contaId?: string;
  codigo?: string;
  nome: string;
  valor: number;
  nivel: number;
}

export interface LinhaDre {
  linha: string;
  descricao: string;
  valor: number;
  percentualReceita: number;
  destaque?: 'total' | 'subtotal' | 'negrito';
}

export interface LinhaRazao {
  data: Date;
  lancamentoId: string;
  historico: string;
  documentoRef?: string;
  debito: number;
  credito: number;
  saldoAcumulado: number;
}

export interface LinhaLivroDiario {
  numero: number;
  data: Date;
  historico: string;
  documentoRef?: string;
  partidas: Array<{
    conta: string;
    nomeConta: string;
    tipo: 'D' | 'C';
    valor: number;
  }>;
  valorTotal: number;
}

export interface LinhaFluxoCaixa {
  data: Date;
  descricao: string;
  entrada: number;
  saida: number;
  saldoAcumulado: number;
}
TIPOS_EOF

# ============================================================
# 4. GERADOR DE BALANCETE
# ============================================================
cat > src/modules/relatorios/generators/balancete.generator.ts <<'GEN_EOF'
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
GEN_EOF

# ============================================================
# 5. GERADOR DE BALANÇO PATRIMONIAL
# ============================================================
cat > src/modules/relatorios/generators/balanco.generator.ts <<'GEN_EOF'
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
GEN_EOF

# ============================================================
# 6. GERADOR DE DRE
# ============================================================
cat > src/modules/relatorios/generators/dre.generator.ts <<'GEN_EOF'
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
GEN_EOF

# ============================================================
# 7. GERADOR DE RAZÃO
# ============================================================
cat > src/modules/relatorios/generators/razao.generator.ts <<'GEN_EOF'
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
GEN_EOF

# ============================================================
# 8. GERADOR DE LIVRO DIÁRIO
# ============================================================
cat > src/modules/relatorios/generators/livro-diario.generator.ts <<'GEN_EOF'
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
GEN_EOF

# ============================================================
# 9. GERADOR DE FLUXO DE CAIXA
# ============================================================
cat > src/modules/relatorios/generators/fluxo-caixa.generator.ts <<'GEN_EOF'
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
GEN_EOF

# ============================================================
# 10. EXPORTADORES
# ============================================================
cat > src/modules/relatorios/exporters/pdf.exporter.ts <<'EXPORT_EOF'
import { Injectable } from '@nestjs/common';
import PDFDocument from 'pdfkit';

export interface DadosRelatorio {
  titulo: string;
  empresaNome: string;
  empresaCnpj: string;
  periodo: string;
  colunas: string[];
  linhas: Array<string[]>;
  totais?: Array<string[]>;
  larguras?: number[];
}

@Injectable()
export class PdfExporter {
  async exportar(dados: DadosRelatorio): Promise<Buffer> {
    return new Promise((resolve, reject) => {
      try {
        const doc = new PDFDocument({
          size: 'A4',
          margin: 30,
          layout: dados.colunas.length > 5 ? 'landscape' : 'portrait',
        });
        const chunks: Buffer[] = [];
        doc.on('data', (c) => chunks.push(c));
        doc.on('end', () => resolve(Buffer.concat(chunks)));
        doc.on('error', reject);

        this.renderizar(doc, dados);
        doc.end();
      } catch (err) {
        reject(err);
      }
    });
  }

  private renderizar(doc: PDFKit.PDFDocument, dados: DadosRelatorio) {
    const larguraPag = doc.page.width - 60;

    // Cabeçalho
    doc.font('Helvetica-Bold').fontSize(14).fillColor('#003366')
      .text(dados.empresaNome, 30, 30, { width: larguraPag, align: 'center' });
    doc.font('Helvetica').fontSize(9).fillColor('#333333')
      .text(`CNPJ: ${this.formatarCnpj(dados.empresaCnpj)}`, { width: larguraPag, align: 'center' });
    doc.font('Helvetica-Bold').fontSize(12).fillColor('#003366')
      .text(dados.titulo, { width: larguraPag, align: 'center' });
    doc.font('Helvetica').fontSize(9)
      .text(`Período: ${dados.periodo}`, { width: larguraPag, align: 'center' });

    doc.moveDown(1);

    const larguras = dados.larguras ?? this.distribuirLarguras(dados.colunas.length, larguraPag);
    const alturaLinha = 18;
    let y = doc.y;

    // Cabeçalho de colunas
    doc.rect(30, y, larguraPag, alturaLinha).fill('#003366');
    doc.fillColor('#FFFFFF').fontSize(8).font('Helvetica-Bold');
    let x = 30;
    for (let i = 0; i < dados.colunas.length; i++) {
      doc.text(dados.colunas[i], x + 3, y + 5, { width: larguras[i] - 6, align: i === 0 ? 'left' : 'right' });
      x += larguras[i];
    }
    y += alturaLinha;

    // Linhas
    doc.font('Helvetica').fontSize(8).fillColor('#000000');
    let zebra = false;
    for (const linha of dados.linhas) {
      if (y + alturaLinha > doc.page.height - 50) {
        doc.addPage();
        y = 30;
      }
      if (zebra) {
        doc.rect(30, y, larguraPag, alturaLinha).fill('#F5F5F5');
      }
      zebra = !zebra;

      doc.fillColor('#000000');
      x = 30;
      for (let i = 0; i < linha.length; i++) {
        doc.text(String(linha[i] ?? ''), x + 3, y + 5, {
          width: larguras[i] - 6,
          align: i === 0 ? 'left' : 'right',
          ellipsis: true,
        });
        x += larguras[i];
      }
      y += alturaLinha;
    }

    // Totais
    if (dados.totais && dados.totais.length > 0) {
      y += 4;
      doc.rect(30, y, larguraPag, alturaLinha).fill('#DDDDDD');
      doc.font('Helvetica-Bold').fillColor('#000000');
      for (const totLinha of dados.totais) {
        x = 30;
        for (let i = 0; i < totLinha.length; i++) {
          doc.text(String(totLinha[i] ?? ''), x + 3, y + 5, {
            width: larguras[i] - 6,
            align: i === 0 ? 'left' : 'right',
          });
          x += larguras[i];
        }
        y += alturaLinha;
      }
    }

    // Rodapé
    const rodapeY = doc.page.height - 30;
    doc.font('Helvetica').fontSize(7).fillColor('#999999').text(
      `Gerado em ${new Date().toLocaleString('pt-BR')} — Sistema Contábil`,
      30,
      rodapeY,
      { width: larguraPag, align: 'center' },
    );
  }

  private distribuirLarguras(n: number, total: number): number[] {
    if (n <= 1) return [total];
    const primeira = total * 0.35;
    const restante = (total - primeira) / (n - 1);
    return [primeira, ...Array(n - 1).fill(restante)];
  }

  private formatarCnpj(cnpj: string): string {
    const limpo = cnpj.replace(/\D/g, '');
    return limpo.replace(/^(\d{2})(\d{3})(\d{3})(\d{4})(\d{2})$/, '$1.$2.$3/$4-$5');
  }
}
EXPORT_EOF

cat > src/modules/relatorios/exporters/excel.exporter.ts <<'EXPORT_EOF'
import { Injectable } from '@nestjs/common';
import * as ExcelJS from 'exceljs';
import { DadosRelatorio } from './pdf.exporter';

@Injectable()
export class ExcelExporter {
  async exportar(dados: DadosRelatorio): Promise<Buffer> {
    const wb = new ExcelJS.Workbook();
    wb.creator = 'Sistema Contábil';
    wb.created = new Date();

    const ws = wb.addWorksheet(dados.titulo.slice(0, 30));

    // Cabeçalho
    ws.mergeCells('A1', `${this.letra(dados.colunas.length)}1`);
    ws.getCell('A1').value = dados.empresaNome;
    ws.getCell('A1').font = { bold: true, size: 14, color: { argb: 'FF003366' } };
    ws.getCell('A1').alignment = { horizontal: 'center' };

    ws.mergeCells('A2', `${this.letra(dados.colunas.length)}2`);
    ws.getCell('A2').value = `CNPJ: ${dados.empresaCnpj}`;
    ws.getCell('A2').alignment = { horizontal: 'center' };
    ws.getCell('A2').font = { size: 9 };

    ws.mergeCells('A3', `${this.letra(dados.colunas.length)}3`);
    ws.getCell('A3').value = dados.titulo;
    ws.getCell('A3').font = { bold: true, size: 12 };
    ws.getCell('A3').alignment = { horizontal: 'center' };

    ws.mergeCells('A4', `${this.letra(dados.colunas.length)}4`);
    ws.getCell('A4').value = `Período: ${dados.periodo}`;
    ws.getCell('A4').alignment = { horizontal: 'center' };
    ws.getCell('A4').font = { size: 9 };

    // Cabeçalho de colunas (linha 6)
    const headerRow = ws.getRow(6);
    dados.colunas.forEach((c, i) => {
      const cell = headerRow.getCell(i + 1);
      cell.value = c;
      cell.font = { bold: true, color: { argb: 'FFFFFFFF' } };
      cell.fill = { type: 'pattern', pattern: 'solid', fgColor: { argb: 'FF003366' } };
      cell.alignment = { horizontal: i === 0 ? 'left' : 'right', vertical: 'middle' };
      cell.border = {
        top: { style: 'thin' }, bottom: { style: 'thin' },
        left: { style: 'thin' }, right: { style: 'thin' },
      };
    });
    headerRow.height = 20;

    // Linhas
    let linhaAtual = 7;
    for (const linha of dados.linhas) {
      const row = ws.getRow(linhaAtual);
      linha.forEach((v, i) => {
        const cell = row.getCell(i + 1);
        // Tentar número
        const num = this.parseNumero(v);
        cell.value = num !== null ? num : v;
        if (num !== null) {
          cell.numFmt = '#,##0.00';
        }
        cell.alignment = { horizontal: i === 0 ? 'left' : 'right' };
      });
      linhaAtual++;
    }

    // Totais
    if (dados.totais) {
      for (const tot of dados.totais) {
        const row = ws.getRow(linhaAtual);
        tot.forEach((v, i) => {
          const cell = row.getCell(i + 1);
          const num = this.parseNumero(v);
          cell.value = num !== null ? num : v;
          if (num !== null) cell.numFmt = '#,##0.00';
          cell.font = { bold: true };
          cell.alignment = { horizontal: i === 0 ? 'left' : 'right' };
        });
        linhaAtual++;
      }
    }

    // Ajustar larguras
    dados.colunas.forEach((_, i) => {
      const col = ws.getColumn(i + 1);
      col.width = i === 0 ? 40 : 18;
    });

    const buffer = await wb.xlsx.writeBuffer();
    return Buffer.from(buffer);
  }

  private letra(n: number): string {
    let s = '';
    while (n > 0) {
      const resto = (n - 1) % 26;
      s = String.fromCharCode(65 + resto) + s;
      n = Math.floor((n - 1) / 26);
    }
    return s || 'A';
  }

  private parseNumero(v: any): number | null {
    if (typeof v === 'number') return v;
    if (typeof v !== 'string') return null;
    const limpo = v.replace(/[R$\s.]/g, '').replace(',', '.');
    if (!/^-?\d+(\.\d+)?$/.test(limpo)) return null;
    const n = parseFloat(limpo);
    return isNaN(n) ? null : n;
  }
}
EXPORT_EOF

# ============================================================
# 11. SERVIÇO PRINCIPAL
# ============================================================
cat > src/modules/relatorios/relatorios.service.ts <<'SERVICE_EOF'
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { S3Service } from '../../infra/s3/s3.service';
import { BalanceteGenerator } from './generators/balancete.generator';
import { BalancoGenerator } from './generators/balanco.generator';
import { DreGenerator } from './generators/dre.generator';
import { RazaoGenerator } from './generators/razao.generator';
import { LivroDiarioGenerator } from './generators/livro-diario.generator';
import { FluxoCaixaGenerator } from './generators/fluxo-caixa.generator';
import { PdfExporter, DadosRelatorio } from './exporters/pdf.exporter';
import { ExcelExporter } from './exporters/excel.exporter';
import { FilterRelatorioDto, FormatoExportacaoEnum, ComparativoDto } from './dto/filter-relatorio.dto';

@Injectable()
export class RelatoriosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
    private readonly balanceteGen: BalanceteGenerator,
    private readonly balancoGen: BalancoGenerator,
    private readonly dreGen: DreGenerator,
    private readonly razaoGen: RazaoGenerator,
    private readonly diarioGen: LivroDiarioGenerator,
    private readonly fluxoGen: FluxoCaixaGenerator,
    private readonly pdf: PdfExporter,
    private readonly excel: ExcelExporter,
  ) {}

  // ============================================================
  // BALANCETE
  // ============================================================
  async balancete(tenantId: string, filtros: FilterRelatorioDto) {
    const { empresaId, dataInicio, dataFim } = this.validarFiltros(filtros);

    const resultado = await this.balanceteGen.gerar(
      tenantId,
      empresaId,
      dataInicio,
      dataFim,
      filtros.incluirZeradas === 'true',
    );

    if (filtros.formato === FormatoExportacaoEnum.JSON || !filtros.formato) {
      return resultado;
    }

    const empresa = await this.buscarEmpresa(tenantId, empresaId);
    const dados = this.montarDadosExportacao(
      'BALANCETE',
      empresa,
      dataInicio,
      dataFim,
      ['Conta', 'Nome', 'Saldo Anterior', 'Débitos', 'Créditos', 'Saldo Atual'],
      resultado.linhas.map((l) => [
        l.codigo,
        l.nome,
        this.formatNum(l.saldoAnterior),
        this.formatNum(l.debitos),
        this.formatNum(l.creditos),
        this.formatNum(l.saldoAtual),
      ]),
      [[
        'TOTAIS',
        '',
        this.formatNum(resultado.totais.saldoAnterior),
        this.formatNum(resultado.totais.debitos),
        this.formatNum(resultado.totais.creditos),
        this.formatNum(resultado.totais.saldoAtual),
      ]],
    );

    return this.exportar(tenantId, 'balancete', dados, filtros.formato!);
  }

  // ============================================================
  // BALANÇO PATRIMONIAL
  // ============================================================
  async balanco(tenantId: string, filtros: FilterRelatorioDto) {
    const { empresaId, dataFim } = this.validarFiltros(filtros, true);

    const resultado = await this.balancoGen.gerar(tenantId, empresaId, dataFim);

    if (filtros.formato === FormatoExportacaoEnum.JSON || !filtros.formato) {
      return resultado;
    }

    const empresa = await this.buscarEmpresa(tenantId, empresaId);

    const linhas: string[][] = [];
    linhas.push(['ATIVO', '', '']);
    for (const l of resultado.ativo) {
      linhas.push(['  '.repeat(l.nivel - 1) + l.nome, l.codigo ?? '', this.formatNum(l.valor)]);
    }
    linhas.push(['TOTAL DO ATIVO', '', this.formatNum(resultado.totais.ativo)]);
    linhas.push(['', '', '']);
    linhas.push(['PASSIVO', '', '']);
    for (const l of resultado.passivo) {
      linhas.push(['  '.repeat(l.nivel - 1) + l.nome, l.codigo ?? '', this.formatNum(l.valor)]);
    }
    linhas.push(['TOTAL DO PASSIVO', '', this.formatNum(resultado.totais.passivo)]);
    linhas.push(['', '', '']);
    linhas.push(['PATRIMÔNIO LÍQUIDO', '', '']);
    for (const l of resultado.patrimonioLiquido) {
      linhas.push(['  '.repeat(l.nivel - 1) + l.nome, l.codigo ?? '', this.formatNum(l.valor)]);
    }
    linhas.push(['TOTAL DO PL', '', this.formatNum(resultado.totais.patrimonioLiquido)]);
    linhas.push(['PASSIVO + PL', '', this.formatNum(resultado.totais.passivoMaisPL)]);

    const dados = this.montarDadosExportacao(
      'BALANÇO PATRIMONIAL',
      empresa,
      dataFim,
      dataFim,
      ['Descrição', 'Código', 'Valor (R$)'],
      linhas,
    );

    return this.exportar(tenantId, 'balanco', dados, filtros.formato!);
  }

  // ============================================================
  // DRE
  // ============================================================
  async dre(tenantId: string, filtros: FilterRelatorioDto) {
    const { empresaId, dataInicio, dataFim } = this.validarFiltros(filtros);

    const resultado = await this.dreGen.gerar(tenantId, empresaId, dataInicio, dataFim);

    if (filtros.formato === FormatoExportacaoEnum.JSON || !filtros.formato) {
      return resultado;
    }

    const empresa = await this.buscarEmpresa(tenantId, empresaId);
    const dados = this.montarDadosExportacao(
      'DEMONSTRATIVO DE RESULTADO (DRE)',
      empresa,
      dataInicio,
      dataFim,
      ['Descrição', 'Valor (R$)', '% Receita'],
      resultado.linhas.map((l) => [l.descricao, this.formatNum(l.valor), `${l.percentualReceita}%`]),
    );

    return this.exportar(tenantId, 'dre', dados, filtros.formato!);
  }

  // ============================================================
  // RAZÃO
  // ============================================================
  async razao(tenantId: string, contaId: string, filtros: FilterRelatorioDto) {
    const { empresaId, dataInicio, dataFim } = this.validarFiltros(filtros);

    const resultado = await this.razaoGen.gerar(tenantId, contaId, dataInicio, dataFim);

    if (filtros.formato === FormatoExportacaoEnum.JSON || !filtros.formato) {
      return resultado;
    }

    const empresa = await this.buscarEmpresa(tenantId, empresaId);
    const dados = this.montarDadosExportacao(
      `RAZÃO ANALÍTICO — ${resultado.conta.codigo} ${resultado.conta.nome}`,
      empresa,
      dataInicio,
      dataFim,
      ['Data', 'Histórico', 'Débito', 'Crédito', 'Saldo'],
      resultado.linhas.map((l) => [
        l.data.toLocaleDateString('pt-BR'),
        l.historico,
        this.formatNum(l.debito),
        this.formatNum(l.credito),
        this.formatNum(l.saldoAcumulado),
      ]),
      [['SALDO FINAL', '', '', '', this.formatNum(resultado.saldoFinal)]],
    );

    return this.exportar(tenantId, 'razao', dados, filtros.formato!);
  }

  // ============================================================
  // LIVRO DIÁRIO
  // ============================================================
  async livroDiario(tenantId: string, filtros: FilterRelatorioDto) {
    const { empresaId, dataInicio, dataFim } = this.validarFiltros(filtros);

    const resultado = await this.diarioGen.gerar(tenantId, empresaId, dataInicio, dataFim);

    if (filtros.formato === FormatoExportacaoEnum.JSON || !filtros.formato) {
      return resultado;
    }

    const empresa = await this.buscarEmpresa(tenantId, empresaId);

    const linhas: string[][] = [];
    for (const l of resultado.linhas) {
      linhas.push([
        l.numero.toString(),
        l.data.toLocaleDateString('pt-BR'),
        l.historico,
        '',
        '',
        '',
      ]);
      for (const p of l.partidas) {
        linhas.push([
          '',
          '',
          `${p.conta} — ${p.nomeConta}`,
          p.tipo,
          this.formatNum(p.valor),
          '',
        ]);
      }
    }

    const dados = this.montarDadosExportacao(
      'LIVRO DIÁRIO',
      empresa,
      dataInicio,
      dataFim,
      ['Nº', 'Data', 'Histórico / Conta', 'Tipo', 'Valor', ''],
      linhas,
      [
        ['', '', 'TOTAIS', '', '', ''],
        ['', '', 'Débitos', '', this.formatNum(resultado.totais.debitos), ''],
        ['', '', 'Créditos', '', this.formatNum(resultado.totais.creditos), ''],
      ],
    );

    return this.exportar(tenantId, 'livro-diario', dados, filtros.formato!);
  }

  // ============================================================
  // FLUXO DE CAIXA
  // ============================================================
  async fluxoCaixa(tenantId: string, filtros: FilterRelatorioDto, contaBancariaId?: string) {
    const { empresaId, dataInicio, dataFim } = this.validarFiltros(filtros);

    const resultado = await this.fluxoGen.gerar(
      tenantId,
      empresaId,
      dataInicio,
      dataFim,
      contaBancariaId,
    );

    if (filtros.formato === FormatoExportacaoEnum.JSON || !filtros.formato) {
      return resultado;
    }

    const empresa = await this.buscarEmpresa(tenantId, empresaId);
    const dados = this.montarDadosExportacao(
      'FLUXO DE CAIXA',
      empresa,
      dataInicio,
      dataFim,
      ['Data', 'Descrição', 'Entradas', 'Saídas', 'Saldo'],
      resultado.linhas.map((l) => [
        l.data.toLocaleDateString('pt-BR'),
        l.descricao,
        this.formatNum(l.entrada),
        this.formatNum(l.saida),
        this.formatNum(l.saldoAcumulado),
      ]),
      [
        ['', 'SALDO INICIAL', '', '', this.formatNum(resultado.totais.saldoInicial)],
        ['', 'TOTAIS', this.formatNum(resultado.totais.entradas), this.formatNum(resultado.totais.saidas), ''],
        ['', 'SALDO FINAL', '', '', this.formatNum(resultado.totais.saldoFinal)],
      ],
    );

    return this.exportar(tenantId, 'fluxo-caixa', dados, filtros.formato!);
  }

  // ============================================================
  // COMPARATIVO DRE
  // ============================================================
  async comparativoDre(tenantId: string, dto: ComparativoDto) {
    const { empresaId } = this.validarFiltros(dto);

    if (!dto.dataInicio || !dto.dataFim || !dto.dataInicioAnterior || !dto.dataFimAnterior) {
      throw new BadRequestException('Períodos atual e anterior são obrigatórios');
    }

    const atual = await this.dreGen.gerar(
      tenantId,
      empresaId,
      new Date(dto.dataInicio),
      new Date(dto.dataFim),
    );
    const anterior = await this.dreGen.gerar(
      tenantId,
      empresaId,
      new Date(dto.dataInicioAnterior),
      new Date(dto.dataFimAnterior),
    );

    const mapaAnterior = new Map(anterior.linhas.map((l) => [l.linha, l.valor]));

    return {
      periodoAtual: { inicio: dto.dataInicio, fim: dto.dataFim },
      periodoAnterior: { inicio: dto.dataInicioAnterior, fim: dto.dataFimAnterior },
      linhas: atual.linhas.map((l) => {
        const valorAnt = mapaAnterior.get(l.linha) ?? 0;
        const variacao = valorAnt !== 0 ? ((l.valor - valorAnt) / Math.abs(valorAnt)) * 100 : 0;
        return {
          linha: l.linha,
          descricao: l.descricao,
          valorAtual: l.valor,
          valorAnterior: valorAnt,
          variacao: Number(variacao.toFixed(2)),
        };
      }),
    };
  }

  // ============================================================
  // HELPERS
  // ============================================================
  private validarFiltros(filtros: FilterRelatorioDto, apenasDataFim = false) {
    if (!filtros.empresaId) {
      throw new BadRequestException('empresaId é obrigatório');
    }
    if (!filtros.dataFim) {
      throw new BadRequestException('dataFim é obrigatória');
    }

    const dataFim = new Date(filtros.dataFim);
    const dataInicio = filtros.dataInicio
      ? new Date(filtros.dataInicio)
      : apenasDataFim
        ? new Date(dataFim.getFullYear(), 0, 1)
        : new Date(dataFim.getFullYear(), dataFim.getMonth(), 1);

    return { empresaId: filtros.empresaId, dataInicio, dataFim };
  }

  private async buscarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId },
      select: { razaoSocial: true, cnpj: true },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
    return empresa;
  }

  private montarDadosExportacao(
    titulo: string,
    empresa: { razaoSocial: string; cnpj: string },
    dataInicio: Date,
    dataFim: Date,
    colunas: string[],
    linhas: string[][],
    totais?: string[][],
  ): DadosRelatorio {
    return {
      titulo,
      empresaNome: empresa.razaoSocial,
      empresaCnpj: empresa.cnpj,
      periodo: `${dataInicio.toLocaleDateString('pt-BR')} a ${dataFim.toLocaleDateString('pt-BR')}`,
      colunas,
      linhas,
      totais,
    };
  }

  private async exportar(
    tenantId: string,
    nomeArquivo: string,
    dados: DadosRelatorio,
    formato: FormatoExportacaoEnum,
  ) {
    const ts = new Date().toISOString().slice(0, 19).replace(/[T:]/g, '-');
    let buffer: Buffer;
    let contentType: string;
    let ext: string;

    if (formato === FormatoExportacaoEnum.PDF) {
      buffer = await this.pdf.exportar(dados);
      contentType = 'application/pdf';
      ext = 'pdf';
    } else {
      buffer = await this.excel.exportar(dados);
      contentType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      ext = 'xlsx';
    }

    const key = `tenants/${tenantId}/relatorios/${nomeArquivo}-${ts}.${ext}`;
    await this.s3.upload(key, buffer, contentType);

    const url = await this.s3.presignedUrl(key, 3600);

    return {
      arquivo: `${nomeArquivo}-${ts}.${ext}`,
      tamanho: buffer.length,
      url,
    };
  }

  private formatNum(v: number | string): string {
    const n = typeof v === 'number' ? v : parseFloat(v);
    if (isNaN(n)) return String(v);
    return n.toLocaleString('pt-BR', { minimumFractionDigits: 2, maximumFractionDigits: 2 });
  }
}
SERVICE_EOF

# ============================================================
# 12. CONTROLLER
# ============================================================
cat > src/modules/relatorios/relatorios.controller.ts <<'CTRL_EOF'
import { Controller, Get, Param, ParseUUIDPipe, Query } from '@nestjs/common';
import { ApiBearerAuth, ApiOperation, ApiTags } from '@nestjs/swagger';
import { RelatoriosService } from './relatorios.service';
import { FilterRelatorioDto, ComparativoDto } from './dto/filter-relatorio.dto';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';
import { PERMISSIONS } from '../../common/constants/permissions.constants';

@ApiTags('relatorios')
@ApiBearerAuth()
@Controller('relatorios')
export class RelatoriosController {
  constructor(private readonly service: RelatoriosService) {}

  @Get('balancete')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Balancete por período (JSON/PDF/EXCEL)' })
  balancete(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.balancete(t, filtros);
  }

  @Get('balanco')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Balanço patrimonial' })
  balanco(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.balanco(t, filtros);
  }

  @Get('dre')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'DRE — Demonstrativo de Resultado' })
  dre(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.dre(t, filtros);
  }

  @Get('dre/comparativo')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'DRE comparativo entre períodos' })
  comparativo(@CurrentTenant() t: string, @Query() dto: ComparativoDto) {
    return this.service.comparativoDre(t, dto);
  }

  @Get('razao/:contaId')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Razão analítico de uma conta' })
  razao(
    @CurrentTenant() t: string,
    @Param('contaId', ParseUUIDPipe) contaId: string,
    @Query() filtros: FilterRelatorioDto,
  ) {
    return this.service.razao(t, contaId, filtros);
  }

  @Get('livro-diario')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Livro diário por período' })
  livroDiario(@CurrentTenant() t: string, @Query() filtros: FilterRelatorioDto) {
    return this.service.livroDiario(t, filtros);
  }

  @Get('fluxo-caixa')
  @RequirePermissions(PERMISSIONS.RELATORIO_VER)
  @ApiOperation({ summary: 'Fluxo de caixa' })
  fluxoCaixa(
    @CurrentTenant() t: string,
    @Query() filtros: FilterRelatorioDto,
    @Query('contaBancariaId') contaBancariaId?: string,
  ) {
    return this.service.fluxoCaixa(t, filtros, contaBancariaId);
  }
}
CTRL_EOF

cat > src/modules/relatorios/relatorios.module.ts <<'MOD_EOF'
import { Module } from '@nestjs/common';
import { RelatoriosController } from './relatorios.controller';
import { RelatoriosService } from './relatorios.service';
import { BalanceteGenerator } from './generators/balancete.generator';
import { BalancoGenerator } from './generators/balanco.generator';
import { DreGenerator } from './generators/dre.generator';
import { RazaoGenerator } from './generators/razao.generator';
import { LivroDiarioGenerator } from './generators/livro-diario.generator';
import { FluxoCaixaGenerator } from './generators/fluxo-caixa.generator';
import { PdfExporter } from './exporters/pdf.exporter';
import { ExcelExporter } from './exporters/excel.exporter';

@Module({
  controllers: [RelatoriosController],
  providers: [
    RelatoriosService,
    BalanceteGenerator,
    BalancoGenerator,
    DreGenerator,
    RazaoGenerator,
    LivroDiarioGenerator,
    FluxoCaixaGenerator,
    PdfExporter,
    ExcelExporter,
  ],
  exports: [RelatoriosService],
})
export class RelatoriosModule {}
MOD_EOF

# ============================================================
# 13. TESTES
# ============================================================
cat > src/modules/relatorios/testes/balancete.generator.spec.ts <<'TEST_EOF'
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
TEST_EOF

cat > src/modules/relatorios/testes/dre.generator.spec.ts <<'TEST_EOF'
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
TEST_EOF

# ============================================================
# 14. REGISTRAR NO APP.MODULE
# ============================================================
python3 <<'PYEOF'
with open('src/app.module.ts', 'r') as f:
    content = f.read()

if 'RelatoriosModule' not in content:
    content = content.replace(
        "import { ApuracoesModule } from './modules/apuracoes/apuracoes.module';",
        "import { ApuracoesModule } from './modules/apuracoes/apuracoes.module';\n"
        "import { RelatoriosModule } from './modules/relatorios/relatorios.module';"
    )
    content = content.replace(
        "    ApuracoesModule,\n    HealthModule,",
        "    ApuracoesModule,\n    RelatoriosModule,\n    HealthModule,"
    )
    with open('src/app.module.ts', 'w') as f:
        f.write(content)
    print("✅ AppModule atualizado com RelatoriosModule")
else:
    print("ℹ️  AppModule já contém RelatoriosModule")
PYEOF

echo ""
echo "✅ Pacote F8 instalado!"
echo ""
echo "Próximos passos:"
echo "  npx prisma generate"
echo "  npm run build"
echo "  npm test"
echo "  npm run dev"