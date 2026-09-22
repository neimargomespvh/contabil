import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { Prisma } from '@prisma/client';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { S3Service } from '../../infra/s3/s3.service';
import { SimplesCalculator } from './calculators/simples.calculator';
import { PresumidoCalculator } from './calculators/presumido.calculator';
import { MeiCalculator } from './calculators/mei.calculator';
import { GuiaGenerator } from './guias/guia.generator';
import { CalcularApuracaoDto, RegimeTributarioEnum } from './dto/calcular-apuracao.dto';
import { FilterApuracaoDto } from './dto/filter-apuracao.dto';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class ApuracoesService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly s3: S3Service,
    private readonly simples: SimplesCalculator,
    private readonly presumido: PresumidoCalculator,
    private readonly mei: MeiCalculator,
    private readonly guiaGen: GuiaGenerator,
  ) {}

  async calcular(tenantId: string, dto: CalcularApuracaoDto) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: dto.empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    const competencia = new Date(dto.competencia);

    // Verificar se já existe apuração nessa competência
    const existente = await this.prisma.apuracao.findFirst({
      where: {
        tenantId,
        empresaId: dto.empresaId,
        competencia,
        regime: dto.regime as any,
      },
    });
    if (existente) {
      throw new ConflictException(
        `Já existe apuração para ${competencia.toISOString().slice(0, 10)} no regime ${dto.regime}`,
      );
    }

    // Rotear para calculadora correta
    let resultado: any;
    switch (dto.regime) {
      case RegimeTributarioEnum.SIMPLES:
        if (!dto.anexoSimples) {
          throw new BadRequestException('Anexo do Simples é obrigatório');
        }
        resultado = this.simples.calcular({
          receitaBruta: dto.receitaBruta,
          receitaBruta12Meses: dto.receitaBruta12Meses ?? dto.receitaBruta * 12,
          anexo: dto.anexoSimples,
          folha12Meses: dto.folha12Meses,
          retencoes: dto.retencoes,
        });
        break;

      case RegimeTributarioEnum.PRESUMIDO:
        resultado = this.presumido.calcular({
          receitaBruta: dto.receitaBruta,
          tipoAtividade: dto.tipoAtividade ?? 'SERVICOS',
          aliquotaIss: dto.aliquotaIss,
          aliquotaIcms: dto.aliquotaIcms,
          retencoes: dto.retencoes,
        });
        break;

      case RegimeTributarioEnum.MEI:
        resultado = this.mei.calcular({
          tipoAtividade: (dto.tipoAtividade ?? 'COMERCIO') as any,
          receitaAcumulada: dto.receitaBruta12Meses,
        });
        break;

      case RegimeTributarioEnum.REAL:
        throw new BadRequestException(
          'Regime Lucro Real será implementado em versão futura',
        );

      default:
        throw new BadRequestException('Regime tributário inválido');
    }

    // Persistir apuração
    const apuracao = await this.prisma.$transaction(async (tx) => {
      const valorAPagar = this.extrairValorAPagar(resultado);
      const baseCalculo = this.extrairBaseCalculo(resultado, dto.receitaBruta);

      const apuracaoCriada = await tx.apuracao.create({
        data: {
          tenantId,
          empresaId: dto.empresaId,
          competencia,
          regime: dto.regime as any,
          anexoSimples: dto.anexoSimples as any,
          receitaBruta: dto.receitaBruta,
          baseCalculo,
          aliquota: resultado.aliquotaEfetiva
            ? Number(resultado.aliquotaEfetiva) / 100
            : resultado.irpj?.aliquota
              ? Number(resultado.irpj.aliquota) / 100
              : null,
          valorDevido: this.extrairValorDevido(resultado),
          valorDeducao: resultado.valorDeducao ?? null,
          valorAPagar,
          status: 'CALCULADA',
        },
      });

      // Persistir impostos individuais
      const impostos = this.extrairImpostos(resultado);
      for (const imp of impostos) {
        await tx.apuracaoImposto.create({
          data: {
            tenantId,
            apuracaoId: apuracaoCriada.id,
            imposto: imp.imposto as any,
            baseCalculo: imp.base,
            aliquota: imp.aliquota ? imp.aliquota / 100 : null,
            valor: imp.valor,
          },
        });
      }

      return apuracaoCriada;
    });

    return {
      apuracao,
      detalhamento: resultado,
    };
  }

  async listar(tenantId: string, filtros: FilterApuracaoDto) {
    const where: Prisma.ApuracaoWhereInput = { tenantId };
    if (filtros.empresaId) where.empresaId = filtros.empresaId;
    if (filtros.regime) where.regime = filtros.regime as any;

    if (filtros.competenciaInicio || filtros.competenciaFim) {
      where.competencia = {};
      if (filtros.competenciaInicio) (where.competencia as any).gte = new Date(filtros.competenciaInicio);
      if (filtros.competenciaFim) (where.competencia as any).lte = new Date(filtros.competenciaFim);
    }

    const [total, data] = await Promise.all([
      this.prisma.apuracao.count({ where }),
      this.prisma.apuracao.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { competencia: filtros.order },
        include: {
          impostos: true,
          empresa: { select: { razaoSocial: true, cnpj: true } },
        },
      }),
    ]);

    return paginar(data, total, filtros.page, filtros.limit);
  }

  async buscarPorId(tenantId: string, id: string) {
    const apuracao = await this.prisma.apuracao.findFirst({
      where: { id, tenantId },
      include: {
        impostos: true,
        guias: true,
        empresa: { select: { id: true, razaoSocial: true, cnpj: true } },
      },
    });
    if (!apuracao) throw new NotFoundException('Apuração não encontrada');
    return apuracao;
  }

  async gerarGuia(tenantId: string, apuracaoId: string) {
    const apuracao = await this.buscarPorId(tenantId, apuracaoId);

    const tipoGuia = this.definirTipoGuia(apuracao.regime);
    const vencimento = this.calcularVencimento(apuracao.competencia, apuracao.regime);

    const dadosGuia = {
      tipo: tipoGuia,
      razaoSocial: apuracao.empresa.razaoSocial,
      cnpj: apuracao.empresa.cnpj,
      periodoApuracao: this.formatarCompetencia(apuracao.competencia),
      vencimento: vencimento.toLocaleDateString('pt-BR'),
      valor: Number(apuracao.valorAPagar),
      codigoReceita: this.codigoReceita(tipoGuia),
      detalhes: apuracao.impostos.reduce(
        (acc, i) => ({ ...acc, [i.imposto]: this.formatarMoeda(Number(i.valor)) }),
        {} as Record<string, string>,
      ),
    };

    // Gerar PDF
    const pdfBuffer = await this.guiaGen.gerar(dadosGuia);

    // Upload para S3
    const s3Key = `tenants/${tenantId}/guias/${apuracaoId}-${tipoGuia}.pdf`;
    await this.s3.upload(s3Key, pdfBuffer, 'application/pdf');

    // Persistir guia
    const guia = await this.prisma.guia.create({
      data: {
        tenantId,
        empresaId: apuracao.empresaId,
        apuracaoId: apuracao.id,
        tipo: tipoGuia as any,
        codigoReceita: dadosGuia.codigoReceita,
        periodoApuracao: apuracao.competencia,
        vencimento,
        valor: Number(apuracao.valorAPagar ?? 0),
        status: 'GERADA',
        pdfS3Key: s3Key,
      },
    });

    return {
      guia,
      url: await this.s3.presignedUrl(s3Key, 3600),
    };
  }

  async listarGuias(tenantId: string, empresaId?: string) {
    const where: any = { tenantId };
    if (empresaId) where.empresaId = empresaId;

    return this.prisma.guia.findMany({
      where,
      orderBy: { vencimento: 'desc' },
      include: { empresa: { select: { razaoSocial: true, cnpj: true } } },
      take: 100,
    });
  }

  async urlGuia(tenantId: string, guiaId: string) {
    const guia = await this.prisma.guia.findFirst({
      where: { id: guiaId, tenantId },
    });
    if (!guia || !guia.pdfS3Key) throw new NotFoundException('Guia não encontrada');

    return {
      url: await this.s3.presignedUrl(guia.pdfS3Key, 3600),
      guia,
    };
  }

  // ============================================================
  // Helpers
  // ============================================================

  private extrairValorAPagar(resultado: any): number {
    if (resultado.valorAPagar !== undefined) return resultado.valorAPagar;
    if (resultado.total !== undefined) return resultado.total;
    if (resultado.valorDas !== undefined) return resultado.valorDas;
    return 0;
  }

  private extrairValorDevido(resultado: any): number {
    if (resultado.valorDevido !== undefined) return resultado.valorDevido;
    if (resultado.total !== undefined) return resultado.total;
    if (resultado.valorDas !== undefined) return resultado.valorDas;
    return 0;
  }

  private extrairBaseCalculo(resultado: any, receitaBruta: number): number {
    if (resultado.rbt12) return resultado.rbt12;
    if (resultado.irpj?.base) return resultado.irpj.base;
    return receitaBruta;
  }

  private extrairImpostos(resultado: any): Array<{ imposto: string; base: number; aliquota?: number; valor: number }> {
    const impostos: Array<{ imposto: string; base: number; aliquota?: number; valor: number }> = [];

    // Simples: repartição
    if (resultado.valorPorTributo) {
      const mapa: Record<string, string> = {
        IRPJ: 'IRPJ',
        CSLL: 'CSLL',
        PIS: 'PIS',
        COFINS: 'COFINS',
        ISS: 'ISS',
        ICMS: 'ICMS',
        CPP: 'IRPJ', // CPP não tem enum próprio, usamos IRPJ
        IPI: 'IRPJ',
      };
      for (const [tributo, valor] of Object.entries(resultado.valorPorTributo)) {
        const impostoEnum = mapa[tributo];
        if (impostoEnum) {
          impostos.push({ imposto: impostoEnum, base: 0, valor: Number(valor) });
        }
      }
      return impostos;
    }

    // Presumido
    if (resultado.irpj) {
      impostos.push({ imposto: 'IRPJ', base: resultado.irpj.base, aliquota: 15, valor: resultado.irpj.valor + resultado.irpj.adicional });
    }
    if (resultado.csll) {
      impostos.push({ imposto: 'CSLL', base: resultado.csll.base, aliquota: 9, valor: resultado.csll.valor });
    }
    if (resultado.pis) {
      impostos.push({ imposto: 'PIS', base: resultado.pis.base, aliquota: 0.65, valor: resultado.pis.valor });
    }
    if (resultado.cofins) {
      impostos.push({ imposto: 'COFINS', base: resultado.cofins.base, aliquota: 3, valor: resultado.cofins.valor });
    }
    if (resultado.iss) {
      impostos.push({ imposto: 'ISS', base: resultado.iss.base, aliquota: resultado.iss.aliquota, valor: resultado.iss.valor });
    }
    if (resultado.icms) {
      impostos.push({ imposto: 'ICMS', base: resultado.icms.base, aliquota: resultado.icms.aliquota, valor: resultado.icms.valor });
    }

    // MEI
    if (resultado.valorDas !== undefined) {
      impostos.push({ imposto: 'DAS', base: 0, valor: resultado.valorDas });
    }

    return impostos;
  }

  private definirTipoGuia(regime: string): 'DAS' | 'DARF' {
    return regime === 'SIMPLES' || regime === 'MEI' ? 'DAS' : 'DARF';
  }

  private codigoReceita(tipo: 'DAS' | 'DARF'): string {
    return tipo === 'DAS' ? '1004' : '2089';
  }

  private calcularVencimento(competencia: Date, regime: string): Date {
    const proximoMes = new Date(competencia);
    proximoMes.setMonth(proximoMes.getMonth() + 1);

    if (regime === 'SIMPLES' || regime === 'MEI') {
      // DAS: dia 20 do mês seguinte
      return new Date(proximoMes.getFullYear(), proximoMes.getMonth(), 20);
    }

    // DARF: último dia do mês seguinte
    return new Date(proximoMes.getFullYear(), proximoMes.getMonth() + 1, 0);
  }

  private formatarCompetencia(data: Date): string {
    const mes = String(data.getMonth() + 1).padStart(2, '0');
    return `${mes}/${data.getFullYear()}`;
  }

  private formatarMoeda(valor: number): string {
    return valor.toLocaleString('pt-BR', { style: 'currency', currency: 'BRL' });
  }
}
