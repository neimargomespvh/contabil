import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { paginar } from '../../common/dto/pagination.dto';
import { CreateRegraDto } from './dto/create-regra.dto';
import { UpdateRegraDto } from './dto/update-regra.dto';
import { FilterRegraDto } from './dto/filter-regra.dto';
import { ReordenarRegrasDto } from './dto/reordenar.dto';
import { CondicaoValidator } from './validators/condicao.validator';

@Injectable()
export class RegrasContabilizacaoService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly condicaoValidator: CondicaoValidator,
  ) {}

  async criar(tenantId: string, dto: CreateRegraDto) {
    await this.validarEmpresa(tenantId, dto.empresaId);
    this.condicaoValidator.validar(dto.condicao);
    await this.validarContas(tenantId, dto.empresaId, [
      dto.contaDebitoId,
      dto.contaCreditoId,
    ]);

    // Verificar conflito de prioridade na mesma empresa
    const conflito = await this.prisma.regraContabilizacao.findFirst({
      where: {
        tenantId,
        empresaId: dto.empresaId,
        prioridade: dto.prioridade,
        status: 'ATIVO',
      },
    });
    if (conflito) {
      throw new ConflictException(
        `Já existe uma regra ativa com prioridade ${dto.prioridade} nesta empresa`,
      );
    }

    return this.prisma.regraContabilizacao.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        nome: dto.nome,
        prioridade: dto.prioridade,
        condicao: dto.condicao as Prisma.InputJsonValue,
        contaDebitoId: dto.contaDebitoId,
        contaCreditoId: dto.contaCreditoId,
        historicoTemplate: dto.historicoTemplate,
        status: 'ATIVO',
      },
      include: {
        contaDebito: { select: { id: true, codigo: true, nome: true } },
        contaCredito: { select: { id: true, codigo: true, nome: true } },
      },
    });
  }

  async listar(tenantId: string, filtros: FilterRegraDto) {
    const where: Prisma.RegraContabilizacaoWhereInput = {
      tenantId,
      empresaId: filtros.empresaId,
    };

    if (filtros.nome) {
      where.nome = { contains: filtros.nome, mode: 'insensitive' };
    }
    if (filtros.status) {
      where.status = filtros.status as any;
    }
    if (filtros.cfop) {
      where.condicao = { path: ['cfop'], equals: filtros.cfop };
    }
    if (filtros.ncm) {
      where.condicao = { path: ['ncm'], equals: filtros.ncm };
    }

    const [total, data] = await Promise.all([
      this.prisma.regraContabilizacao.count({ where }),
      this.prisma.regraContabilizacao.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: [{ prioridade: 'asc' }, { createdAt: 'desc' }],
        include: {
          contaDebito: { select: { id: true, codigo: true, nome: true } },
          contaCredito: { select: { id: true, codigo: true, nome: true } },
        },
      }),
    ]);

    return paginar(data, total, filtros.page, filtros.limit);
  }

  async buscarPorId(tenantId: string, id: string) {
    const regra = await this.prisma.regraContabilizacao.findFirst({
      where: { id, tenantId },
      include: {
        contaDebito: { select: { id: true, codigo: true, nome: true } },
        contaCredito: { select: { id: true, codigo: true, nome: true } },
        empresa: { select: { id: true, razaoSocial: true, cnpj: true } },
      },
    });
    if (!regra) throw new NotFoundException('Regra não encontrada');
    return regra;
  }

  async atualizar(tenantId: string, id: string, dto: UpdateRegraDto) {
    const existente = await this.buscarPorId(tenantId, id);

    if (dto.condicao) this.condicaoValidator.validar(dto.condicao);

    if (dto.contaDebitoId || dto.contaCreditoId) {
      await this.validarContas(tenantId, existente.empresaId, [
        dto.contaDebitoId ?? existente.contaDebitoId,
        dto.contaCreditoId ?? existente.contaCreditoId,
      ]);
    }

    if (dto.prioridade && dto.prioridade !== existente.prioridade) {
      const conflito = await this.prisma.regraContabilizacao.findFirst({
        where: {
          tenantId,
          empresaId: existente.empresaId,
          prioridade: dto.prioridade,
          status: 'ATIVO',
          id: { not: id },
        },
      });
      if (conflito) {
        throw new ConflictException(
          `Já existe uma regra ativa com prioridade ${dto.prioridade}`,
        );
      }
    }

    return this.prisma.regraContabilizacao.update({
      where: { id },
      data: {
        nome: dto.nome,
        prioridade: dto.prioridade,
        condicao: dto.condicao as Prisma.InputJsonValue | undefined,
        contaDebitoId: dto.contaDebitoId,
        contaCreditoId: dto.contaCreditoId,
        historicoTemplate: dto.historicoTemplate,
      },
      include: {
        contaDebito: { select: { id: true, codigo: true, nome: true } },
        contaCredito: { select: { id: true, codigo: true, nome: true } },
      },
    });
  }

  async inativar(tenantId: string, id: string) {
    await this.buscarPorId(tenantId, id);
    return this.prisma.regraContabilizacao.update({
      where: { id },
      data: { status: 'INATIVO' },
    });
  }

  async reativar(tenantId: string, id: string) {
    const regra = await this.buscarPorId(tenantId, id);
    const conflito = await this.prisma.regraContabilizacao.findFirst({
      where: {
        tenantId,
        empresaId: regra.empresaId,
        prioridade: regra.prioridade,
        status: 'ATIVO',
        id: { not: id },
      },
    });
    if (conflito) {
      throw new ConflictException(
        `Já existe uma regra ativa com prioridade ${regra.prioridade}`,
      );
    }
    return this.prisma.regraContabilizacao.update({
      where: { id },
      data: { status: 'ATIVO' },
    });
  }

  async excluir(tenantId: string, id: string) {
    await this.buscarPorId(tenantId, id);
    await this.prisma.regraContabilizacao.delete({ where: { id } });
    return { deleted: true };
  }

  async reordenar(tenantId: string, dto: ReordenarRegrasDto) {
    const ids = dto.regras.map((r) => r.id);
    const existentes = await this.prisma.regraContabilizacao.findMany({
      where: { id: { in: ids }, tenantId },
    });

    if (existentes.length !== ids.length) {
      throw new BadRequestException('Uma ou mais regras não foram encontradas');
    }

    const empresas = new Set(existentes.map((r) => r.empresaId));
    if (empresas.size > 1) {
      throw new BadRequestException(
        'Todas as regras devem pertencer à mesma empresa',
      );
    }

    await this.prisma.$transaction(
      dto.regras.map((r) =>
        this.prisma.regraContabilizacao.update({
          where: { id: r.id },
          data: { prioridade: r.prioridade },
        }),
      ),
    );

    return { updated: dto.regras.length };
  }

  async simular(tenantId: string, empresaId: string, xml: string) {
    // Importa o parser dinamicamente para não criar dependência circular
    const { DocumentoFiscalParser } = await import(
      '../documentos-fiscais/parsers'
    );
    const parser = new DocumentoFiscalParser();
    const parsed = await parser.parse(xml);

    const regras = await this.prisma.regraContabilizacao.findMany({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { prioridade: 'asc' },
      include: {
        contaDebito: { select: { id: true, codigo: true, nome: true } },
        contaCredito: { select: { id: true, codigo: true, nome: true } },
      },
    });

    for (const regra of regras) {
      if (this.casaCondicao(regra.condicao as any, parsed)) {
        return {
          casou: true,
          regra: {
            id: regra.id,
            nome: regra.nome,
            prioridade: regra.prioridade,
            historicoTemplate: regra.historicoTemplate,
            contaDebito: regra.contaDebito,
            contaCredito: regra.contaCredito,
          },
          documento: {
            tipo: parsed.tipo,
            chaveAcesso: parsed.chaveAcesso,
            cfop: parsed.cfopPrincipal,
            ncm: parsed.ncmPrincipal,
            emitenteCnpj: parsed.emitenteCnpj,
            valorTotal: parsed.valorTotal,
            situacao: parsed.situacao,
          },
          historicoPreview: this.renderHistorico(
            regra.historicoTemplate ?? 'NF {numero} - {emitente}',
            parsed,
          ),
        };
      }
    }

    return {
      casou: false,
      motivo: 'Nenhuma regra compatível',
      documento: {
        tipo: parsed.tipo,
        chaveAcesso: parsed.chaveAcesso,
        cfop: parsed.cfopPrincipal,
        ncm: parsed.ncmPrincipal,
        emitenteCnpj: parsed.emitenteCnpj,
      },
    };
  }

  // ─────────────────────────────────────────────────
  // HELPERS
  // ─────────────────────────────────────────────────

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }

  private async validarContas(
    tenantId: string,
    empresaId: string,
    contaIds: string[],
  ) {
    const contas = await this.prisma.conta.findMany({
      where: {
        id: { in: contaIds },
        tenantId,
        planoContas: { empresaId },
      },
      select: { id: true, aceitaLancamento: true, status: true },
    });

    if (contas.length !== contaIds.length) {
      throw new BadRequestException(
        'Uma ou mais contas não existem ou não pertencem à empresa',
      );
    }

    const invalidas = contas.filter(
      (c) => !c.aceitaLancamento || c.status !== 'ATIVO',
    );
    if (invalidas.length) {
      throw new BadRequestException(
        'Todas as contas devem ser analíticas e estar ativas',
      );
    }
  }

  private casaCondicao(cond: any, parsed: any): boolean {
    if (!cond) return false;

    if (cond.cfop && cond.cfop !== parsed.cfopPrincipal) return false;
    if (cond.cfopPrefix && !String(parsed.cfopPrincipal ?? '').startsWith(cond.cfopPrefix))
      return false;
    if (cond.ncm && cond.ncm !== parsed.ncmPrincipal) return false;
    if (cond.ncmPrefix && !String(parsed.ncmPrincipal ?? '').startsWith(cond.ncmPrefix))
      return false;
    if (cond.emitenteCnpj && cond.emitenteCnpj !== parsed.emitenteCnpj) return false;
    if (cond.destinatarioCnpj && cond.destinatarioCnpj !== parsed.destinatarioCnpj)
      return false;
    if (cond.tipo && cond.tipo !== parsed.tipo) return false;

    return true;
  }

  private renderHistorico(template: string, parsed: any): string {
    return template
      .replace('{numero}', parsed.numero ?? '')
      .replace('{serie}', parsed.serie ?? '')
      .replace('{emitente}', parsed.emitenteNome ?? '')
      .replace('{chave}', parsed.chaveAcesso ?? '')
      .replace('{cfop}', parsed.cfopPrincipal ?? '')
      .substring(0, 500);
  }
}
