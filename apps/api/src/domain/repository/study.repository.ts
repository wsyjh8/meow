import { Word, StudyAttempt } from '../types';

/**
 * Study domain repository interface.
 *
 * Covers: word lookup, study attempt submission, study progress read.
 *
 * 需求 23 Phase A4-α: all user-scoped methods take userId as first param.
 */
export interface IStudyRepository {
  getNextNewWord(userId: string): Word | null;

  submitStudyAttempt(
    userId: string,
    wordId: string,
    bookId: string,
    studyType: 'new',
    actionResult: 'know' | 'forgot',
    idempotencyKey: string,
    sessionId?: string,
  ): { success: boolean; alreadyExists: boolean; attempt: StudyAttempt };

  getStudyAttempts(userId: string): StudyAttempt[];
}
