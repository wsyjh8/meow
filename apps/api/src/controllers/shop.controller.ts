import {
  Controller,
  Get,
  Post,
  Body,
  Headers,
  HttpCode,
  HttpStatus,
  BadRequestException,
} from '@nestjs/common';
import { repositories } from '../domain';

export interface PurchaseDto {
  item_id: string;
}

/**
 * Shop controller (P2 Phase 2D).
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
  @HttpCode(HttpStatus.OK)
  async purchase(
    @Body() dto: PurchaseDto,
    @Headers('x-idempotency-key') idempotencyKey?: string,
  ) {
    if (!idempotencyKey) {
      throw new BadRequestException('X-Idempotency-Key header is required');
    }
    if (!dto.item_id) {
      throw new BadRequestException('item_id is required');
    }

    const result = repositories.inventory.purchaseItem(dto.item_id, idempotencyKey);

    if (result.status === 'failed') {
      return {
        purchase_result: {
          status: 'failed',
          error_code: result.errorCode,
          item_id: dto.item_id,
          coins_spent: 0,
        },
        inventory: repositories.inventory.getInventory(),
      };
    }

    if (!result.alreadyExists) {
      repositories.idempotency.setIdempotencyKey(idempotencyKey, 'shop/purchases', {
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
      inventory: repositories.inventory.getInventory(),
    };
  }
}
