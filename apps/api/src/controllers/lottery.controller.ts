import {
  Controller,
  Get,
  Post,
  Param,
  Headers,
  HttpCode,
  HttpStatus,
} from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Lottery (blind box) controller (Phase D).
 *
 * Endpoints:
 *   GET  /me/lottery-boxes        — list pending (unopened) boxes
 *   POST /me/lottery-boxes/:id/open — draw a prize from prize pool
 *
 * Boxes are earned by completing fishing rounds. Opening is free.
 * Prize is coins (20/50/100) via weighted random.
 */
@Controller('me/lottery-boxes')
export class LotteryController {
  @Get()
  getBoxes() {
    const boxes = repositories.lottery.getLotteryBoxes();
    const balance = repositories.reward.getBalanceSnapshot();
    return {
      pending_boxes: boxes.map(b => ({
        id: b.id,
        source: b.source,
        created_at: b.created_at,
      })),
      total_pending: boxes.length,
      coins_balance: balance.coins,
      fish_treats_balance: balance.fish_treats,
    };
  }

  @Post(':id/open')
  @HttpCode(HttpStatus.OK)
  async openBox(
    @Param('id') boxId: string,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (idempotencyKey) {
      const existing = repositories.idempotency.getIdempotencyKey(idempotencyKey);
      if (existing) return existing.response;
    }

    const result = repositories.lottery.openLotteryBox(boxId, idempotencyKey || '');

    if (!result.box) {
      const response = {
        opened: false,
        already_exists: result.alreadyExists,
        reason: 'box_not_found_or_already_opened',
      };
      return response;
    }

    const balance = repositories.reward.getBalanceSnapshot();
    const response = {
      opened: true,
      already_exists: result.alreadyExists,
      box_id: result.box.id,
      prize_type: result.box.prize_type,
      prize_ref: result.box.prize_ref,
      coins_won: result.coinsWon,
      coins_balance: balance.coins,
    };

    if (idempotencyKey) {
      repositories.idempotency.setIdempotencyKey(idempotencyKey, '/me/lottery-boxes/open', response);
    }
    await repositories.ensurePersisted();
    return response;
  }
}
