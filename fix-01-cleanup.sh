#!/usr/bin/env bash
set -e
cd /home/neimar/Projetos/Contabil

echo "🧹 Removendo backup/ (causa conflito de node_modules)..."
rm -rf backup

echo "📁 Criando estrutura..."
mkdir -p src/{config,infra/{prisma,redis,s3,queue},common/{decorators,guards,interceptors,filters,dto},modules}

echo "📦 Movendo pastas para src/modules..."
[ -d "C-auth" ] && { rm -rf src/modules/auth; cp -r C-auth src/modules/auth; rm -rf C-auth; echo "  C-auth → src/modules/auth"; }
[ -d "D-lancamentos" ] && { rm -rf src/modules/lancamentos; cp -r D-lancamentos src/modules/lancamentos; rm -rf D-lancamentos; echo "  D-lancamentos → src/modules/lancamentos"; }
[ -d "B-parsers-xml" ] && { rm -rf src/modules/documentos-fiscais/parsers; mkdir -p src/modules/documentos-fiscais; cp -r B-parsers-xml src/modules/documentos-fiscais/parsers; rm -rf B-parsers-xml; echo "  B-parsers-xml → src/modules/documentos-fiscais/parsers"; }

echo "🔧 Corrigindo interfaces.ts..."
cat > src/modules/documentos-fiscais/parsers/interfaces.ts <<'EOF'
export type TipoDocumento = 'NFE' | 'NFCE' | 'CTE' | 'NFSE';

export interface DocumentoFiscalParseado {
  tipo: TipoDocumento;
  chaveAcesso: string;
  numero: string;
  serie: string;
  modelo: string;
  emitenteCnpj: string;
  emitenteNome: string;
  destinatarioCnpj?: string;
  destinatarioNome?: string;
  dataEmissao: Date;
  valorTotal: number;
  valorIcms?: number;
  valorPis?: number;
  valorCofins?: number;
  valorIss?: number;
  cfopPrincipal?: string;
  ncmPrincipal?: string;
  itens: ItemDocumentoParseado[];
  xmlRaw: string;
}

export interface ItemDocumentoParseado {
  numeroItem: number;
  codigoProduto?: string;
  descricao?: string;
  ncm?: string;
  cfop?: string;
  quantidade?: number;
  valorUnitario?: number;
  valorTotal?: number;
  valorIcms?: number;
  aliquotaIcms?: number;
  valorPis?: number;
  valorCofins?: number;
}

export class XmlMalformadoError extends Error {
  constructor(message = 'XML malformado') { super(message); this.name = 'XmlMalformadoError'; }
}
export class DocumentoDuplicadoError extends Error {
  constructor(chave: string) { super(`Chave ${chave} já importada`); this.name = 'DocumentoDuplicadoError'; }
}
export class SchemaInvalidoError extends Error {
  constructor(message = 'Schema inválido') { super(message); this.name = 'SchemaInvalidoError'; }
}
export class CamposObrigatoriosError extends Error {
  constructor(campos: string[]) {
    super(`Campos obrigatórios faltantes: ${campos.join(', ')}`);
    this.name = 'CamposObrigatoriosError';
  }
}
EOF

echo "🔧 Corrigindo auth.service.ts..."
cat > src/modules/auth/auth.service.ts <<'EOF'
import { Injectable, UnauthorizedException, ConflictException } from '@nestjs/common';
import { JwtService } from '@nestjs/jwt';
import { ConfigService } from '@nestjs/config';
import * as argon2 from 'argon2';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { LoginDto } from './dto/login.dto';
import { RegisterDto } from './dto/register.dto';

