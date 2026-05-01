import {
  Controller,
  Get,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { repositories } from '../domain';

export interface StudyAttemptDto {
  word_id: string;
  book_id: string;
  study_type: 'new';
  action_result: 'know' | 'forgot';
  session_id?: string;
}

/**
 * Study attempts controller.
 *
 * Handles new word learning submissions.
 */
@Controller('me/new-words')
export class StudyAttemptsController {
  @Get('next')
  getNextNewWord() {
    const word = repositories.study.getNextNewWord();
    if (!word) {
      return { message: 'No more new words available' };
    }
    return word;
  }

  @Post()
  @HttpCode(HttpStatus.OK)
  async submitStudyAttempt(
    @Body() dto: StudyAttemptDto,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    // Check idempotency
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(idempotencyKey);
      if (existing) {
        return existing.response;
      }
    }

    const result = repositories.study.submitStudyAttempt(
      dto.word_id,
      dto.book_id,
      dto.study_type,
      dto.action_result,
      idempotencyKey || '',
      dto.session_id,
    );

    // Phase 2: Create source event and settlement for effective new word
    let settlementResponse = null;
    if (result.attempt && dto.action_result === 'know' && idempotencyKey) {
      const sourceEventResult = repositories.reward.createOrGetSourceEvent(
        'effective_new_word',
        result.attempt.id,
        `${idempotencyKey}-settlement`,
      );

      const settlementResult = repositories.reward.createSettlement(
        sourceEventResult.sourceEvent.source_event_id,
        `${idempotencyKey}-settlement`,
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

    const response = {
      submit_status: 'accepted' as const,
      today_new_completed: result.attempt ? 1 : 0,
      daily_goal_status: repositories.today.getTodayState().daily_goal_status,
      already_exists: result.alreadyExists,
      settlement: settlementResponse,
    };

    // Phase 3: Update learning day after effective study
    if (result.attempt && dto.action_result === 'know') {
      const today = new Date().toISOString().split('T')[0];
      repositories.checkIn.updateLearningDay(today);
    }

    // Store idempotency key
    if (idempotencyKey) {
      repositories.idempotency.setIdempotencyKey(idempotencyKey, '/study-attempts', response);
    }

    await repositories.ensurePersisted();

    return response;
  }
}
