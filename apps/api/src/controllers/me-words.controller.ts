import {
  Controller,
  Get,
  Param,
  Query,
  UseGuards,
} from '@nestjs/common';
import { repositories } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * Per-user word-scoped queries.
 *
 * Need #10 — Recorded review timestamps. The review-history endpoint
 * returns up to [limit] accepted review attempts for one word, newest
 * first. Multiple attempts on the same calendar day are allowed and
 * each is returned as its own entry.
 *
 * Out of scope (Need #10):
 * - "next due" hints
 * - FSRS-internal scheduling fields
 * - reward / settlement state
 *
 * The shape returned here is `accepted` cloud history only. Local
 * pending/unsynced records are queried client-side from the on-device
 * review log; the debug page composes the two views.
 *
 * 需求 23 Phase A4-α: AuthGuard required; review history filtered by user.
 */
@Controller('me/words')
@UseGuards(AuthGuard)
export class MeWordsController {
  @Get(':wordId/review-history')
  getReviewHistory(
    @Param('wordId') wordId: string,
    @CurrentUser() user: RequestUser,
    @Query('limit') limitStr?: string,
  ) {
    const parsed = parseInt(limitStr || '20', 10);
    const limit = Number.isFinite(parsed) && parsed > 0
      ? Math.min(parsed, 200)
      : 20;

    const attempts = repositories.review.getReviewAttemptsForWord(user.id, wordId, limit);

    return {
      word_id: wordId,
      limit,
      total: attempts.length,
      items: attempts.map(a => ({
        attempt_id: a.id,
        word_id: a.word_id,
        review_group_id: a.review_group_id,
        action_result: a.action_result,
        reviewed_at: a.created_at,
        session_id: a.session_id ?? null,
      })),
    };
  }
}
