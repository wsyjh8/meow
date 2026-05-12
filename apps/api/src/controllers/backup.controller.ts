import {
  Controller,
  Get,
  Post,
  Body,
  UseGuards,
  HttpException,
  HttpStatus,
} from '@nestjs/common';
import { devStore } from '../domain';
import { AuthGuard, RequestUser } from '../auth/auth.guard';
import { CurrentUser } from '../auth/current-user.decorator';

/**
 * P3.1 Phase 3 — Backup controller.
 * P3.2 — Extended with device metadata + persistent storage.
 *
 * Provides cloud backup container endpoints:
 * - POST /me/backup — upload a snapshot (with device_id, device_model)
 * - GET /me/backup/latest — get latest backup metadata
 * - GET /me/backup/latest/snapshot — get full snapshot for restore
 *
 * This is a BACKUP container, NOT a sync system.
 * upload success != sync success.
 *
 * Multi-device conflict policy: last-write-wins.
 * device_id and device_model are informational only — no merge logic.
 *
 * 需求 23 Phase A4-β.2: per-user backup buckets — User A's snapshot is
 * not visible to User B. Was a single global slot in α (P0 leakage,
 * fixed here).
 *
 * 需求 23 Phase D PR-D-β (plan-023-D-v2 §4.2): controller bypasses the
 * dev-store in-memory backup map and reads/writes the
 * `backup_snapshots` PG table directly. The previous flow
 * (storeBackup → saveToDisk(this.userId)) had two bugs:
 *
 *   1. dev-store β.5 lazy-load only restores DEV_USER_ID's slice on
 *      startup. After server restart user B's backup row in PG might
 *      be there, but `backupSnapshotByUser['user-b']` is undefined,
 *      so GET /me/backup/latest/snapshot returned `no_backup_yet`.
 *   2. saveToDisk used `this.userId` (the LAST withUser binding,
 *      typically `dev-user-001`) instead of the storeBackup arg,
 *      so saveAsync's user-filter dropped real-user backups.
 *
 * Going through pg-persistence directly fixes both. The dev-store
 * backup map is kept (for snapshot serialize/hydrate compat) but no
 * longer the truth — the PG row is.
 *
 * 需求 23 Phase E1 PR-E0.2 (plan-023-E1-v2 §3.2, Review 1 P1#1):
 * D-β still called `devStore.storeBackup` UNCONDITIONALLY after the
 * PG write so the in-memory map stayed in sync. That kept the broken
 * side-effect alive: storeBackup → saveToDisk → pg-persistence
 * saveAsync(snapshot, this.userId) where `this.userId` is whatever
 * the last `withUser` binding set (defaults to DEV_USER_ID). That
 * extra saveAsync wrote dev-user-001's slice to PG on every backup
 * upload, polluting prod-shape data.
 *
 * PR-E0.2 moves storeBackup into the JSON-test-backend fallback
 * branch only. Under PG (production / staging / pg-regression e2e)
 * the upload now performs exactly ONE write: `saveBackupForUser`.
 * No more dev-user-001 saveAsync side-effect.
 *
 * Additionally adds server-side `validateSnapshotUserIds` defence
 * (Review 2 P2-1): every `user_id` field embedded in the snapshot
 * MUST match `req.user.id`, otherwise 400 INVALID_SNAPSHOT_USER_ID.
 * Stops a malicious / buggy client from uploading another user's
 * rows into a victim's backup slot.
 */
@Controller('me/backup')
@UseGuards(AuthGuard)
export class BackupController {
  @Post()
  async uploadBackup(@Body() body: any, @CurrentUser() user: RequestUser) {
    const snapshot = body?.snapshot;
    const schemaVersion = body?.schema_version;
    const deviceId = body?.device_id as string | undefined;
    const deviceModel = body?.device_model as string | undefined;

    if (!snapshot || typeof snapshot !== 'object') {
      return {
        status: 'failed',
        error_code: 'INVALID_PAYLOAD',
        message: 'Missing or invalid snapshot payload',
      };
    }

    // PR-D-β defence (plan §4.2 / Review 2 P2-1): refuse snapshots
    // whose embedded user_id fields don't match the bearer token.
    // The mobile client always writes its own bound userId (post
    // PR-C-γ replaceAll* + pending_guest_migrator), so a mismatch
    // means either tampering or a serious client bug. Either way,
    // accepting the payload would let one user write into another's
    // backup slot.
    const foreign = validateSnapshotUserIds(snapshot, user.id);
    if (foreign.length > 0) {
      throw new HttpException(
        {
          error_code: 'INVALID_SNAPSHOT_USER_ID',
          message:
            `snapshot contains user_id values that do not match the ` +
            `authenticated user. Foreign ids: ${[...new Set(foreign)].join(', ')}`,
        },
        HttpStatus.BAD_REQUEST,
      );
    }

    const backupId = `backup-${Date.now()}`;
    const uploadedAt = new Date().toISOString();
    const resolvedSchema = schemaVersion || snapshot.schema_version || 'unknown';
    const snapshotSize = JSON.stringify(snapshot).length;

    // Also extract device info from snapshot body if not provided at top-level
    const resolvedDeviceId =
      deviceId ?? (snapshot.device?.device_id as string | undefined);
    const resolvedDeviceModel =
      deviceModel ?? (snapshot.device?.device_model as string | undefined);

    // PR-D-β: write directly to PG via the persistence adapter.
    // PR-E0.2: split the two backends — PG path is exactly one write,
    // JSON path keeps the legacy dev-store map for in-memory test use.
    const persistence = devStore.backingPersistence;
    if (persistence.saveBackupForUser) {
      // Production path (PG): PG row is the truth. Do NOT also write
      // through devStore.storeBackup — that would trigger saveToDisk
      // → pg-persistence.saveAsync(snapshot, devStore.userId) which
      // pollutes the DEV_USER_ID slice (plan E1 §3.2 / Review 1 P1#1).
      await persistence.saveBackupForUser(user.id, {
        backupId,
        schemaVersion: resolvedSchema,
        uploadedAt,
        snapshotSize,
        deviceId: resolvedDeviceId ?? null,
        deviceModel: resolvedDeviceModel ?? null,
        snapshot,
      });
    } else {
      // JSON test backend has no `saveBackupForUser` implementation.
      // Use the dev-store in-memory map; saveToDisk on JSON backend
      // writes to the dev-store-state.json file (no PG side-effect).
      console.warn(
        '[BackupController] persistence.saveBackupForUser not available; ' +
          'falling back to dev-store in-memory (JSON test backend).',
      );
      devStore.storeBackup(
        user.id,
        backupId,
        resolvedSchema,
        uploadedAt,
        snapshotSize,
        snapshot,
        resolvedDeviceId,
        resolvedDeviceModel,
      );
    }

    return {
      status: 'succeeded',
      backup_id: backupId,
      uploaded_at: uploadedAt,
      schema_version: resolvedSchema,
      device_id: resolvedDeviceId ?? null,
      device_model: resolvedDeviceModel ?? null,
    };
  }

