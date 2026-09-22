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
