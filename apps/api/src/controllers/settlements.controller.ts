import {
  Controller,
  Get,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
  Param,
  NotFoundException,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

export interface CreateSettlementDto {
  source_event_type: 'effective_new_word' | 'review_group_completed';
  source_ref_id: string;
}

/**
 * Settlements controller (Phase 2).
 *
 * 需求 23 Phase A4-α: AuthGuard required; user_id sourced from token.
 * audit §6 owner-check on getSettlementBySourceEventId fixes the越权
 * vulnerability where any user could read another user's settlement
 * by knowing the source_event_id.
 */
@Controller('settlements')
@UseGuards(AuthGuard)
export class SettlementsController {
  @Post('learning-rounds')
  @HttpCode(HttpStatus.OK)
  async createSettlement(
    @Body() dto: CreateSettlementDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new Error('X-Idempotency-Key header is required');
    }

    const sourceEventResult = repositories.reward.createOrGetSourceEvent(
      user.id,
      dto.source_event_type,
      dto.source_ref_id,
      idempotencyKey,
    );

    const settlementResult = repositories.reward.createSettlement(
      user.id,
      sourceEventResult.sourceEvent.source_event_id,
      idempotencyKey,
    );

    const settlement = settlementResult.settlement;

    await repositories.ensurePersisted();

    return {
      settlement_id: settlement.settlement_id,
      source_event_id: settlement.source_event_id,
      source_event_type: dto.source_event_type,
      source_ref_id: dto.source_ref_id,
      reward_settlement_status: settlement.reward_settlement_status,
      reward_items: settlement.reward_items.map(ri => ({
        reward_item_id: ri.reward_item_id,
        reward_type: ri.reward_type,
        amount: ri.amount,
        reward_status: ri.reward_status,
      })),
      already_exists: settlementResult.alreadyExists || sourceEventResult.alreadyExists,
    };
  }

  @Get(':sourceEventId')
  getSettlement(
    @Param('sourceEventId') sourceEventId: string,
    @CurrentUser() user: RequestUser,
  ) {
    const settlement = repositories.reward.getSettlementBySourceEventId(user.id, sourceEventId);

    if (!settlement) {
      throw new NotFoundException(`Settlement not found for source event: ${sourceEventId}`);
    }

    const sourceEvent = repositories.reward
      .getSourceEvents(user.id)
      .find(e => e.source_event_id === sourceEventId);

    return {
      settlement_id: settlement.settlement_id,
      source_event_id: settlement.source_event_id,
      source_event_type: sourceEvent?.source_event_type,
      source_ref_id: sourceEvent?.source_ref_id,
      reward_settlement_status: settlement.reward_settlement_status,
      reward_items: settlement.reward_items.map(ri => ({
        reward_item_id: ri.reward_item_id,
        reward_type: ri.reward_type,
        amount: ri.amount,
        reward_status: ri.reward_status,
      })),
      created_at: settlement.created_at,
      updated_at: settlement.updated_at,
    };
  }
}
