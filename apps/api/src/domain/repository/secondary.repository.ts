import {
  FeedItemType,
  FeedResultStatus,
  FeedRecord,
  CatSummary,
  SecondarySummary,
  CompanionResponse,
  CatalogItem,
  OwnedItem,
  InventoryState,
  EquippedSnapshot,
  PurchaseResultStatus,
  PurchaseErrorCode,
  EquipResultStatus,
  EquipErrorCode,
} from '../types';

/**
 * Feed / pet-state repository interface.
 *
 * 需求 23 Phase A4-α: user-scoped methods take userId as first param.
 */
export interface IFeedRepository {
  feedCat(
    userId: string,
    feedItemType: FeedItemType,
    idempotencyKey: string,
  ): {
    status: FeedResultStatus;
    feedRecord: FeedRecord | null;
    alreadyExists: boolean;
    leveledUp: boolean;
    previousLevel: number;
    currentLevel: number;
  };

  getFeedRecords(userId: string): FeedRecord[];
  getTodayFeedCount(userId: string): number;
  getTotalExp(userId: string): number;
}

/**
 * Catalog repository interface.
 *
 * Catalog is shared / public content — methods do NOT take userId.
 */
export interface ICatalogRepository {
  getCatalog(): CatalogItem[];
  getCatalogItem(itemId: string): CatalogItem | null;
}

/**
 * Inventory / purchase repository interface.
 *
 * 需求 23 Phase A4-α: user-scoped methods take userId as first param.
 * Owner-check (audit §6): purchaseItem internally writes to current user's
 * inventory only. Items in catalog are shared (no owner).
 */
export interface IInventoryRepository {
  getInventory(userId: string): InventoryState;
  isItemOwned(userId: string, itemId: string): boolean;
  getOwnedItems(userId: string): OwnedItem[];

  purchaseItem(
    userId: string,
    itemId: string,
    idempotencyKey: string,
  ): {
    status: PurchaseResultStatus;
    errorCode: PurchaseErrorCode | null;
    coinsSpent: number;
    alreadyExists: boolean;
  };
}

/**
 * Equipment repository interface.
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 * Owner-check (audit §6): equip / unequip verifies inventory_items.user_id.
 */
export interface IEquipmentRepository {
  getEquippedSnapshot(userId: string): EquippedSnapshot;
  getEquippedPreview(userId: string): Record<string, string | null>;

  equipItem(
    userId: string,
    itemId: string,
    idempotencyKey: string,
  ): {
    status: EquipResultStatus;
    errorCode: EquipErrorCode | null;
    slot: string | null;
    itemType: string | null;
    alreadyExists: boolean;
  };

  unequipItem(
    userId: string,
    itemId: string,
    idempotencyKey: string,
  ): {
    status: EquipResultStatus;
    errorCode: EquipErrorCode | null;
    alreadyExists: boolean;
  };
}

/**
 * Secondary summary read model repository.
 * Aggregates cat summary, companion response, balances, equipped preview.
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 */
export interface ISecondarySummaryRepository {
  getSecondarySummary(userId: string): SecondarySummary;
  getCatSummary(userId: string): CatSummary;
  getCompanionResponse(userId: string): CompanionResponse;
}
