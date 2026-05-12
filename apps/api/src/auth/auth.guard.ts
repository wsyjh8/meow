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
import { devStore } from '../domain/dev-store';

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

  async canActivate(context: ExecutionContext): Promise<boolean> {
    const req = context.switchToHttp().getRequest<Request>();
    const enforce = process.env.AUTH_ENFORCE === 'true';
    const token = extractBearer(req);

    let user: RequestUser | null = null;

    if (token) {
      try {
        const payload = this.authService.verifyToken(token);
        user = { id: payload.sub, type: payload.type };
      } catch (err) {
        if (enforce) throw err;
        // permissive: bad token → fall back to dev user
      }
    }

    if (!user) {
      if (enforce) {
        throw new UnauthorizedException({
          error_code: 'UNAUTHENTICATED',
          message: 'Missing or invalid Authorization header',
        });
      }
      // Permissive fallback (Phase A~D)
      const devUserId = process.env.DEV_FALLBACK_USER_ID || 'dev-user-001';
      user = { id: devUserId, type: 'registered' };
    }

    (req as any).user = user;

    // 需求 23 Phase A4-β.5b: warm this user's dev-store slice from PG so
    // downstream controllers see their durable state after server restart.
    // The very first request from a non-DEV user pays one PG round-trip;
    // subsequent requests hit the in-memory cache. Concurrent first calls
    // for the same user share a single in-flight load (see dev-store
    // `loadingByUser` map).
    await devStore.ensureUserLoaded(user.id);

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
