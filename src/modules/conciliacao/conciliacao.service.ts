import {
  BadRequestException,
  ConflictException,
  Injectable,
  Logger,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { OfxParser } from './parsers/ofx.parser';
import { CsvParser } from './parsers/csv.parser';
import { MatchService } from './services/match.service';
import { ImportarOfxDto } from './dto/importar-ofx.dto';
import { ImportarCsvDto } from './dto/importar-csv.dto';
import { ConciliarManualDto } from './dto/conciliar-manual.dto';
import { FilterExtratoDto } from './dto/filter-extrato.dto';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class ConciliacaoService {
  private readonly logger = new Logger(ConciliacaoService.name);
  private readonly ofxParser = new OfxParser();
  private readonly csvParser = new CsvParser();

  constructor(
    private readonly prisma: PrismaService,
    private readonly match: MatchService,
  ) {}

  async importarOfx(tenantId: string, dto: ImportarOfxDto) {
    const conta = await this.validarConta(tenantId, dto.contaBancariaId);

    let extrato;
    try {
      extrato = this.ofxParser.parse(dto.conteudo);
    } catch (err) {
      throw new BadRequestException(`Erro ao processar OFX: ${(err as Error).message}`);
    }

    return this.persistirExtrato(tenantId, conta, extrato.transacoes, 'OFX', dto.conciliarAutomatico);
  }

  async importarCsv(tenantId: string, dto: ImportarCsvDto) {
    const conta = await this.validarConta(tenantId, dto.contaBancariaId);

    let transacoes;
    try {
      transacoes = this.csvParser.parse(dto.conteudo, {
        separador: dto.mapeamento.separador,
        data: dto.mapeamento.data,
        descricao: dto.mapeamento.descricao,
        valor: dto.mapeamento.valor,
        documento: dto.mapeamento.documento,
        formatoData: dto.mapeamento.formatoData as any,
        decimalVirgula: dto.mapeamento.decimalVirgula,
      });
    } catch (err) {
      throw new BadRequestException(`Erro ao processar CSV: ${(err as Error).message}`);
    }

    return this.persistirExtrato(tenantId, conta, transacoes, 'CSV', dto.conciliarAutomatico);
  }

  private async persistirExtrato(
    tenantId: string,
    conta: any,
    transacoes: any[],
    origem: 'OFX' | 'CSV',
    conciliarAuto?: string,
  ) {
    // 1. Filtrar duplicadas pelo hash
    const hashes = transacoes.map((t) => t.hash);
    const existentes = await this.prisma.extratoBancario.findMany({
      where: { hashUnico: { in: hashes } },
      select: { hashUnico: true },
    });
    const hashesExistentes = new Set(existentes.map((e) => e.hashUnico));

    const novas = transacoes.filter((t) => !hashesExistentes.has(t.hash));
    const duplicadas = transacoes.length - novas.length;

    if (novas.length === 0) {
      return {
        importadas: 0,
        duplicadas,
        total: transacoes.length,
        conciliadas: 0,
      };
    }

    // 2. Inserir em transação
    await this.prisma.$transaction(async (tx) => {
      await tx.extratoBancario.createMany({
        data: novas.map((t) => ({
          tenantId,
          contaBancariaId: conta.id,
          dataMovimento: t.dataMovimento,
          descricao: t.descricao,
          documento: t.documento,
          valor: t.tipo === 'C' ? t.valor : -t.valor,
          tipo: t.tipo,
          origemImportacao: origem,
          hashUnico: t.hash,
          conciliado: false,
        })),
      });
    });

    // 3. Conciliação automática (se solicitada)
    let conciliadas = 0;
    if (conciliarAuto !== 'false') {
      conciliadas = await this.match.conciliarAutomaticamente(tenantId, conta.id);
    }

    return {
      importadas: novas.length,
      duplicadas,
      total: transacoes.length,
      conciliadas,
    };
  }

  async listar(tenantId: string, filtros: FilterExtratoDto) {
    const where: Prisma.ExtratoBancarioWhereInput = { tenantId };

    if (filtros.contaBancariaId) where.contaBancariaId = filtros.contaBancariaId;
    if (filtros.conciliado !== undefined) {
      where.conciliado = filtros.conciliado === 'true';
    }
    if (filtros.dataInicio || filtros.dataFim) {
      where.dataMovimento = {};
      if (filtros.dataInicio) (where.dataMovimento as any).gte = new Date(filtros.dataInicio);
      if (filtros.dataFim) (where.dataMovimento as any).lte = new Date(filtros.dataFim);
    }

    const [total, data] = await Promise.all([
      this.prisma.extratoBancario.count({ where }),
      this.prisma.extratoBancario.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { dataMovimento: filtros.order },
        include: {
          contaBancaria: {
            include: { banco: { select: { codigo: true, nome: true } } },
          },
        },
      }),
    ]);

    return paginar(data, total, filtros.page, filtros.limit);
  }

  async conciliarManual(tenantId: string, extratoId: string, dto: ConciliarManualDto) {
    const extrato = await this.prisma.extratoBancario.findFirst({
      where: { id: extratoId, tenantId },
    });
    if (!extrato) throw new NotFoundException('Extrato não encontrado');
    if (extrato.conciliado) throw new ConflictException('Extrato já está conciliado');

    const lancamento = await this.prisma.lancamento.findFirst({
      where: { id: dto.lancamentoId, tenantId },
    });
    if (!lancamento) throw new NotFoundException('Lançamento não encontrado');

    // Validar valores compatíveis
    const dif = Math.abs(Math.abs(Number(extrato.valor)) - Math.abs(Number(lancamento.valorTotal)));
    if (dif > 0.01) {
      throw new BadRequestException(
        `Valores diferentes: extrato R$ ${extrato.valor}, lançamento R$ ${lancamento.valorTotal}`,
      );
    }

    return this.prisma.extratoBancario.update({
      where: { id: extratoId },
      data: { conciliado: true, lancamentoId: dto.lancamentoId },
    });
  }

  async desconciliar(tenantId: string, extratoId: string) {
    const extrato = await this.prisma.extratoBancario.findFirst({
      where: { id: extratoId, tenantId },
    });
    if (!extrato) throw new NotFoundException('Extrato não encontrado');

    return this.prisma.extratoBancario.update({
      where: { id: extratoId },
      data: { conciliado: false, lancamentoId: null },
    });
  }

  async conciliarLote(tenantId: string, contaBancariaId: string) {
    await this.validarConta(tenantId, contaBancariaId);
    const conciliadas = await this.match.conciliarAutomaticamente(tenantId, contaBancariaId);
    return { conciliadas };
  }

  async dashboard(tenantId: string, contaBancariaId?: string) {
    const where: any = { tenantId };
    if (contaBancariaId) where.contaBancariaId = contaBancariaId;

    const [total, conciliados, pendentes] = await Promise.all([
      this.prisma.extratoBancario.count({ where }),
      this.prisma.extratoBancario.count({ where: { ...where, conciliado: true } }),
      this.prisma.extratoBancario.count({ where: { ...where, conciliado: false } }),
    ]);

    const somaPendentes = await this.prisma.extratoBancario.aggregate({
      where: { ...where, conciliado: false },
      _sum: { valor: true },
    });

    return {
      total,
      conciliados,
      pendentes,
      percentualConciliado: total > 0 ? Number(((conciliados / total) * 100).toFixed(2)) : 0,
      valorPendente: Number(somaPendentes._sum.valor ?? 0),
    };
  }

  private async validarConta(tenantId: string, contaId: string) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');
    return conta;
  }
}
