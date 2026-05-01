import { Session } from '../types';

/**
 * Session domain repository interface.
 *
 * Covers: session start/finish/query.
 */
export interface ISessionRepository {
  getActiveSession(): Session | null;

  startSession(
    minutesTarget: number,
    idempotencyKey: string,
    clientSessionId?: string,
  ): { session: Session; alreadyExists: boolean };

  finishSession(
    sessionId: string,
    idempotencyKey: string,
  ): { session: Session; alreadyExists: boolean };

  getSession(sessionId: string): Session | null;
  getSessions(): Session[];
}