  @Get('latest')
  async getLatestBackup(@CurrentUser() user: RequestUser) {
    // PR-D-β: prefer PG row over dev-store in-memory map. PG is durable
    // across restart AND independent of β.5b lazy-load — user B's
    // metadata is reachable even before any of their other requests
    // hit the server.
    const persistence = devStore.backingPersistence;
    if (persistence.loadBackupMetaForUser) {
      const row = await persistence.loadBackupMetaForUser(user.id);
      if (row) {
        return {
          status: 'available',
          backup_id: row.backupId,
          uploaded_at: row.uploadedAt,
          schema_version: row.schemaVersion,
          snapshot_size: row.snapshotSize,
          device_id: row.deviceId,
          device_model: row.deviceModel,
        };
      }
      return _noBackupYet();
    }

    // JSON test backend: fall back to dev-store in-memory map.
    const meta = devStore.getLatestBackupMeta(user.id);
    return meta ?? _noBackupYet();
  }

  /**
   * P3.1 Phase 4 — Retrieve the full stored snapshot for restore.
   *
   * Returns the complete snapshot JSON that was previously uploaded.
   * This is for RESTORE only — not sync, not merge.
   * Conflict policy: always returns the latest uploaded snapshot (last-write-wins).
   *
   * PR-D-β: reads PG directly, durable across restart, no lazy-load
   * dependency.
   */
  @Get('latest/snapshot')
  async getLatestSnapshot(@CurrentUser() user: RequestUser) {
    const persistence = devStore.backingPersistence;
    if (persistence.loadBackupFullForUser) {
      const row = await persistence.loadBackupFullForUser(user.id);
      if (!row) {
        return {
          status: 'no_backup_found',
          snapshot: null,
        };
      }
      return {
        status: 'available',
        schema_version: row.schemaVersion,
        uploaded_at: row.uploadedAt,
        device_id: row.deviceId,
        device_model: row.deviceModel,
        snapshot: row.snapshot,
      };
    }

    // JSON test backend fallback.
    const snapshot = devStore.getBackupSnapshot(user.id);
    const meta = devStore.getLatestBackupMeta(user.id);
    if (!snapshot || !meta) {
      return {
        status: 'no_backup_found',
        snapshot: null,
      };
    }
    return {
      status: 'available',
      schema_version: meta.schema_version,
      uploaded_at: meta.uploaded_at,
      device_id: meta.device_id ?? null,
      device_model: meta.device_model ?? null,
      snapshot,
    };
  }
}

function _noBackupYet() {
  return {
    status: 'no_backup_yet',
    backup_id: null,
    uploaded_at: null,
    schema_version: null,
    device_id: null,
    device_model: null,
  };
}

/**
 * 需求 23 Phase D PR-D-β (plan §4.3, Review 2 P2-1): walk the snapshot
 * tree and collect every `user_id` value that does NOT match
 * [expectedUserId]. Empty result = clean.
 *
 * Why scan the entire tree rather than checking known paths:
 *   * Mobile v13 snapshot has user_id rows under
 *     `progress.word_records[*]`, `progress.card_states[*]`,
 *     `progress.daily_checkins[*]`, `progress.wordbook_progress`,
 *     `progress.custom_wordbooks[*]`, `progress.vocabulary_notebook[*]`.
 *   * Whitelisting paths means a future schema bump that adds a new
 *     user-scoped entity would silently bypass the check.
 *   * Recursive walk is O(n) on JSON size; for a 1MB typical snapshot
 *     well under 10ms.
 *
 * Note: ignores `device.device_id` (it's a hardware id, not a user_id).
 */
export function validateSnapshotUserIds(
  snapshot: any,
  expectedUserId: string,
): string[] {
  const foreign: string[] = [];

  function walk(node: any) {
    if (node === null || node === undefined) return;
    if (Array.isArray(node)) {
      for (const item of node) walk(item);
      return;
    }
    if (typeof node !== 'object') return;
    for (const [key, value] of Object.entries(node)) {
      if (key === 'user_id' && typeof value === 'string') {
        if (value !== expectedUserId) {
          foreign.push(value);
        }
        continue;
      }
      walk(value);
    }
  }

  walk(snapshot);
  return foreign;
}
