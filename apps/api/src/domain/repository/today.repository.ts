import { TodayState, DailyGoalStatus } from '../types';

/**
 * Today state / daily goal repository interface.
 *
 * Covers: today aggregation, daily goal status.
 */
export interface ITodayRepository {
  getTodayState(): TodayState;
  updateTodayState(updates: Partial<TodayState>): TodayState;
  updateDailyNewTarget(newTarget: number): Promise<void>;
}
