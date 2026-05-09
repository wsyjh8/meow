import { NestFactory } from '@nestjs/core';
import { NestExpressApplication } from '@nestjs/platform-express';
import { AppModule } from './app.module';
import { loggingMiddleware } from './middleware/logging.middleware';
import { errorFilter } from './middleware/error.filter';
import { PersistenceFailureFilter } from './middleware/persistence-failure.filter';
import { assertProductionAuthEnforce } from './auth/auth.guard';

async function bootstrap() {
  // 需求 23 D13: 生产环境必须开启 AUTH_ENFORCE
  assertProductionAuthEnforce();

  const app = await NestFactory.create<NestExpressApplication>(AppModule);

  // Global prefix for API versioning (does NOT affect static assets)
  app.setGlobalPrefix('api/v1');

  // PR-D Option A: /cdn static route removed. audio_assets.url now points
  // at Tencent COS public-read URLs (rewritten by repipe-audio-urls.ts);
  // pronunciation.controller.ts returns 302 redirect to COS. apps/api/cdn-mock/
  // is kept in repo as a .gitkeep placeholder so the dev pipeline
  // (partial_publish.py) still has a write target — sync-audio-mp3-to-cos.ts
  // pushes those files to COS after each publish.

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
