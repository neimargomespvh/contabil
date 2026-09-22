import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreatePlanoDto } from './dto/create-plano.dto';
import { CreateContaDto } from './dto/create-conta.dto';
import { UpdateContaDto } from './dto/update-conta.dto';
import { PLANO_PADRAO } from './seeds/plano-padrao';

@Injectable()
export class PlanoContasService {
  constructor(private readonly prisma: PrismaService) {}

  /**
   * Lista os planos de conta da empresa.
   */
  async listarPlanos(tenantId: string, empresaId: string) {
    await this.validarEmpresa(tenantId, empresaId);

    return this.prisma.planoContas.findMany({
      where: { tenantId, empresaId },
      orderBy: { versao: 'desc' },
      include: { _count: { select: { contas: true } } },
    });
  }

  /**
   * Cria um plano de contas vazio para a empresa, com a próxima versão.
   */
  async criarPlano(tenantId: string, empresaId: string, dto: CreatePlanoDto) {
    await this.validarEmpresa(tenantId, empresaId);

    const ultimo = await this.prisma.planoContas.findFirst({
      where: { empresaId },
      orderBy: { versao: 'desc' },
    });
    const proximaVersao = (ultimo?.versao ?? 0) + 1;

    return this.prisma.planoContas.create({
      data: {
        tenantId,
        empresaId,
        nome: dto.nome,
        versao: proximaVersao,
        vigenciaInicio: new Date(dto.vigenciaInicio),
        vigenciaFim: dto.vigenciaFim ? new Date(dto.vigenciaFim) : undefined,
      },
    });
  }

  /**
   * Cria um plano já populado com o plano padrão brasileiro.
   */
  async criarPlanoPadrao(tenantId: string, empresaId: string, nome = 'Plano Padrão RFB') {
    await this.validarEmpresa(tenantId, empresaId);

    const ultimo = await this.prisma.planoContas.findFirst({
      where: { empresaId },
      orderBy: { versao: 'desc' },
    });
    const proximaVersao = (ultimo?.versao ?? 0) + 1;

    return this.prisma.$transaction(async (tx) => {
      const plano = await tx.planoContas.create({
        data: {
          tenantId,
          empresaId,
          nome,
          versao: proximaVersao,
          vigenciaInicio: new Date(),
        },
      });

      // Mapa de código → id para resolver contaPai
      const mapa: Record<string, string> = {};

      // Ordena por quantidade de pontos (pai antes de filho)
      const ordenado = [...PLANO_PADRAO].sort(
        (a, b) => a.codigo.split('.').length - b.codigo.split('.').length,
      );

      for (const contaPadrao of ordenado) {
        const partes = contaPadrao.codigo.split('.');
        const codigoPai = partes.length > 1 ? partes.slice(0, -1).join('.') : null;
        const contaPaiId = codigoPai ? mapa[codigoPai] ?? null : null;

        const conta = await tx.conta.create({
          data: {
            tenantId,
            planoContasId: plano.id,
            contaPaiId,
            codigo: contaPadrao.codigo,
            nome: contaPadrao.nome,
            natureza: contaPadrao.natureza,
            tipo: contaPadrao.tipo,
            grau: partes.length,
            aceitaLancamento: contaPadrao.tipo === 'ANALITICA',
            dreLinha: contaPadrao.dreLinha,
          },
        });
        mapa[contaPadrao.codigo] = conta.id;
      }

      return plano;
    });
  }

  /**
   * Lista todas as contas de um plano, em ordem hierárquica.
   */
  async listarContas(tenantId: string, planoId: string) {
    const plano = await this.prisma.planoContas.findFirst({
      where: { id: planoId, tenantId },
    });
    if (!plano) throw new NotFoundException('Plano de contas não encontrado');

    const contas = await this.prisma.conta.findMany({
      where: { planoContasId: planoId, tenantId },
      orderBy: { codigo: 'asc' },
    });

    return this.montarArvore(contas);
  }

