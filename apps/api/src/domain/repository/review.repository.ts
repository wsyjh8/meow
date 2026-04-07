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
  ): { success: boolean; groupCompleted: boolean; alreadyExists: boolean };

  hasReviewGroupCompletedEvent(reviewGroupId: string): boolean;

  getReviewGroups(): ReviewGroup[];
  getReviewAttempts(): ReviewAttempt[];
}
