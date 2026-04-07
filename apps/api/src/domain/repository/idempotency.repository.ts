import { IdempotencyKeyRecord } from '../types';

/**
 * Idempotency key repository interface.
 *
 * Cross-cutting concern for write-side replay protection.
 */
export interface IIdempotencyRepository {
  getIdempotencyKey(key: string): IdempotencyKeyRecord | null;

  setIdempotencyKey(
    key: string,
    path: string,
    response: Record<string, unknown>,
  ): void;
}
