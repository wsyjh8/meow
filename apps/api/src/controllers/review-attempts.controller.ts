import { Controller, Post, Body, Headers, HttpCode, HttpStatus, UseGuards } from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

export interface ReviewAttemptDto {
  review_group_id: string;
  word_id: string;
  action_result: 'correct' | 'incorrect';
  session_id?: string;
}

interface LocalWordAttemptDto {
  word_id: string;
  action_result: 'correct' | 'incorrect';
  session_id?: string;
}

interface LocalBatchReviewAttemptDto {
  word_attempts: LocalWordAttemptDto[];
  session_id?: string;
}

/**
 * Review attempts controller.
 *
 * 需求 23 Phase A4-α: AuthGuard required.
 * audit §6 owner-check on submitReviewAttempt prevents writing to
 * another user's review_group.
 */
@Controller('review-attempts')
@UseGuards(AuthGuard)
export class ReviewAttemptsController {
  @Post()
  @HttpCode(HttpStatus.OK)
  async submitReviewAttempt(
    @Body() dto: ReviewAttemptDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(user.id, idempotencyKey);
      if (existing) {
        return existing.response;
      }
    }

    const result = repositories.review.submitReviewAttempt(
      user.id,
      dto.review_group_id,
      dto.word_id,
      dto.action_result,
      idempotencyKey || '',
      dto.session_id,
    );

    const state = repositories.today.getTodayState(user.id);

    let settlementResponse = null;
    if (result.success && result.groupCompleted && idempotencyKey) {
      const hasGroupCompletedEvent = repositories.review.hasReviewGroupCompletedEvent(user.id, dto.review_group_id);

      if (!hasGroupCompletedEvent) {
        const sourceEventResult = repositories.reward.createOrGetSourceEvent(
          user.id,
          'review_group_completed',
          dto.review_group_id,
          `${idempotencyKey}-group-settlement`,
        );

        const settlementResult = repositories.reward.createSettlement(
          user.id,
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
      repositories.checkIn.updateLearningDay(user.id, today);
    }

    if (idempotencyKey) {
      repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, '/review-attempts', response);
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
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(user.id, idempotencyKey);
      if (existing) {
        return existing.response;
      }
    }

    const wordAttemptsWithSession = dto.word_attempts.map(wa => ({
      ...wa,
      session_id: wa.session_id ?? dto.session_id,
    }));
    const result = repositories.review.submitLocalReviewBatch(
      user.id,
      wordAttemptsWithSession,
      idempotencyKey || '',
    );

    const state = repositories.today.getTodayState(user.id);

    let settlementResponse = null;
    const localGroupId = result.localGroupId;
    if (result.success && !result.alreadyExists && idempotencyKey) {
      const hasEvent = repositories.review.hasReviewGroupCompletedEvent(user.id, localGroupId);
      if (!hasEvent) {
        const sourceEventResult = repositories.reward.createOrGetSourceEvent(
          user.id,
          'review_group_completed',
          localGroupId,
          `${idempotencyKey}-group-settlement`,
        );
        const settlementResult = repositories.reward.createSettlement(
          user.id,
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
      repositories.checkIn.updateLearningDay(user.id, today);
    }

    if (idempotencyKey) {
      repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, '/review-attempts/local-batch', response);
    }

    await repositories.ensurePersisted();
    return response;
  }
}
