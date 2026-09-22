import { Injectable, Logger, OnModuleDestroy, OnModuleInit } from '@nestjs/common';
import { PrismaClient } from '@prisma/client';

@Injectable()
export class PrismaService extends PrismaClient implements OnModuleInit, OnModuleDestroy {
  private readonly logger = new Logger(PrismaService.name);
  async onModuleInit() { await this.$connect(); this.logger.log('✅ Prisma conectado'); }
  async onModuleDestroy() { await this.$disconnect(); }
  async setTenant(tenantId: string): Promise<void> {
    await this.$executeRawUnsafe(`SELECT set_config('app.tenant_id', $1, true)`, tenantId);
  }
  async clearTenant(): Promise<void> {
    await this.$executeRawUnsafe(`SELECT set_config('app.tenant_id', '', true)`);
  }
}
