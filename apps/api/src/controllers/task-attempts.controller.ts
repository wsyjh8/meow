import {
  Controller,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

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
 *
 * 需求 23 Phase A4-α: AuthGuard required; audit §6 owner-check on
 * fishing task ownership inside dev-store.submitFishingAttempt.
 */
@Controller('me/task-attempts')
@UseGuards(AuthGuard)
export class TaskAttemptsController {
  @Post()
  @HttpCode(HttpStatus.OK)
  async submit(
    @Body() dto: TaskAttemptDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(user.id, idempotencyKey);
      if (existing) return existing.response;
    }

    const result = repositories.fishing.submitFishingAttempt(
      user.id,
      dto.task_id,
      dto.chosen_word_id,
      idempotencyKey || '',
    );

    const balance = repositories.reward.getBalanceSnapshot(user.id);

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
      repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, '/me/task-attempts', response);
    }

    await repositories.ensurePersisted();
    return response;
  }
}
