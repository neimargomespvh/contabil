import { createParamDecorator, ExecutionContext } from '@nestjs/common';
export const CurrentTenant = createParamDecorator(
  (_: unknown, ctx: ExecutionContext): string => ctx.switchToHttp().getRequest().user?.tenantId,
);
