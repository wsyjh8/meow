import {
  Controller,
  Get,
  BadRequestException,
  InternalServerErrorException,
  Param,
  Query,
  Res,
} from '@nestjs/common';
import type { Response } from 'express';

/**
 * Pronunciation controller — 302 redirect to Tencent COS public-read URL.
 *
 * GET /api/v1/pronunciation/:word?locale=en-US&voice=am_michael
 *
 * PR-D Option A: WAV files now live on COS at:
 *   {PRONUNCIATION_CDN_ORIGIN}/pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav
 *
 * The server returns 302 with `Location: <COS URL>`; mobile `http` package
 * follows redirects automatically (default maxRedirects=5), so client code
 * is unchanged.
 *
 * Validation (preserved from PR-A; defense-in-depth against path traversal
 * in COS keys):
 *   - word:   /^[a-z][a-z0-9'\-]{0,59}$/
 *   - locale: /^[A-Za-z\-]{1,16}$/
 *   - voice:  /^[a-z_]{1,32}$/
 *
 * Errors:
 *   - 400 BadRequest      → invalid word/locale/voice format
 *   - 500 InternalError   → server config missing PRONUNCIATION_CDN_ORIGIN
 *                            (NOT 404 — that would mislead clients into
 *                             thinking the word is missing from corpus)
 *   - 404 from COS GET    → wav genuinely missing (after client follows redirect)
 */
@Controller('pronunciation')
export class PronunciationController {
  @Get(':word')
  getAudio(
    @Param('word') word: string,
    @Query('locale') locale = 'en-US',
    @Query('voice') voice = 'am_michael',
    @Res() res: Response,
  ): void {
    const normalized = word.toLowerCase().trim();

    // Sanitize: only allow characters that appear in English words.
    // Prevents path traversal (no slashes, dots, etc.) — same regex as PR-A.
    if (!/^[a-z][a-z0-9'\-]{0,59}$/.test(normalized)) {
      throw new BadRequestException('Invalid word');
    }

    // Validate locale / voice. These are user-supplied query params; even
    // though they're substituted into a COS URL (not a filesystem path),
    // strict allowlists prevent surprises (path traversal, header injection).
    if (!/^[A-Za-z\-]{1,16}$/.test(locale)) {
      throw new BadRequestException('Invalid locale');
    }
    if (!/^[a-z_]{1,32}$/.test(voice)) {
      throw new BadRequestException('Invalid voice');
    }

    const cdnOrigin = process.env.PRONUNCIATION_CDN_ORIGIN;
    if (!cdnOrigin) {
      // R4 P1-3: server config error → 500 (NOT 404). 404 would mislead
      // clients into thinking the requested word is missing from the corpus.
      throw new InternalServerErrorException({
        error: 'PRONUNCIATION_CDN_ORIGIN not configured on server',
      });
    }

    // Strip any trailing slash on the env value so we don't double-slash.
    const origin = cdnOrigin.replace(/\/+$/, '');
    const cosUrl = `${origin}/pronunciation/${locale}/${voice}/v1/${normalized[0]}/${normalized}.wav`;
    res.redirect(302, cosUrl);
  }
}
