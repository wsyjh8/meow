import {
  Controller,
  Get,
  Post,
  Headers,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * Check-ins controller (Phase 3).
 *
 * 需求 23 Phase A4-α: AuthGuard required; user_id sourced from token.
 */
@Controller('check-ins')
@UseGuards(AuthGuard)
export class CheckInsController {
  @Post()
  @HttpCode(HttpStatus.OK)
  async checkIn(
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new Error('X-Idempotency-Key header is required');
    }

    const result = repositories.checkIn.checkIn(user.id, idempotencyKey);

    await repositories.ensurePersisted();

    return {
      check_in: {
        local_date: result.checkIn.local_date,
        check_in_status: result.checkIn.check_in_status,
      },
      streak: {
        current_streak: result.streak.current_streak,
        streak_basis_type: result.streak.streak_basis_type,
      },
      learning_day: {
        learning_day_today: repositories.today.getTodayState(user.id).learning_day_today,
      },
      already_exists: result.alreadyExists,
    };
  }

  @Get('today')
  getTodayCheckIn(@CurrentUser() user: RequestUser) {
    const today = new Date().toISOString().split('T')[0];
    const checkIn = repositories.checkIn.getCheckInForDate(user.id, today);
    const streak = repositories.checkIn.getOrCreateStreak(user.id);

    return {
      check_in: checkIn
        ? {
            local_date: checkIn.local_date,
            check_in_status: checkIn.check_in_status,
          }
        : null,
      streak: {
        current_streak: streak.current_streak,
        streak_basis_type: streak.streak_basis_type,
      },
      learning_day: {
        learning_day_today: repositories.today.getTodayState(user.id).learning_day_today,
      },
    };
  }
}
