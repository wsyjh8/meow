import { Controller, Get } from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Secondary summary controller (P2 Phase 1A).
 *
 * Provides a backend-owned bridge layer for secondary motivation UI.
 */
@Controller('me/secondary-summary')
export class SecondarySummaryController {
  @Get()
  getSecondarySummary() {
    return repositories.secondarySummary.getSecondarySummary();
  }
}
