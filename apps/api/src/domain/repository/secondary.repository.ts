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
 */
export interface IFeedRepository {
  feedCat(
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

  getFeedRecords(): FeedRecord[];
  getTodayFeedCount(): number;
  getTotalExp(): number;
}

/**
 * Catalog repository interface.
 */
export interface ICatalogRepository {
  getCatalog(): CatalogItem[];
  getCatalogItem(itemId: string): CatalogItem | null;
}

/**
 * Inventory / purchase repository interface.
 */
export interface IInventoryRepository {
  getInventory(): InventoryState;
  isItemOwned(itemId: string): boolean;
  getOwnedItems(): OwnedItem[];

  purchaseItem(
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
 */
export interface IEquipmentRepository {
  getEquippedSnapshot(): EquippedSnapshot;
  getEquippedPreview(): Record<string, string | null>;

  equipItem(
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
 */
export interface ISecondarySummaryRepository {
  getSecondarySummary(): SecondarySummary;
  getCatSummary(): CatSummary;
  getCompanionResponse(): CompanionResponse;
}
