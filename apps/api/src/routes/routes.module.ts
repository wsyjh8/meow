import { Module } from '@nestjs/common';
import { HealthController } from '../controllers/health.controller';
import { TodayController } from '../controllers/today.controller';
import { StudyAttemptsController } from '../controllers/study-attempts.controller';
import { ReviewGroupsController } from '../controllers/review-groups.controller';
import { ReviewAttemptsController } from '../controllers/review-attempts.controller';
import { SessionsController } from '../controllers/sessions.controller';
import { CheckInsController } from '../controllers/check-ins.controller';
import { SettlementsController } from '../controllers/settlements.controller';
import { SecondarySummaryController } from '../controllers/secondary-summary.controller';
import { FeedController } from '../controllers/feed.controller';
import { ShopController } from '../controllers/shop.controller';
import { InventoryController } from '../controllers/inventory.controller';
import { EquipmentController } from '../controllers/equipment.controller';
import { BackupController } from '../controllers/backup.controller';
import { SettingsController } from '../controllers/settings.controller';
import { WordsController } from '../controllers/words.controller';
import { MeWordsController } from '../controllers/me-words.controller';
import { PronunciationController } from '../controllers/pronunciation.controller';
import { DailyTasksController } from '../controllers/daily-tasks.controller';
import { TaskAttemptsController } from '../controllers/task-attempts.controller';
import { LotteryController } from '../controllers/lottery.controller';
import {
  AudioAssetsExamplesController,
  AudioAssetsWordsController,
} from '../controllers/audio-assets.controller';
import { ContentManifestController } from '../controllers/content-manifest.controller';

@Module({
  controllers: [
    HealthController,
    TodayController,
    StudyAttemptsController,
    ReviewGroupsController,
    ReviewAttemptsController,
    SessionsController,
    CheckInsController,
    SettlementsController,
    SecondarySummaryController,
    FeedController,
    ShopController,
    InventoryController,
    EquipmentController,
    BackupController,
    SettingsController,
    WordsController,
    MeWordsController,
    PronunciationController,
    // Phase D
    DailyTasksController,
    TaskAttemptsController,
    LotteryController,
    // v0.3.0 pilot: audio assets (mock CDN era)
    //   - examples: P2.1 (例句音频)
    //   - words: P2.2 (单词音频, replaces legacy /api/v1/pronunciation)
    AudioAssetsExamplesController,
    AudioAssetsWordsController,
    // v0.3.0 PR-A Day 4: content manifest discovery for clients
    ContentManifestController,
  ],
})
export class RoutesModule {}
