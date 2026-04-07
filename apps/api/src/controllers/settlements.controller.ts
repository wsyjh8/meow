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
} from '@nestjs/common';
import { repositories } from '../domain';

export interface CreateSettlementDto {
  source_event_type: 'effective_new_word' | 'review_group_completed';
  source_ref_id: string;
}

/**
 * Settlements controller (Phase 2).
 */
@Controller('settlements')
export class SettlementsController {
  @Post('learning-rounds')
  @HttpCode(HttpStatus.OK)
  async createSettlement(
    @Body() dto: CreateSettlementDto,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new Error('X-Idempotency-Key header is required');
    }

    const sourceEventResult = repositories.reward.createOrGetSourceEvent(
      dto.source_event_type,
      dto.source_ref_id,
      idempotencyKey,
    );

    const settlementResult = repositories.reward.createSettlement(
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
  getSettlement(@Param('sourceEventId') sourceEventId: string) {
    const settlement = repositories.reward.getSettlementBySourceEventId(sourceEventId);

    if (!settlement) {
      throw new NotFoundException(`Settlement not found for source event: ${sourceEventId}`);
    }

    const sourceEvent = repositories.reward
      .getSourceEvents()
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
