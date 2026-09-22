import {
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateContaBancariaDto } from './dto/create-conta-bancaria.dto';
import { UpdateContaBancariaDto } from './dto/update-conta-bancaria.dto';

@Injectable()
export class ContasBancariasService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string, empresaId?: string) {
    const where: any = { tenantId, status: 'ATIVO' };
    if (empresaId) where.empresaId = empresaId;

    return this.prisma.contaBancaria.findMany({
      where,
      include: {
        banco: { select: { codigo: true, nome: true } },
        contaContabil: { select: { id: true, codigo: true, nome: true } },
        empresa: { select: { id: true, razaoSocial: true } },
      },
      orderBy: { createdAt: 'desc' },
    });
  }

  async buscarPorId(tenantId: string, id: string) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id, tenantId },
      include: {
        banco: true,
        contaContabil: true,
        empresa: { select: { id: true, razaoSocial: true } },
      },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');
    return conta;
  }

  async criar(tenantId: string, dto: CreateContaBancariaDto) {
    // Validar empresa
    const empresa = await this.prisma.empresa.findFirst({
      where: { id: dto.empresaId, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    // Validar banco
    const banco = await this.prisma.banco.findUnique({
      where: { codigo: dto.bancoCodigo },
    });
    if (!banco) throw new NotFoundException(`Banco ${dto.bancoCodigo} não cadastrado`);

    // Verificar duplicidade (mesma agência + conta)
    if (dto.agencia && dto.numeroConta) {
      const existente = await this.prisma.contaBancaria.findFirst({
        where: {
          tenantId,
          empresaId: dto.empresaId,
          bancoId: banco.id,
          agencia: dto.agencia,
          numeroConta: dto.numeroConta,
        },
      });
      if (existente) {
        throw new ConflictException('Conta bancária já cadastrada');
      }
    }

    return this.prisma.contaBancaria.create({
      data: {
        tenantId,
        empresaId: dto.empresaId,
        bancoId: banco.id,
        agencia: dto.agencia,
        numeroConta: dto.numeroConta,
        digito: dto.digito,
        tipo: dto.tipo ?? 'CORRENTE',
        contaContabilId: dto.contaContabilId,
        saldoInicial: dto.saldoInicial ?? 0,
      },
      include: { banco: true },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateContaBancariaDto) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');

    let bancoId = conta.bancoId;
    if (dto.bancoCodigo) {
      const banco = await this.prisma.banco.findUnique({
        where: { codigo: dto.bancoCodigo },
      });
      if (!banco) throw new NotFoundException(`Banco ${dto.bancoCodigo} não cadastrado`);
      bancoId = banco.id;
    }

    return this.prisma.contaBancaria.update({
      where: { id },
      data: {
        bancoId,
        agencia: dto.agencia,
        numeroConta: dto.numeroConta,
        digito: dto.digito,
        tipo: dto.tipo,
        contaContabilId: dto.contaContabilId,
        saldoInicial: dto.saldoInicial,
      },
      include: { banco: true },
    });
  }

  async remover(tenantId: string, id: string) {
    const conta = await this.prisma.contaBancaria.findFirst({
      where: { id, tenantId },
    });
    if (!conta) throw new NotFoundException('Conta bancária não encontrada');

    const extratos = await this.prisma.extratoBancario.count({
      where: { contaBancariaId: id },
    });
    if (extratos > 0) {
      // Soft delete se tiver extrato
      await this.prisma.contaBancaria.update({
        where: { id },
        data: { status: 'INATIVO' },
      });
      return { message: 'Conta desativada (possui extratos vinculados)' };
    }

    await this.prisma.contaBancaria.delete({ where: { id } });
    return { message: 'Conta removida' };
  }
}
