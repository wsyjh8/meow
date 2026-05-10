/**
 * DevStore Adapter (A1).
 *
 * Wraps the existing DevStore singleton behind repository interfaces.
 *
 * 需求 23 Phase A4-α: every adapter method binds the caller-provided
 * userId via `devStore.withUser(...)` so downstream code reads
 * `this.userId` correctly. dev-store public method signatures are
 * unchanged in α (minimal-invasive); audit §6 owner-check is enforced
 * inside dev-store using the bound `this.userId`.
 */

import { devStore } from './dev-store';
import type { IStudyRepository } from './repository/study.repository';
import type { IReviewRepository } from './repository/review.repository';
import type { IRewardRepository } from './repository/reward.repository';
import type { ISessionRepository } from './repository/session.repository';
import type { ICheckInRepository } from './repository/checkin.repository';
import type { ITodayRepository } from './repository/today.repository';
import type {
  IFeedRepository,
  ICatalogRepository,
  IInventoryRepository,
  IEquipmentRepository,
  ISecondarySummaryRepository,
} from './repository/secondary.repository';
import type { IIdempotencyRepository } from './repository/idempotency.repository';
import type { IFishingRepository, ILotteryRepository } from './repository/fishing.repository';

/** Bind userId for the duration of `fn`. Tiny helper to keep adapters readable. */
function asUser<T>(userId: string, fn: () => T): T {
  return devStore.withUser(userId, fn);
}

// ========== Study ==========

class DevStoreStudyAdapter implements IStudyRepository {
  getNextNewWord(userId: string) {
    return asUser(userId, () => devStore.getNextNewWord());
  }
  submitStudyAttempt(
    userId: string,
    wordId: string, bookId: string, studyType: 'new',
    actionResult: 'know' | 'forgot', idempotencyKey: string,
    sessionId?: string,
  ) {
    return asUser(userId, () =>
      devStore.submitStudyAttempt(wordId, bookId, studyType, actionResult, idempotencyKey, sessionId),
    );
  }
  getStudyAttempts(userId: string) {
    return asUser(userId, () => devStore.getStudyAttempts());
  }
}

// ========== Review ==========

class DevStoreReviewAdapter implements IReviewRepository {
  getActiveReviewGroup(userId: string) {
    return asUser(userId, () => devStore.getActiveReviewGroup());
  }
  getOrCreateReviewGroup(userId: string) {
    return asUser(userId, () => devStore.getOrCreateReviewGroup());
  }
  submitReviewAttempt(
    userId: string,
    reviewGroupId: string, wordId: string,
    actionResult: 'correct' | 'incorrect', idempotencyKey: string,
    sessionId?: string,
  ) {
    return asUser(userId, () =>
      devStore.submitReviewAttempt(reviewGroupId, wordId, actionResult, idempotencyKey, sessionId),
    );
  }
  submitLocalReviewBatch(
    userId: string,
    wordAttempts: { word_id: string; action_result: 'correct' | 'incorrect'; session_id?: string }[],
    idempotencyKey: string,
  ) {
    return asUser(userId, () => devStore.submitLocalReviewBatch(wordAttempts, idempotencyKey));
  }
  hasReviewGroupCompletedEvent(userId: string, reviewGroupId: string) {
    return asUser(userId, () => devStore.hasReviewGroupCompletedEvent(reviewGroupId));
  }
  getReviewGroups(userId: string) {
    return asUser(userId, () => devStore.getReviewGroups());
  }
  getReviewAttempts(userId: string) {
    return asUser(userId, () => devStore.getReviewAttempts());
  }
  getReviewAttemptsForWord(userId: string, wordId: string, limit: number) {
    return asUser(userId, () => devStore.getReviewAttemptsForWord(wordId, limit));
  }
}

// ========== Reward ==========

