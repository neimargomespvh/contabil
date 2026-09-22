import { createParamDecorator, ExecutionContext } from '@nestjs/common';
export interface AuthUser { id: string; email: string; tenantId: string; permissions: string[]; }
export const CurrentUser = createParamDecorator(
  (data: keyof AuthUser | undefined, ctx: ExecutionContext) => {
    const req = ctx.switchToHttp().getRequest();
    const user: AuthUser = req.user;
    return data ? user?.[data] : user;
  },
);
