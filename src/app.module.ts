import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';
import { RegrasContabilizacaoModule } from './modules/regras-contabilizacao/regras-contabilizacao.module';
import configuration from './config/configuration';
import { PrismaModule } from './infra/prisma/prisma.module';
import { RedisModule } from './infra/redis/redis.module';
import { S3Module } from './infra/s3/s3.module';
import { QueueModule } from './infra/queue/queue.module';

import { AuthModule } from './modules/auth/auth.module';
import { UsersModule } from './modules/users/users.module';
import { RolesModule } from './modules/roles/roles.module';
import { PermissionsModule } from './modules/permissions/permissions.module';
import { EmpresasModule } from './modules/empresas/empresas.module';
import { LancamentosModule } from './modules/lancamentos/lancamentos.module';
import { SociosModule } from './modules/socios/socios.module';
import { PlanoContasModule } from './modules/plano-contas/plano-contas.module';
import { CentrosCustoModule } from './modules/centros-custo/centros-custo.module';
import { DocumentosFiscaisModule } from './modules/documentos-fiscais/documentos-fiscais.module';
import { ContasBancariasModule } from './modules/contas-bancarias/contas-bancarias.module';
import { ConciliacaoModule } from './modules/conciliacao/conciliacao.module';
import { ApuracoesModule } from './modules/apuracoes/apuracoes.module';
import { RelatoriosModule } from './modules/relatorios/relatorios.module';
import { AuditModule } from './modules/audit/audit.module';
import { HealthModule } from './modules/health/health.module';

import { JwtAuthGuard } from './common/guards/jwt-auth.guard';
import { PermissionsGuard } from './common/guards/permissions.guard';
import { TenantContextInterceptor } from './common/interceptors/tenant-context.interceptor';
import { AuditInterceptor } from './common/interceptors/audit.interceptor';

@Module({
  imports: [
    ConfigModule.forRoot({
      isGlobal: true, load: [configuration],
      envFilePath: ['.env', '.env.local'], cache: true,
    }),
    ThrottlerModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => [{
        ttl: (config.get<number>('throttle.ttl') ?? 60) * 1000,
        limit: config.get<number>('throttle.limit') ?? 120,
      }],
    }),
    PrismaModule, RedisModule, S3Module, QueueModule,
    AuditModule,
    AuthModule,
    UsersModule,
    RolesModule,
    PermissionsModule,
    EmpresasModule,
    LancamentosModule,
    SociosModule,
    PlanoContasModule,
    CentrosCustoModule,
    DocumentosFiscaisModule,
    ContasBancariasModule,
    ConciliacaoModule,
    ApuracoesModule,
    RelatoriosModule,
    HealthModule,
    RegrasContabilizacaoModule,
  ],
  providers: [
    { provide: APP_GUARD, useClass: ThrottlerGuard },
    { provide: APP_GUARD, useClass: JwtAuthGuard },
    { provide: APP_GUARD, useClass: PermissionsGuard },
    { provide: APP_INTERCEPTOR, useClass: TenantContextInterceptor },
    { provide: APP_INTERCEPTOR, useClass: AuditInterceptor },
  ],
})
export class AppModule {}
