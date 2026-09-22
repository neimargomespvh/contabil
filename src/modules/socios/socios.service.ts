import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateSocioDto } from './dto/create-socio.dto';
import { UpdateSocioDto } from './dto/update-socio.dto';
import { validarCpf, limparCpf } from '../../common/utils/cpf.util';

@Injectable()
export class SociosService {
  constructor(private readonly prisma: PrismaService) {}

  async listarPorEmpresa(tenantId: string, empresaId: string) {
    await this.validarEmpresa(tenantId, empresaId);

    const socios = await this.prisma.socio.findMany({
      where: { tenantId, empresaId, status: 'ativo' },
      orderBy: { nome: 'asc' },
    });

    const totalParticipacao = socios.reduce(
      (acc, s) => acc + Number(s.participacao),
      0,
    );

    return {
      data: socios,
      resumo: {
        total: socios.length,
        participacaoTotal: Number(totalParticipacao.toFixed(6)),
        participacaoCompleta: Math.abs(totalParticipacao - 100) < 0.0001,
      },
    };
  }

  async buscarPorId(tenantId: string, id: string) {
    const socio = await this.prisma.socio.findFirst({
      where: { id, tenantId },
    });
    if (!socio) throw new NotFoundException('Sócio não encontrado');
    return socio;
  }

  async criar(tenantId: string, dto: CreateSocioDto) {
    await this.validarEmpresa(tenantId, dto.empresaId);

    const cpfLimpo = limparCpf(dto.cpf);
    if (!validarCpf(cpfLimpo)) throw new BadRequestException('CPF inválido');

    const existente = await this.prisma.socio.findFirst({
      where: { empresaId: dto.empresaId, cpf: cpfLimpo },
    });
    if (existente) throw new ConflictException('CPF já cadastrado nesta empresa');

    await this.validarSomaParticipacao(dto.empresaId, dto.participacao, null);

    return this.prisma.socio.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        nome: dto.nome,
        cpf: cpfLimpo,
        participacao: dto.participacao,
        proLabore: dto.proLabore,
        dataEntrada: dto.dataEntrada ? new Date(dto.dataEntrada) : undefined,
        dataSaida: dto.dataSaida ? new Date(dto.dataSaida) : undefined,
      },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateSocioDto) {
    const socio = await this.prisma.socio.findFirst({ where: { id, tenantId } });
    if (!socio) throw new NotFoundException('Sócio não encontrado');

    if (dto.cpf) {
      const cpfLimpo = limparCpf(dto.cpf);
      if (!validarCpf(cpfLimpo)) throw new BadRequestException('CPF inválido');

      if (cpfLimpo !== socio.cpf) {
        const existente = await this.prisma.socio.findFirst({
          where: { empresaId: socio.empresaId, cpf: cpfLimpo, NOT: { id } },
        });
        if (existente) throw new ConflictException('CPF já cadastrado');
      }
    }

    if (dto.participacao !== undefined) {
      await this.validarSomaParticipacao(socio.empresaId, dto.participacao, id);
    }

    return this.prisma.socio.update({
      where: { id },
      data: {
        nome: dto.nome,
        cpf: dto.cpf ? limparCpf(dto.cpf) : undefined,
        participacao: dto.participacao,
        proLabore: dto.proLabore,
        dataEntrada: dto.dataEntrada ? new Date(dto.dataEntrada) : undefined,
        dataSaida: dto.dataSaida ? new Date(dto.dataSaida) : undefined,
      },
    });
  }

  async remover(tenantId: string, id: string) {
    const socio = await this.prisma.socio.findFirst({ where: { id, tenantId } });
    if (!socio) throw new NotFoundException('Sócio não encontrado');

    await this.prisma.socio.update({
      where: { id },
      data: { status: 'inativo', dataSaida: new Date() },
    });
    return { message: 'Sócio removido' };
  }

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }

  private async validarSomaParticipacao(
    empresaId: string,
    novaParticipacao: number,
    socioIdExistente: string | null,
  ) {
    const sociosAtivos = await this.prisma.socio.findMany({
      where: {
        empresaId,
        status: 'ativo',
        ...(socioIdExistente ? { NOT: { id: socioIdExistente } } : {}),
      },
      select: { participacao: true },
    });

    const somaAtual = sociosAtivos.reduce(
      (acc, s) => acc + Number(s.participacao),
      0,
    );
    const somaTotal = somaAtual + novaParticipacao;

    if (somaTotal > 100.0001) {
      throw new BadRequestException(
        `Soma das participações ultrapassaria 100%. Atual: ${somaAtual.toFixed(4)}%, ` +
        `nova: ${novaParticipacao}%, total: ${somaTotal.toFixed(4)}%`,
      );
    }
  }
}
