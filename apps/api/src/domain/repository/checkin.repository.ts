import { CheckInRecord, StreakRecord, LearningDayRecord } from '../types';

/**
 * Check-in / streak / learning-day repository interface.
 *
 * Covers: daily check-in, streak tracking, learning day computation.
 */
export interface ICheckInRepository {
  checkIn(
    idempotencyKey: string,
  ): { checkIn: CheckInRecord; streak: StreakRecord; alreadyExists: boolean };

  getCheckInForDate(localDate: string): CheckInRecord | null;
  getOrCreateStreak(): StreakRecord;
  updateLearningDay(localDate: string): LearningDayRecord;

  getCheckIns(): CheckInRecord[];
  getStreak(): StreakRecord | null;
}
