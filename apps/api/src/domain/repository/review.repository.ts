import { ReviewGroup, ReviewAttempt } from '../types';

/**
 * Review domain repository interface.
 *
 * Covers: review group lifecycle, review attempt submission.
 */
export interface IReviewRepository {
  getActiveReviewGroup(): ReviewGroup | null;
  getOrCreateReviewGroup(): ReviewGroup;

  submitReviewAttempt(
    reviewGroupId: string,
    wordId: string,
    actionResult: 'correct' | 'incorrect',
    idempotencyKey: string,
    sessionId?: string,
  ): { success: boolean; groupCompleted: boolean; alreadyExists: boolean };

  submitLocalReviewBatch(
    wordAttempts: { word_id: string; action_result: 'correct' | 'incorrect'; session_id?: string }[],
    idempotencyKey: string,
  ): { success: boolean; alreadyExists: boolean; localGroupId: string };

  hasReviewGroupCompletedEvent(reviewGroupId: string): boolean;

  getReviewGroups(): ReviewGroup[];
  getReviewAttempts(): ReviewAttempt[];

  /**
   * Need #10 — Recent review attempts for a single word, newest first.
   * Returns up to [limit] entries. Same word may appear multiple times per
   * day; the only ordering guarantee is `created_at` DESC.
   */
  getReviewAttemptsForWord(wordId: string, limit: number): ReviewAttempt[];
}