class DevStoreRewardAdapter implements IRewardRepository {
  createOrGetSourceEvent(userId: string, sourceEventType: any, sourceRefId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.createOrGetSourceEvent(sourceEventType, sourceRefId, idempotencyKey));
  }
  createSettlement(userId: string, sourceEventId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.createSettlement(sourceEventId, idempotencyKey));
  }
  getSettlementBySourceEventId(userId: string, id: string) {
    return asUser(userId, () => devStore.getSettlementBySourceEventId(id));
  }
  getSettlement(userId: string, id: string) {
    return asUser(userId, () => devStore.getSettlement(id));
  }
  getBalanceSnapshot(userId: string) {
    return asUser(userId, () => devStore.getBalanceSnapshot());
  }
  getSourceEvents(userId: string) {
    return asUser(userId, () => devStore.getSourceEvents());
  }
  getSettlements(userId: string) {
    return asUser(userId, () => devStore.getSettlements());
  }
  getRewardLedgerItems(userId: string) {
    return asUser(userId, () => devStore.getRewardLedgerItems());
  }
}

// ========== Session ==========

class DevStoreSessionAdapter implements ISessionRepository {
  getActiveSession(userId: string) {
    return asUser(userId, () => devStore.getActiveSession());
  }
  startSession(userId: string, minutesTarget: number, idempotencyKey: string, clientSessionId?: string) {
    return asUser(userId, () => devStore.startSession(minutesTarget, idempotencyKey, clientSessionId));
  }
  finishSession(userId: string, sessionId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.finishSession(sessionId, idempotencyKey));
  }
  getSession(userId: string, id: string) {
    return asUser(userId, () => devStore.getSession(id));
  }
  getSessions(userId: string) {
    return asUser(userId, () => devStore.getSessions());
  }
}

// ========== Check-in ==========

class DevStoreCheckInAdapter implements ICheckInRepository {
  checkIn(userId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.checkIn(idempotencyKey));
  }
  getCheckInForDate(userId: string, localDate: string) {
    return asUser(userId, () => devStore.getCheckInForDate(localDate));
  }
  getOrCreateStreak(userId: string) {
    return asUser(userId, () => devStore.getOrCreateStreak());
  }
  updateLearningDay(userId: string, localDate: string) {
    return asUser(userId, () => devStore.updateLearningDay(localDate));
  }
  getCheckIns(userId: string) {
    return asUser(userId, () => devStore.getCheckIns());
  }
  getStreak(userId: string) {
    return asUser(userId, () => devStore.getStreak());
  }
}

// ========== Today ==========

class DevStoreTodayAdapter implements ITodayRepository {
  getTodayState(userId: string) {
    return asUser(userId, () => devStore.getTodayState());
  }
  updateTodayState(userId: string, updates: any) {
    return asUser(userId, () => devStore.updateTodayState(updates));
  }
  async updateDailyNewTarget(userId: string, newTarget: number) {
    // β.9 hot-fix: dev-store.updateDailyNewTarget now takes userId as
    // first param. The legacy `this.userId = userId` binding manually was
    // also fixed since getters within the method body resolve to the
    // correct bucket via userId (the same way withUser does, but
    // explicit). Both approaches work; explicit param wins for async.
    const prev = devStore.getCurrentUserId();
    (devStore as any).userId = userId;
    try {
      return await devStore.updateDailyNewTarget(userId, newTarget);
    } finally {
      (devStore as any).userId = prev;
    }
  }
}

// ========== Feed ==========

class DevStoreFeedAdapter implements IFeedRepository {
  feedCat(userId: string, feedItemType: any, idempotencyKey: string) {
    return asUser(userId, () => devStore.feedCat(feedItemType, idempotencyKey));
  }
  getFeedRecords(userId: string) {
    return asUser(userId, () => devStore.getFeedRecords());
  }
  getTodayFeedCount(userId: string) {
    return asUser(userId, () => devStore.getTodayFeedCount());
  }
  getTotalExp(userId: string) {
    return asUser(userId, () => devStore.getTotalExp());
  }
}

// ========== Catalog (no userId — public catalog) ==========

class DevStoreCatalogAdapter implements ICatalogRepository {
  getCatalog() { return devStore.getCatalog(); }
  getCatalogItem(itemId: string) { return devStore.getCatalogItem(itemId); }
}

// ========== Inventory ==========

