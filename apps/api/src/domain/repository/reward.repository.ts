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
 * Covers: source events, reward ledger, settlements, balance computation.
 */
export interface IRewardRepository {
  createOrGetSourceEvent(
    sourceEventType: SourceEventType,
    sourceRefId: string,
    idempotencyKey: string,
  ): { sourceEvent: RewardSourceEvent; alreadyExists: boolean };

  createSettlement(
    sourceEventId: string,
    idempotencyKey: string,
  ): { settlement: Settlement; alreadyExists: boolean };

  getSettlementBySourceEventId(sourceEventId: string): Settlement | null;
  getSettlement(settlementId: string): Settlement | null;

  getBalanceSnapshot(): BalanceSnapshot;

  getSourceEvents(): RewardSourceEvent[];
  getSettlements(): Settlement[];
  getRewardLedgerItems(): RewardLedgerItem[];
}