@Injectable()
export class AuthService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly jwt: JwtService,
    private readonly config: ConfigService,
  ) {}

  async login(dto: LoginDto) {
    const user: any = await this.prisma.user.findFirst({
      where: { email: dto.email },
      include: {
        tenant: true,
        userRoles: { include: { role: { include: { rolePermissions: { include: { permission: true } } } } } },
      },
    });

    if (!user || user.status !== 'ATIVO') throw new UnauthorizedException('Credenciais inválidas');
    if (!(await argon2.verify(user.senhaHash, dto.senha))) throw new UnauthorizedException('Credenciais inválidas');

    const permissions: string[] = user.userRoles.flatMap((ur: any) =>
      ur.role.rolePermissions.map((rp: any) => rp.permission.codigo),
    );

    const payload = { sub: user.id, email: user.email, tenantId: user.tenantId, permissions };
    const accessToken = await this.jwt.signAsync(payload);
    const refreshToken = await this.jwt.signAsync(payload, {
      secret: this.config.get<string>('jwt.refreshSecret'),
      expiresIn: this.config.get<string>('jwt.refreshExpiresIn'),
    });

    await this.prisma.user.update({ where: { id: user.id }, data: { ultimoAcesso: new Date() } });

    return {
      accessToken, refreshToken,
      user: { id: user.id, nome: user.nome, email: user.email, tenantId: user.tenantId, tenantNome: user.tenant.nome, permissions },
    };
  }

  async register(dto: RegisterDto) {
    if (await this.prisma.tenant.findUnique({ where: { cnpj: dto.cnpjTenant } }))
      throw new ConflictException('CNPJ já cadastrado');

    return this.prisma.$transaction(async (tx: any) => {
      const tenant = await tx.tenant.create({
        data: { nome: dto.nomeTenant, cnpj: dto.cnpjTenant, email: dto.email, status: 'ATIVO' },
      });
      const role = await tx.role.create({
        data: { tenantId: tenant.id, nome: 'admin', descricao: 'Administrador' },
      });
      const user = await tx.user.create({
        data: { tenantId: tenant.id, nome: dto.nome, email: dto.email, senhaHash: await argon2.hash(dto.senha), status: 'ATIVO' },
      });
      await tx.userRole.create({ data: { userId: user.id, roleId: role.id } });
      return { tenantId: tenant.id, userId: user.id };
    });
  }

  async refresh(refreshToken: string) {
    try {
      const p: any = await this.jwt.verifyAsync(refreshToken, {
        secret: this.config.get<string>('jwt.refreshSecret'),
      });
      return {
        accessToken: await this.jwt.signAsync({
          sub: p.sub, email: p.email, tenantId: p.tenantId, permissions: p.permissions,
        }),
      };
    } catch { throw new UnauthorizedException('Refresh token inválido'); }
  }
}
EOF

echo "🔧 Corrigindo lancamentos.service.ts..."
cat > src/modules/lancamentos/lancamentos.service.ts <<'EOF'
import { BadRequestException, Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../../infra/prisma/prisma.service';
import { CreateLancamentoDto } from './dto/create-lancamento.dto';
import { PartidasDobradasValidator } from './validators/partidas-dobradas.validator';

@Injectable()
export class LancamentosService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly validator: PartidasDobradasValidator,
  ) {}

  async criar(tenantId: string, dto: CreateLancamentoDto) {
    this.validator.validar(dto.partidas);
    await this.validarPeriodoAberto(dto.empresaId, dto.competencia);
    const valorTotal = dto.partidas.filter((p) => p.tipo === 'D').reduce((a, p) => a + p.valor, 0);

    return this.prisma.lancamento.create({
      data: {
        tenantId, empresaId: dto.empresaId, loteId: dto.loteId,
        dataLancamento: new Date(dto.dataLancamento), competencia: new Date(dto.competencia),
        historico: dto.historico, documentoRef: dto.documentoRef, valorTotal,
        partidas: { create: dto.partidas.map((p) => ({ tenantId, contaId: p.contaId, centroCustoId: p.centroCustoId, tipo: p.tipo, valor: p.valor })) },
      },
      include: { partidas: true },
    });
  }

  async listar(tenantId: string, empresaId: string, competencia?: string) {
    return this.prisma.lancamento.findMany({
      where: { tenantId, empresaId, status: 'ATIVO', ...(competencia && { competencia: new Date(competencia) }) },
      include: { partidas: true }, orderBy: { dataLancamento: 'desc' }, take: 500,
    });
  }

  async buscarPorId(tenantId: string, id: string) {
    const l = await this.prisma.lancamento.findFirst({ where: { id, tenantId }, include: { partidas: true } });
    if (!l) throw new NotFoundException('Lançamento não encontrado');
    return l;
  }

  async estornar(tenantId: string, id: string, motivo: string) {
    const orig: any = await this.prisma.lancamento.findFirst({
      where: { id, tenantId, status: 'ATIVO' }, include: { partidas: true },
    });
    if (!orig) throw new NotFoundException('Lançamento não encontrado');

    return this.prisma.$transaction(async (tx: any) => {
      await tx.lancamento.update({ where: { id: orig.id }, data: { status: 'ESTORNADO' } });
      return tx.lancamento.create({
        data: {
          tenantId, empresaId: orig.empresaId, dataLancamento: new Date(),
          competencia: orig.competencia, historico: `ESTORNO: ${motivo}`,
          valorTotal: orig.valorTotal, estornoDeId: orig.id,
          partidas: { create: orig.partidas.map((p: any) => ({ tenantId, contaId: p.contaId, centroCustoId: p.centroCustoId, tipo: p.tipo === 'D' ? 'C' : 'D', valor: p.valor })) },
        },
      });
    });
  }

  private async validarPeriodoAberto(empresaId: string, comp: string) {
    const f = await this.prisma.fechamentoPeriodo.findUnique({
      where: { uk_fechamento_empresa_comp: { empresaId, competencia: new Date(comp) } },
    });
    if (f?.status === 'FECHADO') throw new BadRequestException('Período fechado');
  }
}
EOF

