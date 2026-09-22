#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

mkdir -p src/{config,infra/{prisma,redis,s3,queue},common/{decorators,guards,interceptors,dto},modules/{audit,health}}

# ============ CONFIG ============
cat > src/config/configuration.ts <<'EOF'
export default () => ({
  port: parseInt(process.env.PORT ?? '3000', 10),
  nodeEnv: process.env.NODE_ENV ?? 'development',
  database: { url: process.env.DATABASE_URL },
  jwt: {
    secret: process.env.JWT_SECRET,
    expiresIn: process.env.JWT_EXPIRES_IN ?? '15m',
    refreshSecret: process.env.JWT_REFRESH_SECRET,
    refreshExpiresIn: process.env.JWT_REFRESH_EXPIRES_IN ?? '7d',
  },
  aws: {
    region: process.env.AWS_REGION ?? 'sa-east-1',
    endpoint: process.env.AWS_ENDPOINT,
    s3Bucket: process.env.AWS_S3_BUCKET ?? 'contabil-docs',
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
    forcePathStyle: process.env.AWS_FORCE_PATH_STYLE === 'true',
  },
  redis: {
    url: process.env.REDIS_URL ?? 'redis://localhost:6379',
    prefix: process.env.REDIS_PREFIX ?? 'contabil:',
  },
  throttle: {
    ttl: parseInt(process.env.THROTTLE_TTL ?? '60', 10),
    limit: parseInt(process.env.THROTTLE_LIMIT ?? '120', 10),
  },
  cors: { origin: (process.env.CORS_ORIGIN ?? '*').split(',') },
});
EOF

# ============ COMMON - DECORATORS ============
cat > src/common/decorators/public.decorator.ts <<'EOF'
import { SetMetadata } from '@nestjs/common';
export const IS_PUBLIC_KEY = 'isPublic';
export const Public = () => SetMetadata(IS_PUBLIC_KEY, true);
EOF

cat > src/common/decorators/current-user.decorator.ts <<'EOF'
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
export interface AuthUser { id: string; email: string; tenantId: string; permissions: string[]; }
export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest();
    const user: AuthUser = req.user;
    return data ? user?.[data] : user;
  },
);
EOF

cat > src/common/decorators/current-tenant.decorator.ts <<'EOF'
import { createParamDecorator, ExecutionContext } from '@nestjs/common';
export const CurrentTenant = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string => ctx.switchToHttp().getRequest().user?.tenantId,
);
EOF

cat > src/common/decorators/permissions.decorator.ts <<'EOF'
import { SetMetadata } from '@nestjs/common';
export const PERMISSIONS_KEY = 'permissions';
export const RequirePermissions = (...perms: string[]) => SetMetadata(PERMISSIONS_KEY, perms);
EOF

# ============ COMMON - GUARDS ============
cat > src/common/guards/jwt-auth.guard.ts <<'EOF'
import { ExecutionContext, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { AuthGuard } from '@nestjs/passport';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

@Injectable()
export class JwtAuthGuard extends AuthGuard('jwt') {
  constructor(private readonly reflector: Reflector) { super(); }
  canActivate(context: ExecutionContext) {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (isPublic) return true;
    return super.canActivate(context);
  }
}
EOF

cat > src/common/guards/permissions.guard.ts <<'EOF'
import { CanActivate, ExecutionContext, ForbiddenException, Injectable } from '@nestjs/common';
import { Reflector } from '@nestjs/core';
import { PERMISSIONS_KEY } from '../decorators/permissions.decorator';
import { IS_PUBLIC_KEY } from '../decorators/public.decorator';

@Injectable()
export class PermissionsGuard implements CanActivate {
  constructor(private readonly reflector: Reflector) {}
  canActivate(context: ExecutionContext): boolean {
    const isPublic = this.reflector.getAllAndOverride<boolean>(IS_PUBLIC_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (isPublic) return true;

    const required = this.reflector.getAllAndOverride<string[]>(PERMISSIONS_KEY, [
      context.getHandler(), context.getClass(),
    ]);
    if (!required?.length) return true;

    const { user } = context.switchToHttp().getRequest();
    const userPerms: string[] = user?.permissions ?? [];
    const ok = required.every((need) => userPerms.some((have) =>
      have === need || (have.endsWith('.*') && need.startsWith(have.slice(0, -1))),
    ));
    if (!ok) throw new ForbiddenException(`Permissão insuficiente: ${required.join(', ')}`);
    return true;
  }
}
EOF

# ============ COMMON - INTERCEPTORS ============
cat > src/common/interceptors/tenant-context.interceptor.ts <<'EOF'
import { CallHandler, ExecutionContext, Injectable, NestInterceptor } from '@nestjs/common';
import { Observable, from } from 'rxjs';
import { switchMap } from 'rxjs/operators';
import { PrismaService } from '../../infra/prisma/prisma.service';

@Injectable()
export class TenantContextInterceptor implements NestInterceptor {
  constructor(private readonly prisma: PrismaService) {}
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const tenantId: string | undefined = req.user?.tenantId;
    if (!tenantId) return next.handle();
    return from(this.prisma.setTenant(tenantId)).pipe(switchMap(() => next.handle()));
  }
}
EOF

cat > src/common/interceptors/logging.interceptor.ts <<'EOF'
import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';

@Injectable()
export class LoggingInterceptor implements NestInterceptor {
  private readonly logger = new Logger('HTTP');
  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    const { method, url, user } = req;
    const start = Date.now();
    return next.handle().pipe(
      tap({
        next: () => this.logger.log(`${method} ${url} - ${Date.now() - start}ms - tenant=${user?.tenantId ?? '-'}`),
        error: (err) => this.logger.warn(`${method} ${url} - ${Date.now() - start}ms - ERRO: ${err.message}`),
      }),
    );
  }
}
EOF

