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
        this.formatNum(resultado.totais.saldoAnterior ?? 0),
        this.formatNum(resultado.totais.debitos ?? 0),
        this.formatNum(resultado.totais.creditos ?? 0),
        this.formatNum(resultado.totais.saldoAtual ?? 0),
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
    linhas.push(['TOTAL DO ATIVO', '', this.formatNum(resultado.totais.ativo ?? 0)]);
    linhas.push(['', '', '']);
    linhas.push(['PASSIVO', '', '']);
    for (const l of resultado.passivo) {
      linhas.push(['  '.repeat(l.nivel - 1) + l.nome, l.codigo ?? '', this.formatNum(l.valor)]);
    }
    linhas.push(['TOTAL DO PASSIVO', '', this.formatNum(resultado.totais.passivo ?? 0)]);
    linhas.push(['', '', '']);
    linhas.push(['PATRIMÔNIO LÍQUIDO', '', '']);
    for (const l of resultado.patrimonioLiquido) {
      linhas.push(['  '.repeat(l.nivel - 1) + l.nome, l.codigo ?? '', this.formatNum(l.valor)]);
    }
    linhas.push(['TOTAL DO PL', '', this.formatNum(resultado.totais.patrimonioLiquido ?? 0)]);
    linhas.push(['PASSIVO + PL', '', this.formatNum(resultado.totais.passivoMaisPL ?? 0)]);

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
        ['', '', 'Débitos', '', this.formatNum(resultado.totais.debitos ?? 0), ''],
        ['', '', 'Créditos', '', this.formatNum(resultado.totais.creditos ?? 0), ''],
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
        ['', 'SALDO INICIAL', '', '', this.formatNum(resultado.totais.saldoInicial ?? 0)],
        ['', 'TOTAIS', this.formatNum(resultado.totais.entradas ?? 0), this.formatNum(resultado.totais.saidas ?? 0), ''],
        ['', 'SALDO FINAL', '', '', this.formatNum(resultado.totais.saldoFinal ?? 0)],
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
