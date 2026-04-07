/// P3.1 Phase 0 — Backup operation semantic types.
///
/// These types enforce strict separation of backup-related success semantics:
/// - local export success != upload success
/// - upload success != sync success (sync is NOT a P3.1 concept)
/// - restore success is independent from both export and upload
/// - has cloud backup != current device has been restored
///
/// This file is TYPE DEFINITIONS ONLY — no implementation, no UI, no logic.
/// Phase 0 guard: types exist for test assertions and future phase seams.

/// The type of backup operation being performed.
/// Each value represents a semantically distinct operation with its own success criteria.
enum BackupOperationType {
  /// Local snapshot export — device-side only, no network involved.
  localExport,

  /// Cloud upload — sending a local snapshot to the cloud backup container.
  /// upload success != sync success. Cloud is a backup container, not a sync endpoint.
  cloudUpload,

  /// Restore — downloading and applying a backup to the current device.
  /// restore success is independent from export success and upload success.
  restore,

  /// P3.1 Delta — Download cloud progress to local device (fetch only).
  /// download completed != restore success (download fetches, restore applies/overwrites).
  /// download completed != upload success (opposite direction).
  /// download completed != sync success (sync is NOT a P3.1 concept).
  downloadToLocal,
}

/// The status of a backup operation.
/// Used for strict state tracking — each operation has its own independent status.
enum BackupOperationStatus {
  /// Operation has not been initiated.
  notStarted,

  /// Operation is currently in progress.
  inProgress,

  /// Operation completed successfully.
  succeeded,

  /// Operation failed.
  failed,
}

/// P3.1 Delta — Status of a download-to-local operation.
/// These are DOWNLOAD states — not restore, not upload, not sync.
///
/// download completed != restore completed
/// download completed != all devices consistent
/// download completed != sync succeeded
enum DownloadToLocalStatus {
  /// No download has been attempted.
  notAttempted,

  /// Download is currently in progress.
  downloading,

  /// Download completed successfully — data fetched to local.
  /// This does NOT mean restore succeeded or data was applied.
  downloadCompleted,

  /// Download failed.
  downloadFailed,

  /// Service temporarily unavailable.
  temporarilyUnavailable,
}