cat > src/common/interceptors/audit.interceptor.ts <<'EOF'
import { CallHandler, ExecutionContext, Injectable, Logger, NestInterceptor } from '@nestjs/common';
import { Observable, tap } from 'rxjs';
import { AuditService } from '../../modules/audit/audit.service';

const AUDIT_METHODS = new Set(['POST', 'PUT', 'PATCH', 'DELETE']);
const SKIP_PATHS = ['/auth/login', '/auth/refresh', '/health'];

@Injectable()
export class AuditInterceptor implements NestInterceptor {
  private readonly logger = new Logger(AuditInterceptor.name);
  constructor(private readonly audit: AuditService) {}

  intercept(context: ExecutionContext, next: CallHandler): Observable<any> {
    const req = context.switchToHttp().getRequest();
    if (!AUDIT_METHODS.has(req.method)) return next.handle();
    if (SKIP_PATHS.some((p) => (req.url as string).includes(p))) return next.handle();
    if (!req.user?.tenantId) return next.handle();

    return next.handle().pipe(
      tap({
        next: (response) => void this.safe(req, response, true),
        error: () => void this.safe(req, null, false),
      }),
    );
  }

  private async safe(req: any, response: any, sucesso: boolean) {
    try {
      await this.audit.registrar({
        tenantId: req.user.tenantId, userId: req.user.id,
        entidade: (req.baseUrl ?? '').replace('/api/v1/', '') || 'desconhecido',
        entidadeId: response?.id ?? req.params?.id,
        acao: `${req.method} ${sucesso ? 'OK' : 'FALHA'}`,
        payloadDepois: this.sanitizar(req.body),
        ip: req.ip, userAgent: req.headers['user-agent'],
      });
    } catch (err) {
      this.logger.warn(`Audit falhou: ${(err as Error).message}`);
    }
  }

  private sanitizar(body: any) {
    if (!body || typeof body !== 'object') return body ?? null;
    const c = { ...body };
    for (const k of ['senha', 'password', 'senhaHash', 'token', 'refreshToken']) {
      if (k in c) c[k] = '***';
    }
    return c;
  }
}
EOF

# ============ COMMON - FILTERS ============
cat > src/common/filters/http-exception.filter.ts <<'EOF'
import { ArgumentsHost, Catch, ExceptionFilter, HttpException, HttpStatus, Logger } from '@nestjs/common';
import { Request, Response } from 'express';

@Catch()
export class HttpExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(HttpExceptionFilter.name);
  catch(exception: unknown, host: ArgumentsHost) {
    const ctx = host.switchToHttp();
    const res = ctx.getResponse<Response>();
    const req = ctx.getRequest<Request>();
    const isHttp = exception instanceof HttpException;
    const status = isHttp ? exception.getStatus() : HttpStatus.INTERNAL_SERVER_ERROR;
    const body = isHttp ? (exception.getResponse() as any) : { message: 'Erro interno' };
    const message = typeof body === 'string' ? body : body.message ?? 'Erro';
    if (status >= 500) this.logger.error(`${req.method} ${req.url} - ${status}`, (exception as Error)?.stack);
    res.status(status).json({ statusCode: status, timestamp: new Date().toISOString(), path: req.url, method: req.method, message });
  }
}
EOF

# ============ COMMON - DTO ============
cat > src/common/dto/pagination.dto.ts <<'EOF'
import { Type } from 'class-transformer';
import { IsInt, IsOptional, IsString, Max, Min } from 'class-validator';

