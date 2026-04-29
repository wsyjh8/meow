/**
 * DevStore Adapter (A1).
 *
 * Wraps the existing DevStore singleton behind repository interfaces.
 * This is the bridge between the old monolithic store and the new
 * interface-based persistence contract.
 *
 * In A2+, PostgreSQL implementations will implement the same interfaces.
 * In A4, controllers will be switched from this adapter to PG implementations.
 * In A5, this adapter will be removed.
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

// ========== Study ==========

class DevStoreStudyAdapter implements IStudyRepository {
  getNextNewWord() { return devStore.getNextNewWord(); }
  submitStudyAttempt(
    wordId: string, bookId: string, studyType: 'new',
    actionResult: 'know' | 'forgot', idempotencyKey: string,
  ) {
    return devStore.submitStudyAttempt(wordId, bookId, studyType, actionResult, idempotencyKey);
  }
  getStudyAttempts() { return devStore.getStudyAttempts(); }
}

// ========== Review ==========

class DevStoreReviewAdapter implements IReviewRepository {
  getActiveReviewGroup() { return devStore.getActiveReviewGroup(); }
  getOrCreateReviewGroup() { return devStore.getOrCreateReviewGroup(); }
  submitReviewAttempt(
    reviewGroupId: string, wordId: string,
    actionResult: 'correct' | 'incorrect', idempotencyKey: string,
  ) {
    return devStore.submitReviewAttempt(reviewGroupId, wordId, actionResult, idempotencyKey);
  }
  submitLocalReviewBatch(
    wordAttempts: { word_id: string; action_result: 'correct' | 'incorrect' }[],
    idempotencyKey: string,
  ) {
    return devStore.submitLocalReviewBatch(wordAttempts, idempotencyKey);
  }
  hasReviewGroupCompletedEvent(reviewGroupId: string) {
    return devStore.hasReviewGroupCompletedEvent(reviewGroupId);
  }
  getReviewGroups() { return devStore.getReviewGroups(); }
  getReviewAttempts() { return devStore.getReviewAttempts(); }
}

// ========== Reward ==========

class DevStoreRewardAdapter implements IRewardRepository {
  createOrGetSourceEvent(sourceEventType: any, sourceRefId: string, idempotencyKey: string) {
    return devStore.createOrGetSourceEvent(sourceEventType, sourceRefId, idempotencyKey);
  }
  createSettlement(sourceEventId: string, idempotencyKey: string) {
    return devStore.createSettlement(sourceEventId, idempotencyKey);
  }
  getSettlementBySourceEventId(id: string) { return devStore.getSettlementBySourceEventId(id); }
  getSettlement(id: string) { return devStore.getSettlement(id); }
  getBalanceSnapshot() { return devStore.getBalanceSnapshot(); }
  getSourceEvents() { return devStore.getSourceEvents(); }
  getSettlements() { return devStore.getSettlements(); }
  getRewardLedgerItems() { return devStore.getRewardLedgerItems(); }
}

// ========== Session ==========

class DevStoreSessionAdapter implements ISessionRepository {
  getActiveSession() { return devStore.getActiveSession(); }
  startSession(minutesTarget: number, idempotencyKey: string) {
    return devStore.startSession(minutesTarget, idempotencyKey);
  }
  finishSession(sessionId: string, idempotencyKey: string) {
    return devStore.finishSession(sessionId, idempotencyKey);
  }
  getSession(id: string) { return devStore.getSession(id); }
  getSessions() { return devStore.getSessions(); }
}

// ========== Check-in ==========

class DevStoreCheckInAdapter implements ICheckInRepository {
  checkIn(idempotencyKey: string) { return devStore.checkIn(idempotencyKey); }
  getCheckInForDate(localDate: string) { return devStore.getCheckInForDate(localDate); }
  getOrCreateStreak() { return devStore.getOrCreateStreak(); }
  updateLearningDay(localDate: string) { return devStore.updateLearningDay(localDate); }
  getCheckIns() { return devStore.getCheckIns(); }
  getStreak() { return devStore.getStreak(); }
}

// ========== Today ==========

class DevStoreTodayAdapter implements ITodayRepository {
  getTodayState() { return devStore.getTodayState(); }
  updateTodayState(updates: any) { return devStore.updateTodayState(updates); }
  async updateDailyNewTarget(newTarget: number) { return devStore.updateDailyNewTarget(newTarget); }
}

// ========== Feed ==========

class DevStoreFeedAdapter implements IFeedRepository {
  feedCat(feedItemType: any, idempotencyKey: string) {
    return devStore.feedCat(feedItemType, idempotencyKey);
  }
  getFeedRecords() { return devStore.getFeedRecords(); }
  getTodayFeedCount() { return devStore.getTodayFeedCount(); }
  getTotalExp() { return devStore.getTotalExp(); }
}

// ========== Catalog ==========

class DevStoreCatalogAdapter implements ICatalogRepository {
  getCatalog() { return devStore.getCatalog(); }
  getCatalogItem(itemId: string) { return devStore.getCatalogItem(itemId); }
}

// ========== Inventory ==========

class DevStoreInventoryAdapter implements IInventoryRepository {
  getInventory() { return devStore.getInventory(); }
  isItemOwned(itemId: string) { return devStore.isItemOwned(itemId); }
  getOwnedItems() { return devStore.getOwnedItems(); }
  purchaseItem(itemId: string, idempotencyKey: string) {
    return devStore.purchaseItem(itemId, idempotencyKey);
  }
}

// ========== Equipment ==========

class DevStoreEquipmentAdapter implements IEquipmentRepository {
  getEquippedSnapshot() { return devStore.getEquippedSnapshot(); }
  getEquippedPreview() { return devStore.getEquippedPreview(); }
  equipItem(itemId: string, idempotencyKey: string) {
    return devStore.equipItem(itemId, idempotencyKey);
  }
  unequipItem(itemId: string, idempotencyKey: string) {
    return devStore.unequipItem(itemId, idempotencyKey);
  }
}

// ========== Secondary Summary ==========

class DevStoreSecondarySummaryAdapter implements ISecondarySummaryRepository {
  getSecondarySummary() { return devStore.getSecondarySummary(); }
  getCatSummary() { return devStore.getCatSummary(); }
  getCompanionResponse() { return devStore.getCompanionResponse(); }
}

// ========== Idempotency ==========

class DevStoreIdempotencyAdapter implements IIdempotencyRepository {
  getIdempotencyKey(key: string) { return devStore.getIdempotencyKey(key); }
  setIdempotencyKey(key: string, path: string, response: Record<string, unknown>) {
    devStore.setIdempotencyKey(key, path, response);
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