class DevStoreInventoryAdapter implements IInventoryRepository {
  getInventory(userId: string) {
    return asUser(userId, () => devStore.getInventory());
  }
  isItemOwned(userId: string, itemId: string) {
    return asUser(userId, () => devStore.isItemOwned(itemId));
  }
  getOwnedItems(userId: string) {
    return asUser(userId, () => devStore.getOwnedItems());
  }
  purchaseItem(userId: string, itemId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.purchaseItem(itemId, idempotencyKey));
  }
}

// ========== Equipment ==========

class DevStoreEquipmentAdapter implements IEquipmentRepository {
  getEquippedSnapshot(userId: string) {
    return asUser(userId, () => devStore.getEquippedSnapshot());
  }
  getEquippedPreview(userId: string) {
    return asUser(userId, () => devStore.getEquippedPreview());
  }
  equipItem(userId: string, itemId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.equipItem(itemId, idempotencyKey));
  }
  unequipItem(userId: string, itemId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.unequipItem(itemId, idempotencyKey));
  }
}

// ========== Secondary Summary ==========

class DevStoreSecondarySummaryAdapter implements ISecondarySummaryRepository {
  getSecondarySummary(userId: string) {
    return asUser(userId, () => devStore.getSecondarySummary());
  }
  getCatSummary(userId: string) {
    return asUser(userId, () => devStore.getCatSummary());
  }
  getCompanionResponse(userId: string) {
    return asUser(userId, () => devStore.getCompanionResponse());
  }
}

// ========== Phase D: Fishing ==========

class DevStoreFishingAdapter implements IFishingRepository {
  getDailyFishingTask(userId: string) {
    return asUser(userId, () => devStore.getDailyFishingTask());
  }
  startFishingRound(userId: string) {
    return asUser(userId, () => devStore.startFishingRound());
  }
  submitFishingAttempt(userId: string, taskId: string, chosenWordId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.submitFishingAttempt(taskId, chosenWordId, idempotencyKey));
  }
}

// ========== Phase D: Lottery ==========

class DevStoreLotteryAdapter implements ILotteryRepository {
  getLotteryBoxes(userId: string) {
    return asUser(userId, () => devStore.getLotteryBoxes());
  }
  openLotteryBox(userId: string, boxId: string, idempotencyKey: string) {
    return asUser(userId, () => devStore.openLotteryBox(boxId, idempotencyKey));
  }
}

// ========== Idempotency ==========

class DevStoreIdempotencyAdapter implements IIdempotencyRepository {
  getIdempotencyKey(userId: string, key: string) {
    return asUser(userId, () => devStore.getIdempotencyKey(key));
  }
  setIdempotencyKey(userId: string, key: string, path: string, response: Record<string, unknown>) {
    asUser(userId, () => { devStore.setIdempotencyKey(key, path, response); });
  }
}

// ========== Aggregated Repositories Object ==========

/**
 * All repository instances backed by the current DevStore.
 * Controllers import this and access individual repositories.
 */
export const repositories = {
  study: new DevStoreStudyAdapter() as IStudyRepository,
  review: new DevStoreReviewAdapter() as IReviewRepository,
  reward: new DevStoreRewardAdapter() as IRewardRepository,
  session: new DevStoreSessionAdapter() as ISessionRepository,
  checkIn: new DevStoreCheckInAdapter() as ICheckInRepository,
  today: new DevStoreTodayAdapter() as ITodayRepository,
  feed: new DevStoreFeedAdapter() as IFeedRepository,
  catalog: new DevStoreCatalogAdapter() as ICatalogRepository,
  inventory: new DevStoreInventoryAdapter() as IInventoryRepository,
  equipment: new DevStoreEquipmentAdapter() as IEquipmentRepository,
  secondarySummary: new DevStoreSecondarySummaryAdapter() as ISecondarySummaryRepository,
  idempotency: new DevStoreIdempotencyAdapter() as IIdempotencyRepository,
  fishing: new DevStoreFishingAdapter() as IFishingRepository,
  lottery: new DevStoreLotteryAdapter() as ILotteryRepository,

  /**
   * Ensure the last mutation has been persisted to the active backend.
   * Controllers MUST await this after write operations.
   * Throws if persistence fails — caller must NOT return success.
   */
  async ensurePersisted(): Promise<void> {
    await devStore.saveToDiskAsync();
  },
};

export type Repositories = typeof repositories;
