import {
  RewardSourceEvent,
  RewardLedgerItem,
  Settlement,
  SourceEventType,
  BalanceSnapshot,
} from '../types';

/**
 * Reward / settlement domain repository interface.
 *
 * 需求 23 Phase A4-α: all user-scoped methods take userId as first param.
 * Owner-check (audit §6) enforced internally — looking up another user's
 * source_event / settlement returns null.
 */
export interface IRewardRepository {
  createOrGetSourceEvent(
    userId: string,
    sourceEventType: SourceEventType,
    sourceRefId: string,
    idempotencyKey: string,
  ): { sourceEvent: RewardSourceEvent; alreadyExists: boolean };

  createSettlement(
    userId: string,
    sourceEventId: string,
    idempotencyKey: string,
  ): { settlement: Settlement; alreadyExists: boolean };

  getSettlementBySourceEventId(userId: string, sourceEventId: string): Settlement | null;
  getSettlement(userId: string, settlementId: string): Settlement | null;

  getBalanceSnapshot(userId: string): BalanceSnapshot;

  getSourceEvents(userId: string): RewardSourceEvent[];
  getSettlements(userId: string): Settlement[];
  getRewardLedgerItems(userId: string): RewardLedgerItem[];
}
