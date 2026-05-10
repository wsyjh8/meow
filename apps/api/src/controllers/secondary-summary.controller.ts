import { Controller, Get, UseGuards } from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * Secondary summary controller (P2 Phase 1A).
 *
 * Provides a backend-owned bridge layer for secondary motivation UI.
 *
 * 需求 23 Phase A4-α: AuthGuard required.
 */
@Controller('me/secondary-summary')
@UseGuards(AuthGuard)
export class SecondarySummaryController {
  @Get()
  getSecondarySummary(@CurrentUser() user: RequestUser) {
    return repositories.secondarySummary.getSecondarySummary(user.id);
  }
}
