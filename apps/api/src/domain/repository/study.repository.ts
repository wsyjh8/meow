import { Word, StudyAttempt } from '../types';

/**
 * Study domain repository interface.
 *
 * Covers: word lookup, study attempt submission, study progress read.
 */
export interface IStudyRepository {
  getNextNewWord(): Word | null;

  submitStudyAttempt(
    wordId: string,
    bookId: string,
    studyType: 'new',
    actionResult: 'know' | 'forgot',
    idempotencyKey: string,
  ): { success: boolean; alreadyExists: boolean; attempt: StudyAttempt };

  getStudyAttempts(): StudyAttempt[];
}
