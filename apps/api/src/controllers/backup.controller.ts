import { Controller, Get, Post, Body } from '@nestjs/common';
import { devStore } from '../domain';

/**
 * P3.1 Phase 3 — Backup controller.
 *
 * Provides cloud backup container endpoints:
 * - POST /me/backup — upload a snapshot
 * - GET /me/backup/latest — get latest backup status
 *
 * This is a BACKUP container, NOT a sync system.
 * upload success != sync success.
 */
@Controller('me/backup')
export class BackupController {
  @Post()
  uploadBackup(@Body() body: any) {
    const snapshot = body?.snapshot;
    const schemaVersion = body?.schema_version;

    if (!snapshot || typeof snapshot !== 'object') {
      return {
        status: 'failed',
        error_code: 'INVALID_PAYLOAD',
        message: 'Missing or invalid snapshot payload',
      };
    }

    // Store the backup in memory (devStore pattern)
    const backupId = `backup-${Date.now()}`;
    const uploadedAt = new Date().toISOString();

    // Save to devStore's backup storage
    (devStore as any)._latestBackup = {
      backup_id: backupId,
      schema_version: schemaVersion || snapshot.schema_version || 'unknown',
      uploaded_at: uploadedAt,
      snapshot_size: JSON.stringify(snapshot).length,
      status: 'succeeded',
    };
    (devStore as any)._backupSnapshot = snapshot;

    return {
      status: 'succeeded',
      backup_id: backupId,
      uploaded_at: uploadedAt,
      schema_version: schemaVersion || snapshot.schema_version || 'unknown',
    };
  }

  @Get('latest')
  getLatestBackup() {
    const latest = (devStore as any)._latestBackup;

    if (!latest) {
      return {
        status: 'no_backup_yet',
        backup_id: null,
        uploaded_at: null,
        schema_version: null,
      };
    }

    return latest;
  }

  /**
   * P3.1 Phase 4 — Retrieve the full stored snapshot for restore.
   *
   * Returns the complete snapshot JSON that was previously uploaded.
   * This is for RESTORE only — not sync, not merge.
   */
  @Get('latest/snapshot')
  getLatestSnapshot() {
    const snapshot = (devStore as any)._backupSnapshot;
    const metadata = (devStore as any)._latestBackup;

    if (!snapshot || !metadata) {
      return {
        status: 'no_backup_found',
        snapshot: null,
      };
    }

    return {
      status: 'available',
      schema_version: metadata.schema_version,
      uploaded_at: metadata.uploaded_at,
      snapshot,
    };
  }
}
