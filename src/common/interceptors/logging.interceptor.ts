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
