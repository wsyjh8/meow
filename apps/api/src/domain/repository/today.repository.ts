import { TodayState } from '../types';

/**
 * Today state / daily goal repository interface.
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 */
export interface ITodayRepository {
  getTodayState(userId: string): TodayState;
  updateTodayState(userId: string, updates: Partial<TodayState>): TodayState;
  updateDailyNewTarget(userId: string, newTarget: number): Promise<void>;
}
