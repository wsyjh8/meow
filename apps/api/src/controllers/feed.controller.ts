import {
  Controller,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
  BadRequestException,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

export interface FeedDto {
  feed_item_type: 'fish_treat';
}

/**
 * Feed controller (P2 Phase 2A + 2B).
 *
 * Handles feeding the cat with fish treats.
 * Phase 2B: includes growth_feedback with level-up detection.
 *
 * Frozen rules applied:
 * - fish_treats deduction is backend truth
 * - idempotency key prevents duplicate deduction
 * - cannot deduct below zero
 * - front-end must not locally pre-deduct
 * - level must be computed by backend, not client
 *
 * 需求 23 Phase A4-α: AuthGuard required.
 */
@Controller('me/feed')
@UseGuards(AuthGuard)
export class FeedController {
  /**
   * POST /api/v1/me/feed
   *
   * Feed the cat. Consumes 1 fish_treat per call.
   */
  @Post()
  @HttpCode(HttpStatus.OK)
  async feed(
    @Body() dto: FeedDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new BadRequestException('X-Idempotency-Key header is required');
    }

    if (!dto.feed_item_type || dto.feed_item_type !== 'fish_treat') {
      throw new BadRequestException('feed_item_type must be "fish_treat"');
    }

    const result = repositories.feed.feedCat(user.id, dto.feed_item_type, idempotencyKey);

    if (result.status === 'insufficient_resource') {
      return {
        feed_result: {
          status: 'insufficient_resource',
          error_code: 'FISH_TREATS_NOT_ENOUGH',
          consumed_item: null,
          consumed_amount: 0,
        },
        growth_feedback: null,
        secondary_summary: repositories.secondarySummary.getSecondarySummary(user.id),
      };
    }

    // Save idempotency key with feed_id for replay
    repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, 'me/feed', {
      feed_id: result.feedRecord!.feed_id,
    });

    // Phase 2B: Build growth_feedback
    const growthFeedback = result.leveledUp
      ? {
          leveled_up: true,
          previous_level: result.previousLevel,
          current_level: result.currentLevel,
        }
      : {
          leveled_up: false,
          previous_level: result.previousLevel,
          current_level: result.currentLevel,
        };

    await repositories.ensurePersisted();

    return {
      feed_result: {
        status: 'succeeded',
        consumed_item: result.feedRecord!.feed_item_type,
        consumed_amount: result.feedRecord!.consumed_amount,
        mood_delta: result.feedRecord!.mood_delta,
        exp_delta: result.feedRecord!.exp_delta,
        already_exists: result.alreadyExists,
      },
      growth_feedback: growthFeedback,
      secondary_summary: repositories.secondarySummary.getSecondarySummary(user.id),
    };
  }
}
