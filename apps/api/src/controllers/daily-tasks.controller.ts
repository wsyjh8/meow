import {
  Controller,
  Get,
  Post,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * Daily fishing task controller (Phase D).
 *
 * Endpoints:
 *   GET  /me/daily-tasks         — read today's task status
 *   POST /me/daily-tasks/start   — begin (or resume) the next round
 *
 * §3.2 discipline: rewards never feed back into learning progress.
 *
 * 需求 23 Phase A4-α: AuthGuard required.
 */
@Controller('me/daily-tasks')
@UseGuards(AuthGuard)
export class DailyTasksController {
  @Get()
  getDailyTask(@CurrentUser() user: RequestUser) {
    const task = repositories.fishing.getDailyFishingTask(user.id);
    const balance = repositories.reward.getBalanceSnapshot(user.id);
    return {
      task_id: task.id,
      task_date: task.task_date,
      rounds_completed: task.rounds_completed,
      rounds_total: task.rounds_total,
      status: task.status,
      has_active_round: task.current_round_fish_word_id !== null,
      fish_treats_balance: balance.fish_treats,
    };
  }

  @Post('start')
  @HttpCode(HttpStatus.OK)
  async startRound(@CurrentUser() user: RequestUser) {
    const question = repositories.fishing.startFishingRound(user.id);
    if (!question) {
      const task = repositories.fishing.getDailyFishingTask(user.id);
      return {
        started: false,
        reason: task.status === 'exhausted' ? 'exhausted' : 'no_studied_words',
        rounds_completed: task.rounds_completed,
        rounds_total: task.rounds_total,
        status: task.status,
      };
    }

    await repositories.ensurePersisted();

    return {
      started: true,
      task_id: question.task_id,
      round_number: question.round_number,
      choices: question.choices,
    };
  }
}
