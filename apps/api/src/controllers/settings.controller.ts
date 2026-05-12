import {
  Controller,
  Put,
  Body,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

export interface UpdateDailyGoalDto {
  daily_new_target: number;
}

/**
 * User settings controller.
 *
 * Handles user preference updates (daily goal, etc.)
 *
 * 需求 23 Phase A4-α: AuthGuard required; user_id sourced from token.
 */
@Controller('me/settings')
@UseGuards(AuthGuard)
export class SettingsController {
  @Put('daily-goal')
  @HttpCode(HttpStatus.OK)
  async updateDailyGoal(
    @Body() dto: UpdateDailyGoalDto,
    @CurrentUser() user: RequestUser,
  ) {
    const target = Math.max(1, Math.min(100, Math.floor(dto.daily_new_target || 20)));

    await repositories.today.updateDailyNewTarget(user.id, target);

    return {
      daily_new_target: target,
      updated: true,
    };
  }
}
