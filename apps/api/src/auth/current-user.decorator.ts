/**
 * 需求 23 Phase A2 — @CurrentUser() param decorator
 *
 * Reads `req.user` populated by AuthGuard. Use only on routes guarded
 * by AuthGuard, otherwise the value will be undefined.
 */

import { createParamDecorator, ExecutionContext } from '@nestjs/common';
import { RequestUser } from './auth.guard';

export const CurrentUser = createParamDecorator(
  (_data: unknown, ctx: ExecutionContext): RequestUser | undefined => {
    const req = ctx.switchToHttp().getRequest();
    return req.user;
  },
);
