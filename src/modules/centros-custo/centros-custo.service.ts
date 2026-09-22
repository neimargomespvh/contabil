import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateCentroCustoDto } from './dto/create-centro.dto';
import { UpdateCentroCustoDto } from './dto/update-centro.dto';

@Injectable()
export class CentrosCustoService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string, empresaId: string) {
    await this.validarEmpresa(tenantId, empresaId);

    return this.prisma.centroCusto.findMany({
      where: { tenantId, empresaId, status: 'ATIVO' },
      orderBy: { codigo: 'asc' },
    });
  }

  async criar(tenantId: string, dto: CreateCentroCustoDto) {
    await this.validarEmpresa(tenantId, dto.empresaId);

    const existente = await this.prisma.centroCusto.findFirst({
      where: { empresaId: dto.empresaId, codigo: dto.codigo },
    });
    if (existente) throw new ConflictException('Já existe um centro de custo com esse código');

    return this.prisma.centroCusto.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        codigo: dto.codigo,
        nome: dto.nome,
      },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateCentroCustoDto) {
    const cc = await this.prisma.centroCusto.findFirst({ where: { id, tenantId } });
    if (!cc) throw new NotFoundException('Centro de custo não encontrado');

    return this.prisma.centroCusto.update({
      where: { id },
      data: { codigo: dto.codigo, nome: dto.nome },
    });
  }

  async remover(tenantId: string, id: string) {
    const cc = await this.prisma.centroCusto.findFirst({ where: { id, tenantId } });
    if (!cc) throw new NotFoundException('Centro de custo não encontrado');

    await this.prisma.centroCusto.update({
      where: { id },
      data: { status: 'INATIVO' },
    });
    return { message: 'Centro de custo desativado' };
  }

  private async validarEmpresa(tenantId: string, empresaId: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
  }
}
