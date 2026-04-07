import { Controller, Get } from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Today controller.
 *
 * Main endpoint for "今日页" aggregation.
 */
@Controller('me/today')
export class TodayController {
  @Get()
  getToday() {
    const today = new Date().toISOString().split('T')[0];
    repositories.checkIn.updateLearningDay(today);

    const todayState = repositories.today.getTodayState();

    const checkIn = repositories.checkIn.getCheckInForDate(today);
    const streak = repositories.checkIn.getOrCreateStreak();

    return {
      ...todayState,
      has_checked_in_today: checkIn !== null,
      current_streak: streak.current_streak,
      streak_basis_type: streak.streak_basis_type,
    };
  }
}
