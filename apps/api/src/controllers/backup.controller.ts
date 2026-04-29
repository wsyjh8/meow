import { Controller, Get, Post, Body } from '@nestjs/common';
import { devStore, repositories } from '../domain';

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
 */
@Controller('me/backup')
export class BackupController {
  @Post()
  async uploadBackup(@Body() body: any) {
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

    const backupId = `backup-${Date.now()}`;
    const uploadedAt = new Date().toISOString();
    const resolvedSchema = schemaVersion || snapshot.schema_version || 'unknown';
    const snapshotSize = JSON.stringify(snapshot).length;

    // Also extract device info from snapshot body if not provided at top-level
    const resolvedDeviceId = deviceId ?? (snapshot.device?.device_id as string | undefined);
    const resolvedDeviceModel = deviceModel ?? (snapshot.device?.device_model as string | undefined);

    // Persist via devStore (survives server restart)
    devStore.storeBackup(
      backupId,
      resolvedSchema,
      uploadedAt,
      snapshotSize,
      snapshot,
      resolvedDeviceId,
      resolvedDeviceModel,
    );

    await repositories.ensurePersisted();

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
  getLatestBackup() {
    const meta = devStore.getLatestBackupMeta();

    if (!meta) {
      return {
        status: 'no_backup_yet',
        backup_id: null,
        uploaded_at: null,
        schema_version: null,
        device_id: null,
        device_model: null,
      };
    }

    return meta;
  }

  /**
   * P3.1 Phase 4 — Retrieve the full stored snapshot for restore.
   *
   * Returns the complete snapshot JSON that was previously uploaded.
   * This is for RESTORE only — not sync, not merge.
   * Conflict policy: always returns the latest uploaded snapshot (last-write-wins).
   */
  @Get('latest/snapshot')
  getLatestSnapshot() {
    const snapshot = devStore.getBackupSnapshot();
    const meta = devStore.getLatestBackupMeta();

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
