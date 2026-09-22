import { Injectable, Logger } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';

export interface AuditRegistro {
  tenantId: string; userId?: string | null;
  entidade: string; entidadeId?: string | null;
  acao: string; payloadAntes?: any; payloadDepois?: any;
  ip?: string; userAgent?: string;
}

@Injectable()
export class AuditService {
  private readonly logger = new Logger(AuditService.name);
  constructor(private readonly prisma: PrismaService) {}

  async registrar(reg: AuditRegistro) {
    try {
      await this.prisma.auditLog.create({
        data: {
          tenantId: reg.tenantId, userId: reg.userId ?? null,
          entidade: reg.entidade, entidadeId: reg.entidadeId ?? null,
          acao: reg.acao,
          payloadAntes: reg.payloadAntes ?? undefined,
          payloadDepois: reg.payloadDepois ?? undefined,
          ip: reg.ip ?? null, userAgent: reg.userAgent ?? null,
        },
      });
    } catch (err) { this.logger.warn(`Audit falhou: ${(err as Error).message}`); }
  }

  async listarPorEntidade(tenantId: string, entidade: string, entidadeId: string) {
    return this.prisma.auditLog.findMany({
      where: { tenantId, entidade, entidadeId },
      orderBy: { createdAt: 'desc' }, take: 100,
    });
  }
}
