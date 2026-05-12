import { Session } from '../types';

/**
 * Session domain repository interface.
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 * Owner-check (audit §6) enforced internally — getSession / finishSession
 * for a session not owned by the caller returns null / throws NotFound.
 */
export interface ISessionRepository {
  getActiveSession(userId: string): Session | null;

  startSession(
    userId: string,
    minutesTarget: number,
    idempotencyKey: string,
    clientSessionId?: string,
  ): { session: Session; alreadyExists: boolean };

  finishSession(
    userId: string,
    sessionId: string,
    idempotencyKey: string,
  ): { session: Session; alreadyExists: boolean };

  getSession(userId: string, sessionId: string): Session | null;
  getSessions(userId: string): Session[];
}