echo "🔧 Corrigindo app.module.ts..."
cat > src/app.module.ts <<'EOF'
import { Module } from '@nestjs/common';
import { ConfigModule, ConfigService } from '@nestjs/config';
import { APP_GUARD, APP_INTERCEPTOR } from '@nestjs/core';
import { ThrottlerModule, ThrottlerGuard } from '@nestjs/throttler';

import configuration from './config/configuration';
import { PrismaModule } from './infra/prisma/prisma.module';
import { RedisModule } from './infra/redis/redis.module';
import { S3Module } from './infra/s3/s3.module';
import { QueueModule } from './infra/queue/queue.module';
import { AuthModule } from './modules/auth/auth.module';
import { HealthModule } from './modules/health/health.module';
import { AuditModule } from './modules/audit/audit.module';
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
    AuditModule, AuthModule, HealthModule,
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
EOF

echo "🔧 Corrigindo main.ts..."
cat > src/main.ts <<'EOF'
import { NestFactory, Reflector } from '@nestjs/core';
import { ValidationPipe, ClassSerializerInterceptor, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { DocumentBuilder, SwaggerModule } from '@nestjs/swagger';
import helmet from 'helmet';
import { AppModule } from './app.module';
import { HttpExceptionFilter } from './common/filters/http-exception.filter';
import { PrismaExceptionFilter } from './common/filters/prisma-exception.filter';
import { LoggingInterceptor } from './common/interceptors/logging.interceptor';

async function bootstrap() {
  const logger = new Logger('Bootstrap');
  const app = await NestFactory.create(AppModule, { logger: ['error', 'warn', 'log'] });
  const config = app.get(ConfigService);
  const port = config.get<number>('port') ?? 3000;

  app.use(helmet({ contentSecurityPolicy: false }));
  app.enableCors({ origin: config.get<string[]>('cors.origin') ?? true, credentials: true });
  app.setGlobalPrefix('api/v1');
  app.useGlobalPipes(new ValidationPipe({
    whitelist: true, forbidNonWhitelisted: true, transform: true,
    transformOptions: { enableImplicitConversion: true },
  }));
  app.useGlobalFilters(new PrismaExceptionFilter(), new HttpExceptionFilter());
  app.useGlobalInterceptors(new LoggingInterceptor(), new ClassSerializerInterceptor(app.get(Reflector)));

  const swaggerConfig = new DocumentBuilder()
    .setTitle('Sistema Contábil API').setDescription('API multitenant').setVersion('1.0').addBearerAuth().build();
  SwaggerModule.setup('docs', app, SwaggerModule.createDocument(app, swaggerConfig));

  await app.listen(port, '0.0.0.0');
  logger.log(`🚀 API em http://localhost:${port}/api/v1`);
  logger.log(`📚 Swagger em http://localhost:${port}/docs`);
}
bootstrap().catch((e) => { console.error('❌', e); process.exit(1); });
EOF

echo "🔧 Corrigindo prisma-exception.filter.ts..."
cat > src/common/filters/prisma-exception.filter.ts <<'EOF'
import { ArgumentsHost, Catch, ExceptionFilter, HttpStatus, Logger } from '@nestjs/common';
import {
  PrismaClientKnownRequestError,
  PrismaClientValidationError,
  PrismaClientInitializationError,
} from '@prisma/client/runtime/library';
import { Response } from 'express';

@Catch(PrismaClientKnownRequestError, PrismaClientValidationError, PrismaClientInitializationError)
export class PrismaExceptionFilter implements ExceptionFilter {
  private readonly logger = new Logger(PrismaExceptionFilter.name);

  catch(exception: unknown, host: ArgumentsHost) {
    const res = host.switchToHttp().getResponse<Response>();
    let status = HttpStatus.INTERNAL_SERVER_ERROR;
    let message = 'Erro de banco de dados';

    if (exception instanceof PrismaClientKnownRequestError) {
      switch (exception.code) {
        case 'P2002':
          status = HttpStatus.CONFLICT;
          message = `Registro duplicado: ${(exception.meta?.target as string[])?.join(', ') ?? ''}`;
          break;
        case 'P2003':
          status = HttpStatus.BAD_REQUEST;
          message = 'Violação de chave estrangeira';
          break;
        case 'P2025':
          status = HttpStatus.NOT_FOUND;
          message = 'Registro não encontrado';
          break;
        default:
          message = `Erro Prisma ${exception.code}`;
      }
    } else if (exception instanceof PrismaClientValidationError) {
      status = HttpStatus.BAD_REQUEST; message = 'Dados inválidos';
    } else if (exception instanceof PrismaClientInitializationError) {
      message = 'Erro ao conectar no banco';
    }

    this.logger.error(message, (exception as Error)?.stack);
    res.status(status).json({ statusCode: status, timestamp: new Date().toISOString(), message });
  }
}
EOF

echo "✅ Script 1 concluído"
