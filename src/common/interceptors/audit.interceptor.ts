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
