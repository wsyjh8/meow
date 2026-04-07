import { Controller, Get } from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Inventory controller (P2 Phase 2D).
 *
 * Provides read access to user's owned items and current coins balance.
 */
@Controller('me/inventory')
export class InventoryController {
  @Get()
  getInventory() {
    return repositories.inventory.getInventory();
  }
}
