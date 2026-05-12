/**
 * File-backed persistence adapter for DevStore (Phase 4).
 *
 * Provides load/save/reset for the in-memory DevStore state.
 * Uses atomic write (write to .tmp then rename) for safety.
 *
 * Assumption (temporary, not frozen):
 * - This is a minimal MVP file-backed persistence, not a production database.
 * - Single-user, single-process, no concurrent write handling.
 * - Suitable for dev/demo; production requires a real DB.
 */

import * as fs from 'fs';
import * as path from 'path';

/**
 * Persistence adapter interface.
 * Any backend (JSON file, PostgreSQL, etc.) must implement this.
 *
 * 需求 23 Phase A4-β.5: load/save/clear accept an optional userId.
 *   - PG backend uses it to scope queries (load only that user's data,
 *     save only that user's slice).
 *   - JSON backend ignores it (single-file dev fallback).
 * Default param is DEV_USER_ID for back-compat with single-user dev mode.
 */
export interface IDevStorePersistence {
  load(): DevStoreSnapshot | null;
  save(snapshot: DevStoreSnapshot): void;
  /** Async save — returns a promise that rejects if persistence fails. */
  saveAsync?(snapshot: DevStoreSnapshot, userId?: string): Promise<void>;
  /** Async load (PG only) — loads a single user's snapshot. */
  loadAsync?(userId?: string): Promise<DevStoreSnapshot | null>;
  clear(userId?: string): void;

  // ============================================================
  // 需求 23 Phase D PR-D-β: backup snapshot persistence (PG only).
  //
  // These methods are independent of saveAsync/loadAsync so backup
  // cross-user reads work after server restart without depending
  // on dev-store in-memory lazy-load (β.5b deferred).
  //
  // Optional in the interface so the JSON backend (test/emergency
  // only) doesn't have to implement them — BackupController guards
  // with `if (persistence.saveBackupForUser)` and throws a clear
  // error in JSON mode.
  // ============================================================
  saveBackupForUser?(
    userId: string,
    meta: BackupSnapshotMeta,
  ): Promise<void>;
  loadBackupMetaForUser?(
    userId: string,
  ): Promise<BackupSnapshotMetaRow | null>;
  loadBackupFullForUser?(
    userId: string,
  ): Promise<BackupSnapshotFullRow | null>;
  clearBackupForUser?(userId: string): Promise<void>;
}

/// Payload BackupController hands to [IDevStorePersistence.saveBackupForUser].
export interface BackupSnapshotMeta {
  backupId: string;
  schemaVersion: string;
  uploadedAt: string;
  snapshotSize: number;
  deviceId?: string | null;
  deviceModel?: string | null;
  snapshot: unknown;
}

/// Shape returned by [IDevStorePersistence.loadBackupMetaForUser].
export interface BackupSnapshotMetaRow {
  backupId: string;
  schemaVersion: string;
  uploadedAt: string;
  snapshotSize: number;
  deviceId: string | null;
  deviceModel: string | null;
}

/// Shape returned by [IDevStorePersistence.loadBackupFullForUser]
/// (meta + full snapshot body).
export interface BackupSnapshotFullRow extends BackupSnapshotMetaRow {
  snapshot: unknown;
}

export interface DevStoreSnapshot {
  // Main mechanism state
  studyAttempts: any[];
  reviewGroups: any[];
  reviewAttempts: any[];
  sourceEvents: any[];
  rewardLedgerItems: any[];
  settlements: any[];
  sessions: any[];
  checkIns: any[];
  streakRecord: any | null;
  learningDays: any[];
  todayStates: Record<string, any>;

  // P2 secondary mechanism state
  feedRecords: any[];
  feedMoodAccumulated: number;
  feedExpAccumulated: number;
  feedBondAccumulated: number;
  ownedItems: any[];
  coinsSpent: number;
  equippedOutfit: Record<string, string | null>;
  equippedRoom: Record<string, string | null>;

  // Idempotency keys
  idempotencyKeys: Record<string, any>;

  // P3.2 Backup persistence
  // α: single global slot fields (kept here for backward-compat hydration of
  // pre-β.2 snapshots — old data gets migrated into the dev-user-001 bucket).
  // β.2+: per-user records, keyed by userId.
  latestBackup?: any | null;          // legacy single slot — read-only after β.2
  backupSnapshot?: any | null;        // legacy single slot — read-only after β.2
  latestBackupsByUser?: Record<string, any>;
  backupSnapshotsByUser?: Record<string, any>;

  // Phase D: Fishing + Lottery — optional for backward compat
  fishingTasks?: Record<string, any>;
  fishingAttempts?: any[];
  lotteryBoxes?: any[];
}

const DEFAULT_PERSIST_DIR = path.resolve(__dirname, '..', '..', 'data');
const DEFAULT_PERSIST_FILENAME = 'dev-store-state.json';

export class DevStorePersistence implements IDevStorePersistence {
  private filePath: string;

  constructor(filePath?: string) {
    if (filePath) {
      this.filePath = filePath;
    } else {
      const dir = process.env.DEV_STORE_PERSIST_DIR || DEFAULT_PERSIST_DIR;
      const filename = process.env.DEV_STORE_PERSIST_FILENAME || DEFAULT_PERSIST_FILENAME;
      this.filePath = path.join(dir, filename);
    }
  }

  /**
   * Load state from file. Returns null if file doesn't exist.
   */
  load(): DevStoreSnapshot | null {
    try {
      if (!fs.existsSync(this.filePath)) {
        return null;
      }
      const raw = fs.readFileSync(this.filePath, 'utf-8');
      return JSON.parse(raw) as DevStoreSnapshot;
    } catch (err) {
      console.warn(`[Persistence] Failed to load state from ${this.filePath}:`, err);
      return null;
    }
  }

  /**
   * Save state to file. Uses atomic write (tmp + rename).
   */
  save(snapshot: DevStoreSnapshot): void {
    try {
      const dir = path.dirname(this.filePath);
      if (!fs.existsSync(dir)) {
        fs.mkdirSync(dir, { recursive: true });
      }
      const tmpPath = this.filePath + '.tmp';
      fs.writeFileSync(tmpPath, JSON.stringify(snapshot, null, 2), 'utf-8');
      fs.renameSync(tmpPath, this.filePath);
    } catch (err) {
      console.warn(`[Persistence] Failed to save state to ${this.filePath}:`, err);
    }
  }

  /**
   * Delete persisted state file.
   */
  clear(): void {
    try {
      if (fs.existsSync(this.filePath)) {
        fs.unlinkSync(this.filePath);
      }
      const tmpPath = this.filePath + '.tmp';
      if (fs.existsSync(tmpPath)) {
        fs.unlinkSync(tmpPath);
      }
    } catch (err) {
      console.warn(`[Persistence] Failed to clear state file:`, err);
    }
  }

  getFilePath(): string {
    return this.filePath;
  }
}
