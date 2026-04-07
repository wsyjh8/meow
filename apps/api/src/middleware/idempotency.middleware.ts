import { Request, Response, NextFunction } from 'express';

/**
 * Idempotency middleware placeholder.
 * 
 * This middleware reads the X-Idempotency-Key header for future use.
 * Actual idempotency protection logic is NOT implemented in Phase 0.
 * 
 * Blocked if touched:
 * - Full idempotency key validation
 * - Request deduplication logic
 * - Cache/storage layer for idempotency keys
 */
export function idempotencyMiddleware(
  req: Request,
  res: Response,
  next: NextFunction,
) {
  const idempotencyKey = req.headers['x-idempotency-key'];

  // Placeholder: log for now, actual validation to be implemented in P1
  if (idempotencyKey) {
    // TODO: Implement idempotency key validation and caching
    // For now, just pass through
  }

  next();
}
