import { FilterLancamentoDto } from './dto/filter-lancamento.dto';
import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateLancamentoDto } from './dto/create-lancamento.dto';
import { PartidasDobradasValidator } from './validators/partidas-dobradas.validator';

@Injectable()
export class LancamentosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validator: PartidasDobradasValidator,
  ) {}

  /**
   * Lista lançamentos paginados com filtros (usado pelo frontend).
   */
  async listarPaginado(
    tenantId: string,
    empresaId: string,
    competencia?: string,
    page = 1,
    limit = 30,
  ) {
    if (!empresaId) {
      throw new BadRequestException('empresaId é obrigatório');
    }

    const where: Prisma.LancamentoWhereInput = {
      tenantId,
      empresaId,
    };

    if (competencia) {
      where.competencia = new Date(competencia);
    }

    const [total, data] = await Promise.all([
      this.prisma.lancamento.count({ where }),
      this.prisma.lancamento.findMany({
        where,
        skip: (page - 1) * limit,
        take: limit,
        orderBy: [{ dataLancamento: 'desc' }, { numero: 'desc' }],
        include: {
          partidas: {
            include: {
              conta: { select: { id: true, codigo: true, nome: true, natureza: true } },
              centroCusto: { select: { id: true, codigo: true, nome: true } },
            },
          },
        },
      }),
    ]);

    return {
      data,
      meta: {
        total,
        page,
        limit,
        totalPages: Math.ceil(total / limit),
      },
    };
  }

  /**
   * Lista simples (compatibilidade com chamadas antigas).
   */



async listar(tenantId: string, filtro: FilterLancamentoDto) {
  const { empresaId, competencia, page, limit } = filtro;

  const where = {
    tenantId,
    empresaId,
    status: 'ATIVO' as const,
    ...(competencia && { competencia: new Date(competencia) }),
  };

  const [data, total] = await this.prisma.$transaction([
    this.prisma.lancamento.findMany({
      where,
      include: {
        partidas: {
          include: { conta: { select: { id: true, codigo: true, nome: true } } },
        },
      },
      orderBy: [{ dataLancamento: 'desc' }, { numero: 'desc' }],
      skip: (page - 1) * limit,
      take: limit,
    }),
    this.prisma.lancamento.count({ where }),
  ]);

  return {
    data,
    meta: {
      page,
      limit,
      total,
      totalPages: Math.ceil(total / limit),
      hasNext: page * limit < total,
      hasPrev: page > 1,
    },
  };
}

  async buscarPorId(tenantId: string, id: string) {
    const lancamento = await this.prisma.lancamento.findFirst({
      where: { id, tenantId },
      include: {
        partidas: {
          include: {
            conta: {
              select: { id: true, codigo: true, nome: true, natureza: true },
            },
            centroCusto: { select: { id: true, codigo: true, nome: true } },
          },
        },
        empresa: { select: { id: true, razaoSocial: true, cnpj: true } },
      },
    });

    if (!lancamento) throw new NotFoundException('Lançamento não encontrado');
    return lancamento;
  }

  async criar(tenantId: string, dto: CreateLancamentoDto) {
    this.validator.validar(dto.partidas);

    await this.validarEmpresa(tenantId, dto.empresaId);
    await this.validarPeriodoAberto(dto.empresaId, dto.competencia);
    await this.validarContas(tenantId, dto.partidas.map((p) => p.contaId));

    const valorTotal = dto.partidas
      .filter((p) => p.tipo === 'D')
      .reduce((acc, p) => acc + Number(p.valor), 0);

    return this.prisma.lancamento.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        loteId: dto.loteId,
        dataLancamento: new Date(dto.dataLancamento),
        competencia: new Date(dto.competencia),
        historico: dto.historico,
        documentoRef: dto.documentoRef,
        valorTotal,
        partidas: {
          create: dto.partidas.map((p) => ({
            tenantId,
            contaId: p.contaId,
            centroCustoId: p.centroCustoId,
            tipo: p.tipo,
            valor: p.valor,
          })),
        },
      },
      include: {
        partidas: {
          include: { conta: { select: { id: true, codigo: true, nome: true } } },
        },
      },
    });
  }

  async estornar(tenantId: string, id: string, motivo: string) {
    const original = await this.prisma.lancamento.findFirst({
      where: { id, tenantId, status: 'ATIVO' },
      include: { partidas: true },
    });

    if (!original) {
      throw new NotFoundException('Lançamento não encontrado ou já estornado');
    }

    await this.validarPeriodoAberto(
      original.empresaId,
      original.competencia.toISOString().slice(0, 10),
    );

    return this.prisma.$transaction(async (tx) => {
      await tx.lancamento.update({
        where: { id: original.id },
        data: { status: 'ESTORNADO' },
      });

      return tx.lancamento.create({
        data: {
          tenantId,
          empresaId: original.empresaId,
          dataLancamento: new Date(),
          competencia: original.competencia,
          historico: `ESTORNO: ${motivo}`,
          documentoRef: original.documentoRef,
          valorTotal: original.valorTotal,
          estornoDeId: original.id,
          partidas: {
            create: original.partidas.map((p) => ({
              tenantId,
              contaId: p.contaId,
              centroCustoId: p.centroCustoId,
              tipo: p.tipo === 'D' ? 'C' : 'D',
              valor: p.valor,
            })),
          },
        },
        include: { partidas: true },
      });
    });
  }

  // ============================================================
  // Validações privadas
  // ============================================================

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }

  private async validarPeriodoAberto(empresaId: string, competencia: string) {
    const fechamento = await this.prisma.fechamentoPeriodo.findUnique({
      where: {
        uk_fechamento_empresa_comp: {
          empresaId,
          competencia: new Date(competencia),
        },
      },
    });

    if (fechamento?.status === 'FECHADO') {
      throw new BadRequestException('Período fechado para lançamentos');
    }
  }

  private async validarContas(tenantId: string, contaIds: string[]) {
    const contas = await this.prisma.conta.findMany({
      where: { id: { in: contaIds }, tenantId },
      select: { id: true, aceitaLancamento: true, status: true },
    });

    if (contas.length !== contaIds.length) {
      throw new BadRequestException('Uma ou mais contas não existem');
    }

    const invalidas = contas.filter((c) => !c.aceitaLancamento || c.status !== 'ATIVO');
    if (invalidas.length > 0) {
      throw new BadRequestException(
        'Uma ou mais contas não aceitam lançamento ou estão inativas',
      );
    }
  }
}