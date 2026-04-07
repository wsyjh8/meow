import {
  Controller,
  Put,
  Body,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { repositories } from '../domain';

export interface UpdateDailyGoalDto {
  daily_new_target: number;
}

/**
 * User settings controller.
 *
 * Handles user preference updates (daily goal, etc.)
 */
@Controller('me/settings')
export class SettingsController {
  @Put('daily-goal')
  @HttpCode(HttpStatus.OK)
  async updateDailyGoal(@Body() dto: UpdateDailyGoalDto) {
    const target = Math.max(1, Math.min(100, Math.floor(dto.daily_new_target || 20)));

    await repositories.today.updateDailyNewTarget(target);

    return {
      daily_new_target: target,
      updated: true,
    };
  }
}
