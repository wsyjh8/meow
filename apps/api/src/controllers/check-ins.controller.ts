import {
  Controller,
  Get,
  Post,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Check-ins controller (Phase 3).
 */
@Controller('check-ins')
export class CheckInsController {
  @Post()
  @HttpCode(HttpStatus.OK)
  async checkIn(@Headers('x-idempotency-key') idempotencyKey?: string) {
    if (!idempotencyKey) {
      throw new Error('X-Idempotency-Key header is required');
    }

    const result = repositories.checkIn.checkIn(idempotencyKey);

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
        learning_day_today: repositories.today.getTodayState().learning_day_today,
      },
      already_exists: result.alreadyExists,
    };
  }

  @Get('today')
  getTodayCheckIn() {
    const today = new Date().toISOString().split('T')[0];
    const checkIn = repositories.checkIn.getCheckInForDate(today);
    const streak = repositories.checkIn.getOrCreateStreak();

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
        learning_day_today: repositories.today.getTodayState().learning_day_today,
      },
    };
  }
}
