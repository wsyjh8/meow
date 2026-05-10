import {
  DailyFishingTask,
  FishingRoundQuestion,
  DailyFishingStatus,
  FishingAttempt,
  LotteryBox,
} from '../types';

/**
 * Fishing mini-game repository (Phase D).
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 *
 * §3.2 discipline: rewards (fish_treats / lottery boxes) never feed
 * back into learning progress. They are装扮副机制.
 */
export interface IFishingRepository {
  /** Get or create today's fishing task (lazy creation). */
  getDailyFishingTask(userId: string): DailyFishingTask;

  /** Start the next fishing round, or return null if exhausted / no studied words yet. */
  startFishingRound(userId: string): FishingRoundQuestion | null;

  /** Submit the user's choice. Idempotent. Owner-checked. */
  submitFishingAttempt(
    userId: string,
    taskId: string,
    chosenWordId: string,
    idempotencyKey: string,
  ): {
    alreadyExists: boolean;
    attempt: FishingAttempt | null;
    isCorrect: boolean;
    fishWord: { word_id: string; word_text: string; meaning: string } | null;
    fishTreatsEarned: number;
    roundsCompleted: number;
    roundsTotal: number;
    status: DailyFishingStatus;
    boxEarned: boolean;
    boxId: string | null;
  };
}

/**
 * Lottery (blind box) repository (Phase D).
 *
 * 需求 23 Phase A4-α: all methods take userId as first param.
 * Owner-check (audit §6): openLotteryBox throws NotFound if box doesn't
 * belong to userId.
 */
export interface ILotteryRepository {
  /** All unopened lottery boxes for the given user. */
  getLotteryBoxes(userId: string): LotteryBox[];

  /** Open a specific box. Idempotent. Awards coins via reward ledger. */
  openLotteryBox(
    userId: string,
    boxId: string,
    idempotencyKey: string,
  ): {
    alreadyExists: boolean;
    box: LotteryBox | null;
    coinsWon: number;
  };
}
