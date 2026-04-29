import {
  Controller,
  Get,
  Header,
  NotFoundException,
  BadRequestException,
  Param,
  Query,
  StreamableFile,
} from '@nestjs/common';
import * as fs from 'fs';
import * as path from 'path';

/**
 * Pronunciation controller — stream WAV audio for a given word.
 *
 * GET /api/v1/pronunciation/:word?locale=en-US&voice=am_michael
 *
 * Audio files live at:
 *   data/pronunciation/{locale}/{voice}/v1/{firstLetter}/{word}.wav
 *
 * Default voice: American male (en-US / am_michael).
 * Returns 404 if the audio file does not exist for the requested word/locale/voice.
 */
@Controller('pronunciation')
export class PronunciationController {
  // In ts-node dev:   __dirname = src/controllers/  → up 2 → project root
  // In compiled dist: __dirname = dist/controllers/ → up 2 → project root
  private readonly dataDir = path.resolve(
    __dirname,
    '..',
    '..',
    'data',
    'pronunciation',
  );

  @Get(':word')
  @Header('Cache-Control', 'public, max-age=86400')
  getAudio(
    @Param('word') word: string,
    @Query('locale') locale = 'en-US',
    @Query('voice') voice = 'am_michael',
  ): StreamableFile {
    const normalized = word.toLowerCase().trim();

    // Sanitize: only allow characters that appear in English words.
    // Prevents path traversal (no slashes, dots, etc.).
    if (!/^[a-z][a-z0-9''\-]{0,59}$/.test(normalized)) {
      throw new BadRequestException('Invalid word');
    }

    const audioPath = path.join(
      this.dataDir,
      locale,
      voice,
      'v1',
      normalized[0],
      `${normalized}.wav`,
    );

    if (!fs.existsSync(audioPath)) {
      throw new NotFoundException({
        error: 'Pronunciation not found',
        word: normalized,
      });
    }

    // Include Content-Length so Android's MediaPlayer can properly size its buffer.
    // Without it, the chunked transfer response causes MEDIA_ERROR_SYSTEM on Android.
    const { size } = fs.statSync(audioPath);
    return new StreamableFile(fs.createReadStream(audioPath), {
      type: 'audio/wav',
      length: size,
    });
  }
}