export class PaginationDto {
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) page: number = 1;
  @IsOptional() @Type(() => Number) @IsInt() @Min(1) @Max(100) limit: number = 20;
  @IsOptional() @IsString() orderBy?: string = 'createdAt';
  @IsOptional() @IsString() order: 'asc' | 'desc' = 'desc';
  get skip(): number { return (this.page - 1) * this.limit; }
}

export interface PaginatedResult<T> {
  data: T[];
  meta: { total: number; page: number; limit: number; totalPages: number };
}

export function paginar<T>(data: T[], total: number, page: number, limit: number): PaginatedResult<T> {
  return { data, meta: { total, page, limit, totalPages: Math.ceil(total / limit) } };
}
EOF

# ============ INFRA - PRISMA ============
cat > src/infra/prisma/prisma.service.ts <<'EOF'
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
EOF

cat > src/infra/prisma/prisma.module.ts <<'EOF'
import { Global, Module } from '@nestjs/common';
import { PrismaService } from './prisma.service';

@Global()
@Module({ providers: [PrismaService], exports: [PrismaService] })
export class PrismaModule {}
EOF

# ============ INFRA - REDIS ============
cat > src/infra/redis/redis.service.ts <<'EOF'
import { Injectable, Logger, OnModuleDestroy } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import Redis from 'ioredis';

@Injectable()
export class RedisService implements OnModuleDestroy {
  private readonly logger = new Logger(RedisService.name);
  private readonly client: Redis;
  private readonly prefix: string;

  constructor(config: ConfigService) {
    this.prefix = config.get<string>('redis.prefix') ?? 'contabil:';
    this.client = new Redis(config.get<string>('redis.url')!, { maxRetriesPerRequest: 3 });
    this.client.on('connect', () => this.logger.log('✅ Redis conectado'));
    this.client.on('error', (e) => this.logger.error('Redis erro', e.message));
  }
  async onModuleDestroy() { await this.client.quit(); }
  private k(key: string) { return `${this.prefix}${key}`; }
  async get<T = any>(key: string): Promise<T | null> {
    const v = await this.client.get(this.k(key));
    return v ? JSON.parse(v) as T : null;
  }
  async set(key: string, value: any, ttl?: number): Promise<void> {
    const p = JSON.stringify(value);
    if (ttl) await this.client.set(this.k(key), p, 'EX', ttl);
    else await this.client.set(this.k(key), p);
  }
  async del(key: string): Promise<void> { await this.client.del(this.k(key)); }
  getClient(): Redis { return this.client; }
}
EOF

cat > src/infra/redis/redis.module.ts <<'EOF'
import { Global, Module } from '@nestjs/common';
import { RedisService } from './redis.service';

@Global()
@Module({ providers: [RedisService], exports: [RedisService] })
export class RedisModule {}
EOF

# ============ INFRA - S3 ============
cat > src/infra/s3/s3.service.ts <<'EOF'
import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { S3Client, PutObjectCommand, GetObjectCommand, DeleteObjectCommand, HeadObjectCommand } from '@aws-sdk/client-s3';
import { getSignedUrl } from '@aws-sdk/s3-request-presigner';
import { createHash } from 'crypto';
import { Readable } from 'stream';

@Injectable()
export class S3Service {
  private readonly logger = new Logger(S3Service.name);
  private readonly client: S3Client;
  private readonly bucket: string;

  constructor(config: ConfigService) {
    this.bucket = config.get<string>('aws.s3Bucket')!;
    this.client = new S3Client({
      region: config.get<string>('aws.region')!,
      endpoint: config.get<string>('aws.endpoint'),
      forcePathStyle: config.get<boolean>('aws.forcePathStyle'),
      credentials: {
        accessKeyId: config.get<string>('aws.accessKeyId') ?? '',
        secretAccessKey: config.get<string>('aws.secretAccessKey') ?? '',
      },
    });
  }

  async upload(key: string, body: Buffer | Readable | string, contentType = 'application/octet-stream') {
    const buffer = Buffer.isBuffer(body) ? body
      : typeof body === 'string' ? Buffer.from(body)
      : await this.streamToBuffer(body);
    const hash = createHash('sha256').update(buffer).digest('hex');
    await this.client.send(new PutObjectCommand({
      Bucket: this.bucket, Key: key, Body: buffer, ContentType: contentType, Metadata: { hash },
    }));
    return { key, hash };
  }

  async download(key: string): Promise<Buffer> {
    const res = await this.client.send(new GetObjectCommand({ Bucket: this.bucket, Key: key }));
    return this.streamToBuffer(res.Body as Readable);
  }

