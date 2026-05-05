import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { join } from 'path';
import { AppModule } from './app.module';
import { loggingMiddleware } from './middleware/logging.middleware';
import { errorFilter } from './middleware/error.filter';
import { PersistenceFailureFilter } from './middleware/persistence-failure.filter';

async function bootstrap() {
  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Global prefix for API versioning (does NOT affect static assets below)
  app.setGlobalPrefix('api/v1');

  // Mock CDN — serve published audio assets from apps/api/cdn-mock/ at /cdn/*
  // Codex pipeline writes mp3 files under cdn-mock/audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
  // App fetches via http://10.0.2.2:3000/cdn/audio/v1/...
  // When real CDN comes online, just stop serving this prefix and update audio_assets.url.
  app.useStaticAssets(join(__dirname, '..', 'cdn-mock'), {
    prefix: '/cdn',
    setHeaders: (res) => {
      // Long cache: audio_id is content-addressable + version-pathed, never overwritten in place
      res.setHeader('Cache-Control', 'public, max-age=31536000, immutable');
    },
  });

  // Request logging
  app.use(loggingMiddleware);

  // Global error filters (persistence failure filter first, then general)
  app.useGlobalFilters(new PersistenceFailureFilter(), errorFilter);

  // CORS for mobile development
  app.enableCors({
    origin: process.env.CORS_ORIGIN || '*',
    methods: ['GET', 'POST', 'PUT', 'PATCH', 'DELETE', 'OPTIONS'],
    allowedHeaders: ['Content-Type', 'Authorization', 'X-Idempotency-Key'],
  });

  const port = process.env.PORT || 3000;
  await app.listen(port);
  console.log(`API server running on port ${port}`);
}
bootstrap();
