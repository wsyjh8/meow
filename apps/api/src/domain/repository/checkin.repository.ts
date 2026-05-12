import { CheckInRecord, StreakRecord, LearningDayRecord } from '../types';

/**
 * Check-in / streak / learning-day repository interface.
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 */
export interface ICheckInRepository {
  checkIn(
    userId: string,
    idempotencyKey: string,
  ): { checkIn: CheckInRecord; streak: StreakRecord; alreadyExists: boolean };

  getCheckInForDate(userId: string, localDate: string): CheckInRecord | null;
  getOrCreateStreak(userId: string): StreakRecord;
  updateLearningDay(userId: string, localDate: string): LearningDayRecord;

  getCheckIns(userId: string): CheckInRecord[];
  getStreak(userId: string): StreakRecord | null;
}
