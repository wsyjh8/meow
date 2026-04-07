import { Controller, Get } from '@nestjs/common';
import { repositories } from '../domain';

/**
 * Review groups controller.
 * 
 * Handles review_group lifecycle.
 * 
 * Frozen rules:
 * - Backend generates and holds review_group
 * - Only one active group per user at a time
 * - Group completion only advances today's review progress
 * - Group completion != today's review completion
 * - Same active group can span across sessions
 * - No duplicate completion/settlement/rewards
 * 
 * Blocked if touched:
 * - Group size algorithm
 * - Grouping algorithm
 * - Review priority algorithm
 */
@Controller('me/review-groups')
export class ReviewGroupsController {
  @Get('next')
  getNextReviewGroup() {
    const group = repositories.review.getOrCreateReviewGroup();
    return {
      review_group_id: group.review_group_id,
      group_status: group.group_status,
      group_completed: group.group_completed,
      remaining_count: group.items.filter(i => !i.completed).length,
      items: group.items.map(i => ({
        word_id: i.word_id,
        word_text: i.word_text,
        meaning: i.meaning,
        completed: i.completed,
      })),
    };
  }
}