  async exists(key: string): Promise<boolean> {
    try { await this.client.send(new HeadObjectCommand({ Bucket: this.bucket, Key: key })); return true; }
    catch { return false; }
  }

  async delete(key: string): Promise<void> {
    await this.client.send(new DeleteObjectCommand({ Bucket: this.bucket, Key: key }));
  }

  async presignedUrl(key: string, expiresIn = 3600): Promise<string> {
    return getSignedUrl(this.client, new GetObjectCommand({ Bucket: this.bucket, Key: key }), { expiresIn });
  }

  private async streamToBuffer(stream: Readable): Promise<Buffer> {
    const chunks: Buffer[] = [];
    for await (const c of stream) chunks.push(Buffer.isBuffer(c) ? c : Buffer.from(c));
    return Buffer.concat(chunks);
  }
}
EOF

cat > src/infra/s3/s3.module.ts <<'EOF'
import { Global, Module } from '@nestjs/common';
import { S3Service } from './s3.service';

@Global()
@Module({ providers: [S3Service], exports: [S3Service] })
export class S3Module {}
EOF

# ============ INFRA - QUEUE ============
cat > src/infra/queue/queue.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { BullModule } from '@nestjs/bullmq';
import { ConfigService } from '@nestjs/config';

@Module({
  imports: [
    BullModule.forRootAsync({
      inject: [ConfigService],
      useFactory: (config: ConfigService) => {
        const url = new URL(config.get<string>('redis.url')!);
        return {
          connection: {
            host: url.hostname,
            port: parseInt(url.port || '6379', 10),
            password: url.password || undefined,
          },
        };
      },
    }),
    BullModule.registerQueue(
      { name: 'xml-import' }, { name: 'ofx-import' },
      { name: 'apuracao' }, { name: 'relatorio' },
    ),
  ],
  exports: [BullModule],
})
export class QueueModule {}
EOF

# ============ MODULES - AUDIT ============
cat > src/modules/audit/audit.service.ts <<'EOF'
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
EOF

cat > src/modules/audit/audit.controller.ts <<'EOF'
import { Controller, Get, Param } from '@nestjs/common';
import { ApiBearerAuth, ApiTags } from '@nestjs/swagger';
import { AuditService } from './audit.service';
import { CurrentTenant } from '../../common/decorators/current-tenant.decorator';
import { RequirePermissions } from '../../common/decorators/permissions.decorator';

@ApiTags('audit')
@ApiBearerAuth()
@Controller('audit')
export class AuditController {
  constructor(private readonly service: AuditService) {}

  @Get('entidade/:entidade/:id')
  @RequirePermissions('auditoria.ver')
  listar(@CurrentTenant() t: string, @Param('entidade') e: string, @Param('id') id: string) {
    return this.service.listarPorEntidade(t, e, id);
  }
}
EOF

cat > src/modules/audit/audit.module.ts <<'EOF'
import { Global, Module } from '@nestjs/common';
import { AuditController } from './audit.controller';
import { AuditService } from './audit.service';

@Global()
@Module({ controllers: [AuditController], providers: [AuditService], exports: [AuditService] })
export class AuditModule {}
EOF

# ============ MODULES - HEALTH ============
cat > src/modules/health/health.controller.ts <<'EOF'
import { Controller, Get } from '@nestjs/common';
import { ApiTags } from '@nestjs/swagger';
import { Public } from '../../common/decorators/public.decorator';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { RedisService } from '../../infra/redis/redis.service';

@ApiTags('health')
@Controller('health')
export class HealthController {
  constructor(private readonly prisma: PrismaService, private readonly redis: RedisService) {}

  @Public() @Get()
  async check() {
    const checks: Record<string, 'ok' | 'fail'> = {};
    try { await this.prisma.$queryRaw`SELECT 1`; checks.database = 'ok'; }
    catch { checks.database = 'fail'; }
    try { await this.redis.getClient().ping(); checks.redis = 'ok'; }
    catch { checks.redis = 'fail'; }
    const healthy = Object.values(checks).every((v) => v === 'ok');
    return { status: healthy ? 'healthy' : 'degraded', timestamp: new Date().toISOString(), uptime: process.uptime(), checks };
  }

  @Public() @Get('ready') ready() { return { status: 'ready' }; }
  @Public() @Get('live') live() { return { status: 'alive' }; }
}
EOF

cat > src/modules/health/health.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { HealthController } from './health.controller';

@Module({ controllers: [HealthController] })
export class HealthModule {}
EOF

echo "✅ Script 2 concluído - todos os arquivos F1 criados"
