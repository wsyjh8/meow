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
 * Covers daily fishing task lifecycle: get task status, start a round,
 * submit a guess. Daily reset uses Beijing time (UTC+8) at 05:00.
 *
 * §3.2 discipline: rewards (fish_treats / lottery boxes) never feed
 * back into learning progress. They are装扮副机制.
 */
export interface IFishingRepository {
  /** Get or create today's fishing task (lazy creation). */
  getDailyFishingTask(): DailyFishingTask;

  /** Start the next fishing round, or return null if exhausted / no studied words yet. */
  startFishingRound(): FishingRoundQuestion | null;

  /** Submit the user's choice. Idempotent. */
  submitFishingAttempt(
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
 * Boxes are earned by completing all 3 fishing rounds in one day.
 * Opening a box draws a coin reward via weighted random.
 */
export interface ILotteryRepository {
  /** All unopened lottery boxes for current user. */
  getLotteryBoxes(): LotteryBox[];

  /** Open a specific box. Idempotent. Awards coins via reward ledger. */
  openLotteryBox(
    boxId: string,
    idempotencyKey: string,
  ): {
    alreadyExists: boolean;
    box: LotteryBox | null;
    coinsWon: number;
  };
}
