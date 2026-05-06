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

  // PR-B3 Day 1 (D3) — staging serve route. Two key constraints:
  //   1. (R1#1) MUST be registered BEFORE the /cdn cdn-mock route below.
  //      NestJS/express useStaticAssets matches by registration order +
  //      next() fallthrough — NOT by prefix length. If cdn-mock came first,
  //      a request for /cdn/staging/foo would enter the /cdn middleware
  //      first (looking up cdn-mock/staging/foo) and only fall through to
  //      this route via next() — risky if cdn-mock ever has a staging/
  //      subdir, which would shadow real staging files.
  //   2. (R2#1) Dev/local mode only. In production we still skip file://
  //      rows in the manifest API, but the static route would expose the
  //      deploy directory. Guard with `if (!isProdEnv)`.
  //
  // Cache-Control 'no-cache' because staging files change during develop;
  // a real CDN (future) sets long-lived cache headers itself.
  const isProdEnv = process.env.NODE_ENV === 'production';
  if (!isProdEnv) {
    app.useStaticAssets(join(__dirname, '..', 'audio-pipeline-staging'), {
      prefix: '/cdn/staging',
      setHeaders: (res) => {
        res.setHeader('Cache-Control', 'no-cache');
      },
    });
  }

  // Mock CDN — serve published audio assets from apps/api/cdn-mock/ at /cdn/*
  // Codex pipeline writes mp3 files under cdn-mock/audio/v1/{kind}s/{locale}/{voice}/{audio_version}/{shard}/{audio_id}.mp3
  // App fetches via http://10.0.2.2:3000/cdn/audio/v1/...
  // When real CDN comes online, just stop serving this prefix and update audio_assets.url.
  // NOTE: Registered AFTER /cdn/staging above — see PR-B3 Day 1 comment.
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
