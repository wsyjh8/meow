import { Controller, Get, UseGuards } from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * Inventory controller (P2 Phase 2D).
 *
 * Provides read access to user's owned items and current coins balance.
 *
 * 需求 23 Phase A4-α: AuthGuard required.
 */
@Controller('me/inventory')
@UseGuards(AuthGuard)
export class InventoryController {
  @Get()
  getInventory(@CurrentUser() user: RequestUser) {
    return repositories.inventory.getInventory(user.id);
  }
}
