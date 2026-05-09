/**
 * 需求 23 Phase A2/A3 — AuthGuard
 *
 * Behavior depends on env `AUTH_ENFORCE`:
 *   - 'true':  required Bearer token; rejects 401 if missing/invalid.
 *   - other:   "permissive mode" for Phase A~D incremental rollout —
 *              parses token if present, else falls back to DEV_FALLBACK_USER_ID
 *              (default 'dev-user-001'). Lets old clients keep working while
 *              new clients adopt token flow.
 *
 * Phase E1 will flip AUTH_ENFORCE=true in staging, then production.
 *
 * References:
 *   docs/design/plan-023-用户系统与用户数据隔离-v2.md §4.2
 */

import {
  CanActivate,
  ExecutionContext,
  Injectable,
  UnauthorizedException,
} from '@nestjs/common';
import type { Request } from 'express';
import { AuthService } from './auth.service';
import { AccountType } from './auth.types';

export interface RequestUser {
  id: string;
  type: AccountType;
}

function extractBearer(req: Request): string | null {
  const h = req.headers['authorization'];
  if (!h || typeof h !== 'string') return null;
  const parts = h.split(' ');
  if (parts.length !== 2 || parts[0].toLowerCase() !== 'bearer') return null;
  return parts[1].trim() || null;
}

@Injectable()
export class AuthGuard implements CanActivate {
  constructor(private readonly authService: AuthService) {}

  canActivate(context: ExecutionContext): boolean {
    const req = context.switchToHttp().getRequest<Request>();
    const enforce = process.env.AUTH_ENFORCE === 'true';
    const token = extractBearer(req);

    if (token) {
      try {
        const payload = this.authService.verifyToken(token);
        (req as any).user = { id: payload.sub, type: payload.type } as RequestUser;
        return true;
      } catch (err) {
        if (enforce) throw err;
        // permissive: bad token → fall back to dev user
      }
    }

    if (enforce) {
      throw new UnauthorizedException({
        error_code: 'UNAUTHENTICATED',
        message: 'Missing or invalid Authorization header',
      });
    }

    // Permissive fallback (Phase A~D)
    const devUserId = process.env.DEV_FALLBACK_USER_ID || 'dev-user-001';
    (req as any).user = { id: devUserId, type: 'registered' } as RequestUser;
    return true;
  }
}

/**
 * Production-only assertion: AUTH_ENFORCE must be 'true' when NODE_ENV='production'.
 * Wire from main.ts on bootstrap.
 */
export function assertProductionAuthEnforce(): void {
  if (process.env.NODE_ENV === 'production' && process.env.AUTH_ENFORCE !== 'true') {
    throw new Error(
      '[auth] Refusing to start: NODE_ENV=production but AUTH_ENFORCE != "true". ' +
        'See plan-023 D13.',
    );
  }
}
