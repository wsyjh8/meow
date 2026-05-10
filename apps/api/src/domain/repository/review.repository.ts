import { ReviewGroup, ReviewAttempt } from '../types';

/**
 * Review domain repository interface.
 *
 * Covers: review group lifecycle, review attempt submission.
 *
 * 需求 23 Phase A4-α: all user-scoped methods take userId as first param.
 * Owner-check (audit §6) enforced internally — submitting against a
 * review_group not owned by the caller throws NotFound.
 */
export interface IReviewRepository {
  getActiveReviewGroup(userId: string): ReviewGroup | null;
  getOrCreateReviewGroup(userId: string): ReviewGroup;

  submitReviewAttempt(
    userId: string,
    reviewGroupId: string,
    wordId: string,
    actionResult: 'correct' | 'incorrect',
    idempotencyKey: string,
    sessionId?: string,
  ): { success: boolean; groupCompleted: boolean; alreadyExists: boolean };

  submitLocalReviewBatch(
    userId: string,
    wordAttempts: { word_id: string; action_result: 'correct' | 'incorrect'; session_id?: string }[],
    idempotencyKey: string,
  ): { success: boolean; alreadyExists: boolean; localGroupId: string };

  hasReviewGroupCompletedEvent(userId: string, reviewGroupId: string): boolean;

  getReviewGroups(userId: string): ReviewGroup[];
  getReviewAttempts(userId: string): ReviewAttempt[];

  /**
   * Need #10 — Recent review attempts for a single word, newest first.
   * Returns up to [limit] entries. Same word may appear multiple times per
   * day; the only ordering guarantee is `created_at` DESC.
   */
  getReviewAttemptsForWord(userId: string, wordId: string, limit: number): ReviewAttempt[];
}
