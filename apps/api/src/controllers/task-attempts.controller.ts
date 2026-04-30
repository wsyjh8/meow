import {
  Controller,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { repositories } from '../domain';

export interface TaskAttemptDto {
  task_id: string;
  chosen_word_id: string;
}

/**
 * Fishing attempt controller (Phase D).
 *
 *   POST /me/task-attempts
 *
 * Submits the user's chosen word for the active fishing round.
 * On correct answer: +2 fish_treats via reward ledger.
 * On final round: earn 1 lottery box.
 */
@Controller('me/task-attempts')
export class TaskAttemptsController {
  @Post()
  @HttpCode(HttpStatus.OK)
  async submit(
    @Body() dto: TaskAttemptDto,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(idempotencyKey);
      if (existing) return existing.response;
    }

    const result = repositories.fishing.submitFishingAttempt(
      dto.task_id,
      dto.chosen_word_id,
      idempotencyKey || '',
    );

    const balance = repositories.reward.getBalanceSnapshot();

    const response = {
      submit_status: 'accepted' as const,
      already_exists: result.alreadyExists,
      is_correct: result.isCorrect,
      fish_word: result.fishWord,
      fish_treats_earned: result.fishTreatsEarned,
      rounds_completed: result.roundsCompleted,
      rounds_total: result.roundsTotal,
      status: result.status,
      box_earned: result.boxEarned,
      box_id: result.boxId,
      fish_treats_balance: balance.fish_treats,
    };

    if (idempotencyKey && result.attempt) {
      repositories.idempotency.setIdempotencyKey(idempotencyKey, '/me/task-attempts', response);
    }

    await repositories.ensurePersisted();
    return response;
  }
}
