import {
  BadRequestException,
  ConflictException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateEmpresaDto } from './dto/create-empresa.dto';
import { UpdateEmpresaDto } from './dto/update-empresa.dto';
import { FilterEmpresaDto } from './dto/filter-empresa.dto';
import { validarCnpj, limparCnpj } from '../../common/utils/cnpj.util';
import { validarCpf, limparCpf } from '../../common/utils/cpf.util';
import { paginar } from '../../common/dto/pagination.dto';

@Injectable()
export class EmpresasService {
  constructor(private readonly prisma: PrismaService) {}

  async listar(tenantId: string, filtros: FilterEmpresaDto) {
    const where: any = { tenantId, deletedAt: null };

    if (filtros.busca) {
      const busca = filtros.busca;
      where.OR = [
        { razaoSocial: { contains: busca, mode: 'insensitive' } },
        { nomeFantasia: { contains: busca, mode: 'insensitive' } },
        { cnpj: { contains: limparCnpj(busca) } },
      ];
    }

    if (filtros.regimeTributario) where.regimeTributario = filtros.regimeTributario;
    if (filtros.status) where.status = filtros.status;

    const [total, empresas] = await Promise.all([
      this.prisma.empresa.count({ where }),
      this.prisma.empresa.findMany({
        where,
        skip: filtros.skip,
        take: filtros.limit,
        orderBy: { [filtros.orderBy ?? 'createdAt']: filtros.order },
        include: {
          _count: { select: { socios: true, lancamentos: true } },
        },
      }),
    ]);

    return paginar(empresas, total, filtros.page, filtros.limit);
  }

  async buscarPorId(tenantId: string, id: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id, tenantId, deletedAt: null },
      include: {
        socios: { where: { status: 'ativo' } },
      },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');
    return empresa;
  }

  async criar(tenantId: string, dto: CreateEmpresaDto) {
    const cnpjLimpo = limparCnpj(dto.cnpj);

    if (!validarCnpj(cnpjLimpo)) {
      throw new BadRequestException('CNPJ inválido');
    }

    const existente = await this.prisma.empresa.findFirst({
      where: { tenantId, cnpj: cnpjLimpo, deletedAt: null },
    });
    if (existente) throw new ConflictException('CNPJ já cadastrado neste escritório');

    if (dto.responsavelCpf && !validarCpf(dto.responsavelCpf)) {
      throw new BadRequestException('CPF do responsável inválido');
    }

    if (dto.anexoSimples && dto.regimeTributario !== 'SIMPLES') {
      throw new BadRequestException('Anexo do Simples só é válido para regime SIMPLES');
    }

    return this.prisma.empresa.create({
      data: {
        tenantId,
        razaoSocial: dto.razaoSocial,
        nomeFantasia: dto.nomeFantasia,
        cnpj: cnpjLimpo,
        inscricaoEstadual: dto.inscricaoEstadual,
        inscricaoMunicipal: dto.inscricaoMunicipal,
        regimeTributario: dto.regimeTributario,
        anexoSimples: dto.anexoSimples,
        cnaePrincipal: dto.cnaePrincipal,
        cnaesSecundarios: dto.cnaesSecundarios ?? undefined,
        dataAbertura: dto.dataAbertura ? new Date(dto.dataAbertura) : undefined,
        dataRegimeAtual: dto.dataRegimeAtual ? new Date(dto.dataRegimeAtual) : undefined,
        endereco: dto.endereco ? JSON.parse(JSON.stringify(dto.endereco)) : undefined,
        email: dto.email,
        telefone: dto.telefone,
        responsavelNome: dto.responsavelNome,
        responsavelCpf: dto.responsavelCpf ? limparCpf(dto.responsavelCpf) : undefined,
        observacoes: dto.observacoes,
      },
    });
  }

  async atualizar(tenantId: string, id: string, dto: UpdateEmpresaDto) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    if (dto.cnpj) {
      const cnpjLimpo = limparCnpj(dto.cnpj);
      if (!validarCnpj(cnpjLimpo)) throw new BadRequestException('CNPJ inválido');

      if (cnpjLimpo !== empresa.cnpj) {
        const existente = await this.prisma.empresa.findFirst({
          where: { tenantId, cnpj: cnpjLimpo, NOT: { id } },
        });
        if (existente) throw new ConflictException('CNPJ já cadastrado');
      }
    }

    if (dto.responsavelCpf && !validarCpf(dto.responsavelCpf)) {
      throw new BadRequestException('CPF do responsável inválido');
    }

    return this.prisma.empresa.update({
      where: { id },
      data: {
        razaoSocial: dto.razaoSocial,
        nomeFantasia: dto.nomeFantasia,
        cnpj: dto.cnpj ? limparCnpj(dto.cnpj) : undefined,
        inscricaoEstadual: dto.inscricaoEstadual,
        inscricaoMunicipal: dto.inscricaoMunicipal,
        regimeTributario: dto.regimeTributario,
        anexoSimples: dto.anexoSimples,
        cnaePrincipal: dto.cnaePrincipal,
        cnaesSecundarios: dto.cnaesSecundarios ?? undefined,
        dataAbertura: dto.dataAbertura ? new Date(dto.dataAbertura) : undefined,
        dataRegimeAtual: dto.dataRegimeAtual ? new Date(dto.dataRegimeAtual) : undefined,
        endereco: dto.endereco ? JSON.parse(JSON.stringify(dto.endereco)) : undefined,
        email: dto.email,
        telefone: dto.telefone,
        responsavelNome: dto.responsavelNome,
        responsavelCpf: dto.responsavelCpf ? limparCpf(dto.responsavelCpf) : undefined,
        observacoes: dto.observacoes,
      },
    });
  }

  async remover(tenantId: string, id: string) {
    const empresa = await this.prisma.empresa.findFirst({
      where: { id, tenantId, deletedAt: null },
    });
    if (!empresa) throw new NotFoundException('Empresa não encontrada');

    // Soft delete — mantém histórico contábil
    await this.prisma.empresa.update({
      where: { id },
      data: { deletedAt: new Date(), status: 'BAIXADA' },
    });
    return { message: 'Empresa removida' };
  }
}
