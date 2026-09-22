import { Injectable } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { PERMISSOES_DESCRICOES } from '../../common/constants/permissions.constants';

@Injectable()
export class PermissionsService {
  constructor(private readonly prisma: PrismaService) {}

  async listar() {
    const permissoes = await this.prisma.permission.findMany({
      orderBy: { codigo: 'asc' },
    });

    return permissoes.map((p) => ({
      id: p.id,
      codigo: p.codigo,
      descricao: p.descricao ?? PERMISSOES_DESCRICOES[p.codigo] ?? p.codigo,
    }));
  }
}
