import { IdempotencyKeyRecord } from '../types';

/**
 * Idempotency key repository interface.
 *
 * Cross-cutting concern for write-side replay protection.
 *
 * 需求 23 Phase A4-α: keys are scoped per-user (PK changed in
 * migration 009 from `key` to `(user_id, key)`). Both methods take
 * userId as first param.
 */
export interface IIdempotencyRepository {
  getIdempotencyKey(userId: string, key: string): IdempotencyKeyRecord | null;

  setIdempotencyKey(
    userId: string,
    key: string,
    path: string,
    response: Record<string, unknown>,
  ): void;
}
