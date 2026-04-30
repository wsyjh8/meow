import {
  Controller,
  Get,
  Post,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Daily fishing task controller (Phase D).
 *
 * Endpoints:
 *   GET  /me/daily-tasks         — read today's task status
 *   POST /me/daily-tasks/start   — begin (or resume) the next round
 *
 * §3.2 discipline: rewards never feed back into learning progress.
 */
@Controller('me/daily-tasks')
export class DailyTasksController {
  @Get()
  getDailyTask() {
    const task = repositories.fishing.getDailyFishingTask();
    const balance = repositories.reward.getBalanceSnapshot();
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
  async startRound() {
    const question = repositories.fishing.startFishingRound();
    if (!question) {
      const task = repositories.fishing.getDailyFishingTask();
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
