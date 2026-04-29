import { Controller, Post, Body, Headers, HttpCode, HttpStatus } from '@nestjs/common';
import { repositories } from '../domain';

export interface ReviewAttemptDto {
  review_group_id: string;
  word_id: string;
  action_result: 'correct' | 'incorrect';
}

interface LocalWordAttemptDto {
  word_id: string;
  action_result: 'correct' | 'incorrect';
}

interface LocalBatchReviewAttemptDto {
  word_attempts: LocalWordAttemptDto[];
}

/**
 * Review attempts controller.
 */
@Controller('review-attempts')
export class ReviewAttemptsController {
  @Post()
  @HttpCode(HttpStatus.OK)
  async submitReviewAttempt(
    @Body() dto: ReviewAttemptDto,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(idempotencyKey);
      if (existing) {
        return existing.response;
      }
    }

    const result = repositories.review.submitReviewAttempt(
      dto.review_group_id,
      dto.word_id,
      dto.action_result,
      idempotencyKey || '',
    );

    const state = repositories.today.getTodayState();

    let settlementResponse = null;
    if (result.success && result.groupCompleted && idempotencyKey) {
      const hasGroupCompletedEvent = repositories.review.hasReviewGroupCompletedEvent(dto.review_group_id);

      if (!hasGroupCompletedEvent) {
        const sourceEventResult = repositories.reward.createOrGetSourceEvent(
          'review_group_completed',
          dto.review_group_id,
          `${idempotencyKey}-group-settlement`,
        );

        const settlementResult = repositories.reward.createSettlement(
          sourceEventResult.sourceEvent.source_event_id,
          `${idempotencyKey}-group-settlement`,
        );

        settlementResponse = {
          source_event_id: sourceEventResult.sourceEvent.source_event_id,
          reward_settlement_status: settlementResult.settlement.reward_settlement_status,
          reward_items: settlementResult.settlement.reward_items.map(ri => ({
            reward_type: ri.reward_type,
            amount: ri.amount,
            reward_status: ri.reward_status,
          })),
        };
      }
    }

    const response = {
      submit_status: result.success ? 'accepted' as const : 'rejected' as const,
      group_completed: result.groupCompleted,
      group_remaining: state.active_review_group_remaining,
      today_review_completed: state.today_review_completed,
      daily_goal_status: state.daily_goal_status,
      already_exists: result.alreadyExists,
      settlement: settlementResponse,
    };

    if (result.success && dto.action_result === 'correct') {
      const today = new Date().toISOString().split('T')[0];
      repositories.checkIn.updateLearningDay(today);
    }

    if (idempotencyKey) {
      repositories.idempotency.setIdempotencyKey(idempotencyKey, '/review-attempts', response);
    }

    await repositories.ensurePersisted();

    return response;
  }

  /**
   * POST /review-attempts/local-batch
   *
   * P3.3.16 — Real cutover endpoint.
   * Accepts a batch of word ratings from a local-origin review session
   * (served by LocalReviewQueueBuilder, no backend-issued reviewGroupId).
   * Triggers the same settlement + daily_goal + learning_day chain as
   * the single-word cloud path.
   */
  @Post('local-batch')
  @HttpCode(HttpStatus.OK)
  async submitLocalReviewBatch(
    @Body() dto: LocalBatchReviewAttemptDto,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(idempotencyKey);
      if (existing) {
        return existing.response;
      }
    }

    const result = repositories.review.submitLocalReviewBatch(
      dto.word_attempts,
      idempotencyKey || '',
    );

    const state = repositories.today.getTodayState();

    let settlementResponse = null;
    const localGroupId = result.localGroupId;
    if (result.success && !result.alreadyExists && idempotencyKey) {
      const hasEvent = repositories.review.hasReviewGroupCompletedEvent(localGroupId);
      if (!hasEvent) {
        const sourceEventResult = repositories.reward.createOrGetSourceEvent(
          'review_group_completed',
          localGroupId,
          `${idempotencyKey}-group-settlement`,
        );
        const settlementResult = repositories.reward.createSettlement(
          sourceEventResult.sourceEvent.source_event_id,
          `${idempotencyKey}-group-settlement`,
        );
        settlementResponse = {
          source_event_id: sourceEventResult.sourceEvent.source_event_id,
          reward_settlement_status: settlementResult.settlement.reward_settlement_status,
          reward_items: settlementResult.settlement.reward_items.map(ri => ({
            reward_type: ri.reward_type,
            amount: ri.amount,
            reward_status: ri.reward_status,
          })),
        };
      }
    }

    const response = {
      submit_status: result.success ? 'accepted' as const : 'rejected' as const,
      group_completed: true,
      group_remaining: 0,
      today_review_completed: state.today_review_completed,
      daily_goal_status: state.daily_goal_status,
      already_exists: result.alreadyExists,
      settlement: settlementResponse,
    };

    if (result.success && dto.word_attempts.some(a => a.action_result === 'correct')) {
      const today = new Date().toISOString().split('T')[0];
      repositories.checkIn.updateLearningDay(today);
    }

    if (idempotencyKey) {
      repositories.idempotency.setIdempotencyKey(idempotencyKey, '/review-attempts/local-batch', response);
    }

    await repositories.ensurePersisted();
    return response;
  }
}
