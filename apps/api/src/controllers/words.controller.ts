import {
  Controller,
  Get,
  Param,
  Query,
} from '@nestjs/common';
import { devStore } from '../domain/dev-store';

/**
 * Words controller — batch word list access.
 *
 * Used by Flutter client to populate cached_words table for offline study.
 * GET /api/v1/books/:bookId/words?offset=0&limit=500
 */
@Controller('books')
export class WordsController {
  @Get(':bookId/words')
  getWordsByBook(
    @Param('bookId') bookId: string,
    @Query('offset') offsetStr?: string,
    @Query('limit') limitStr?: string,
  ) {
    const offset = Math.max(0, parseInt(offsetStr || '0', 10) || 0);
    const limit = Math.min(1000, Math.max(1, parseInt(limitStr || '500', 10) || 500));

    const result = devStore.getWordsByBook(bookId, offset, limit);

    return {
      book_id: bookId,
      offset,
      limit,
      total: result.total,
      words: result.words,
    };
  }
}
