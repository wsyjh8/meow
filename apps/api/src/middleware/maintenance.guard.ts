/**
 * Degraded-state write guard (Option A.1 H1).
 *
 * Rejects POST/PUT/PATCH/DELETE when any of these system states are active:
 *   - MAINTENANCE_MODE=true   → system in maintenance window
 *   - READ_ONLY_MODE=true     → writes forbidden, reads allowed
 *   - TEMPORARILY_UNAVAILABLE=true → write path unavailable, retryable
 *
 * Returns structured degraded-state response (not generic error, not fake success).
 * GET/HEAD/OPTIONS always pass through.
 */

import { Injectable, NestMiddleware } from '@nestjs/common';
import { Request, Response, NextFunction } from 'express';

/** Degraded-state detection helpers — importable by health/controllers. */
export function isMaintenanceMode(): boolean {
  return process.env.MAINTENANCE_MODE === 'true';
}
export function isReadOnlyMode(): boolean {
  return process.env.READ_ONLY_MODE === 'true';
}
export function isTemporarilyUnavailable(): boolean {
  return process.env.TEMPORARILY_UNAVAILABLE === 'true';
}
export function isWriteBlocked(): boolean {
  return isMaintenanceMode() || isReadOnlyMode() || isTemporarilyUnavailable();
}

/** Build the structured degraded-state error response. */
function buildDegradedResponse() {
  const maintenance = isMaintenanceMode();
  const readOnly = isReadOnlyMode();
  const tempUnavail = isTemporarilyUnavailable();

  let code: string;
  let message: string;

  if (maintenance) {
    code = 'MAINTENANCE_MODE_ACTIVE';
    message = 'Writes are temporarily unavailable. The system is in maintenance mode.';
  } else if (readOnly) {
    code = 'READ_ONLY_MODE_ACTIVE';
    message = 'Writes are currently forbidden. The system is in read-only mode.';
  } else {
    code = 'TEMPORARILY_UNAVAILABLE';
    message = 'This write path is temporarily unavailable. Please retry later.';
  }

  return {
    ok: false,
    error: {
      code,
      message,
      retryable: true,
      details: {
        maintenance,
        read_only: readOnly,
        temporarily_unavailable: tempUnavail,
      },
    },
  };
}

@Injectable()
export class MaintenanceGuardMiddleware implements NestMiddleware {
  use(req: Request, res: Response, next: NextFunction) {
    // Read operations always pass through
    if (req.method === 'GET' || req.method === 'HEAD' || req.method === 'OPTIONS') {
      return next();
    }

    // Block writes when any degraded state is active
    if (isWriteBlocked()) {
      return res.status(503).json(buildDegradedResponse());
    }

    next();
  }
}
