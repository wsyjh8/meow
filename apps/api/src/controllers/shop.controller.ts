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

export interface PurchaseDto {
  item_id: string;
}

/**
 * Shop controller (P2 Phase 2D).
 *
 * 需求 23 Phase A4-α: mixed auth — /shop/catalog is public, /shop/purchases
 * requires AuthGuard (method-level decorator).
 */
@Controller('shop')
export class ShopController {
  @Get('catalog')
  getCatalog() {
    return {
      items: repositories.catalog.getCatalog(),
    };
  }

  @Post('purchases')
  @UseGuards(AuthGuard)
  @HttpCode(HttpStatus.OK)
  async purchase(
    @Body() dto: PurchaseDto,
    @CurrentUser() user: RequestUser,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new BadRequestException('X-Idempotency-Key header is required');
    }
    if (!dto.item_id) {
      throw new BadRequestException('item_id is required');
    }

    const result = repositories.inventory.purchaseItem(user.id, dto.item_id, idempotencyKey);

    if (result.status === 'failed') {
      return {
        purchase_result: {
          status: 'failed',
          error_code: result.errorCode,
          item_id: dto.item_id,
          coins_spent: 0,
        },
        inventory: repositories.inventory.getInventory(user.id),
      };
    }

    if (!result.alreadyExists) {
      repositories.idempotency.setIdempotencyKey(user.id, idempotencyKey, 'shop/purchases', {
        item_id: dto.item_id,
        coins_spent: result.coinsSpent,
      });
    }

    await repositories.ensurePersisted();

    return {
      purchase_result: {
        status: 'succeeded',
        item_id: dto.item_id,
        coins_spent: result.coinsSpent,
        already_exists: result.alreadyExists,
      },
      inventory: repositories.inventory.getInventory(user.id),
    };
  }
}
