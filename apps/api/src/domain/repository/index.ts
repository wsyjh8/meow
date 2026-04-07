/**
 * Repository interfaces index.
 *
 * These interfaces define the persistence contract for all domains.
 * Current implementation: DevStoreAdapter (JSON-backed via DevStore).
 * Future implementation: PostgreSQL repositories (A2+).
 */

export type { IStudyRepository } from './study.repository';
export type { IReviewRepository } from './review.repository';
export type { IRewardRepository } from './reward.repository';
export type { ISessionRepository } from './session.repository';
export type { ICheckInRepository } from './checkin.repository';
export type { ITodayRepository } from './today.repository';
export type {
  IFeedRepository,
  ICatalogRepository,
  IInventoryRepository,
  IEquipmentRepository,
  ISecondarySummaryRepository,
} from './secondary.repository';
export type { IIdempotencyRepository } from './idempotency.repository';