  /**
   * Monta uma árvore hierárquica de contas.
   */
  private montarArvore(contas: any[]) {
    const mapa = new Map<string, any>();
    const raizes: any[] = [];

    for (const c of contas) {
      mapa.set(c.id, { ...c, filhas: [] });
    }

    for (const c of contas) {
      const node = mapa.get(c.id);
      if (c.contaPaiId && mapa.has(c.contaPaiId)) {
        mapa.get(c.contaPaiId).filhas.push(node);
      } else {
        raizes.push(node);
      }
    }

    return raizes;
  }

  /**
   * Cria uma nova conta dentro de um plano.
   */
  async criarConta(tenantId: string, planoId: string, dto: CreateContaDto) {
    const plano = await this.prisma.planoContas.findFirst({
      where: { id: planoId, tenantId },
    });
    if (!plano) throw new NotFoundException('Plano de contas não encontrado');

    const existente = await this.prisma.conta.findFirst({
      where: { planoContasId: planoId, codigo: dto.codigo },
    });
    if (existente) throw new ConflictException('Já existe uma conta com esse código');

    let grau = dto.codigo.split('.').length;

    if (dto.contaPaiId) {
      const pai = await this.prisma.conta.findFirst({
        where: { id: dto.contaPaiId, planoContasId: planoId, tenantId },
      });
      if (!pai) throw new NotFoundException('Conta pai não encontrada');
      if (pai.tipo === 'ANALITICA') {
        throw new BadRequestException('Conta analítica não pode ter filhas');
      }
      grau = pai.grau + 1;

      // Valida que o código da filha começa com o código do pai + "."
      if (!dto.codigo.startsWith(`${pai.codigo}.`)) {
        throw new BadRequestException(
          `O código da conta filha deve começar com "${pai.codigo}."`,
        );
      }
    }

    return this.prisma.conta.create({
      data: {
        tenantId,
        planoContasId: planoId,
        contaPaiId: dto.contaPaiId,
        codigo: dto.codigo,
        nome: dto.nome,
        natureza: dto.natureza,
        tipo: dto.tipo,
        grau,
        aceitaLancamento: dto.tipo === 'ANALITICA',
        dreLinha: dto.dreLinha,
      },
    });
  }

  /**
   * Atualiza uma conta existente.
   */
  async atualizarConta(tenantId: string, contaId: string, dto: UpdateContaDto) {
    const conta = await this.prisma.conta.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta não encontrada');

    if (dto.codigo && dto.codigo !== conta.codigo) {
      const existente = await this.prisma.conta.findFirst({
        where: { planoContasId: conta.planoContasId, codigo: dto.codigo, NOT: { id: contaId } },
      });
      if (existente) throw new ConflictException('Já existe conta com esse código');
    }

    if (dto.tipo === 'SINTETICA' && conta.tipo === 'ANALITICA') {
      const filhas = await this.prisma.conta.count({ where: { contaPaiId: contaId } });
      const partidas = await this.prisma.partida.count({ where: { contaId } });
      if (partidas > 0) {
        throw new BadRequestException(
          'Não é possível tornar sintética uma conta que já possui lançamentos',
        );
      }
      if (filhas === 0 && dto.tipo === 'SINTETICA') {
        // ok, apenas avisa
      }
    }

    return this.prisma.conta.update({
      where: { id: contaId },
      data: {
        codigo: dto.codigo,
        nome: dto.nome,
        natureza: dto.natureza,
        tipo: dto.tipo,
        aceitaLancamento: dto.tipo ? dto.tipo === 'ANALITICA' : undefined,
        dreLinha: dto.dreLinha,
      },
    });
  }

  /**
   * Remove uma conta — bloqueado se tiver filhas ou lançamentos.
   */
  async removerConta(tenantId: string, contaId: string) {
    const conta = await this.prisma.conta.findFirst({
      where: { id: contaId, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta não encontrada');

    const filhas = await this.prisma.conta.count({ where: { contaPaiId: contaId } });
    if (filhas > 0) throw new BadRequestException('Conta possui contas filhas');

    const partidas = await this.prisma.partida.count({ where: { contaId } });
    if (partidas > 0) {
      throw new BadRequestException('Conta possui lançamentos vinculados');
    }

    await this.prisma.conta.delete({ where: { id: contaId } });
    return { message: 'Conta removida' };
  }

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }
}
