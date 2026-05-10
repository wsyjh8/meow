import { Controller, Get, UseGuards } from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * Today controller.
 *
 * Main endpoint for "今日页" aggregation.
 *
 * 需求 23 Phase A4-α: AuthGuard required; user_id sourced from token.
 */
@Controller('me/today')
@UseGuards(AuthGuard)
export class TodayController {
  @Get()
  getToday(@CurrentUser() user: RequestUser) {
    const today = new Date().toISOString().split('T')[0];
    repositories.checkIn.updateLearningDay(user.id, today);

    const todayState = repositories.today.getTodayState(user.id);

    const checkIn = repositories.checkIn.getCheckInForDate(user.id, today);
    const streak = repositories.checkIn.getOrCreateStreak(user.id);

    return {
      ...todayState,
      has_checked_in_today: checkIn !== null,
      current_streak: streak.current_streak,
      streak_basis_type: streak.streak_basis_type,
    };
  }
}
