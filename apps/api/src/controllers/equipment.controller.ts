import {
  Controller,
  Get,
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

export interface EquipDto {
  item_id: string;
}

/**
 * Equipment controller (P2 Phase 3).
 *
 * Provides equipped-state read and equip/unequip flow.
 *
 * Frozen rules:
 * - Equipped state is backend truth
 * - Only owned items can be equipped
 * - One item per slot
 * - Idempotency key prevents duplicate side effects
 *
 * 需求 23 Phase A4-α: AuthGuard required.
 */
@Controller('me/equipment')
@UseGuards(AuthGuard)
export class EquipmentController {
  /**
   * GET /api/v1/me/equipment
   *
   * Returns the current equipped snapshot.
   */
  @Get()
  getEquipment(@CurrentUser() user: RequestUser) {
    return {
      equipped_snapshot: repositories.equipment.getEquippedSnapshot(user.id),
    };
  }

  /**
   * POST /api/v1/me/equipment/equip
   *
   * Equip an owned item. Replaces any existing item in the same slot.
   */
  @Post('equip')
  @HttpCode(HttpStatus.OK)
  async equip(
    @Body() dto: EquipDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new BadRequestException('X-Idempotency-Key header is required');
    }
    if (!dto.item_id) {
      throw new BadRequestException('item_id is required');
    }

    const result = repositories.equipment.equipItem(user.id, dto.item_id, idempotencyKey);

    if (result.status === 'failed') {
      return {
        equip_result: {
          status: 'failed',
          error_code: result.errorCode,
          item_id: dto.item_id,
        },
        equipped_snapshot: repositories.equipment.getEquippedSnapshot(user.id),
      };
    }

    // Save idempotency key for replay
    if (!result.alreadyExists) {
      repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, 'me/equipment/equip', {
        item_id: dto.item_id,
        slot: result.slot,
        item_type: result.itemType,
      });
    }

    await repositories.ensurePersisted();

    return {
      equip_result: {
        status: 'succeeded',
        item_id: dto.item_id,
        slot: result.slot,
        item_type: result.itemType,
        already_exists: result.alreadyExists,
      },
      equipped_snapshot: repositories.equipment.getEquippedSnapshot(user.id),
    };
  }

  /**
   * POST /api/v1/me/equipment/unequip
   *
   * Unequip an item from its slot.
   */
  @Post('unequip')
  @HttpCode(HttpStatus.OK)
  async unequip(
    @Body() dto: EquipDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new BadRequestException('X-Idempotency-Key header is required');
    }
    if (!dto.item_id) {
      throw new BadRequestException('item_id is required');
    }

    const result = repositories.equipment.unequipItem(user.id, dto.item_id, idempotencyKey);

    if (result.status === 'failed') {
      return {
        unequip_result: {
          status: 'failed',
          error_code: result.errorCode,
          item_id: dto.item_id,
        },
        equipped_snapshot: repositories.equipment.getEquippedSnapshot(user.id),
      };
    }

    if (!result.alreadyExists) {
      repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, 'me/equipment/unequip', {
        item_id: dto.item_id,
      });
    }

    await repositories.ensurePersisted();

    return {
      unequip_result: {
        status: 'succeeded',
        item_id: dto.item_id,
        already_exists: result.alreadyExists,
      },
      equipped_snapshot: repositories.equipment.getEquippedSnapshot(user.id),
    };
  }
}
