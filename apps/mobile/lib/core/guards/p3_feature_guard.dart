/// P3 Feature Guard — Phase 0 safety layer.
///
/// All flags default to false. A flag must only be set to true
/// when Room 1 has pinned the corresponding contract as active baseline.
///
/// This is NOT a feature-flag system for users. It is an engineering
/// guardrail to prevent accidental route/render/data-consumption
/// for unpinned P3 candidate contracts.
abstract final class P3FeatureGuard {
  /// Statistics independent page (route + navigation + shell).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isStatisticsPageEnabled = false;

  /// CTA decision-support block (today_primary_action or equivalent).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isCTADecisionSupportEnabled = false;

  /// Streak basis switch (learning_day-based streak).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isStreakBasisSwitchEnabled = false;

  /// Review readiness contract (deeper review_summary / readiness).
  /// Phase 0 guard — do not enable without Room 1 pin.
  static const bool isReviewReadinessContractEnabled = false;

  /// Streak future explanation block (e.g., "rules may change" notice).
  /// Phase 4 guard — do not enable without Room 1 pin of future explanation contract.
  /// When false: no explanation about future streak policy is shown anywhere.
  static const bool isStreakExplanationEnabled = false;

  // ==================== P3.1 — Local Progress + Cloud Backup ====================

  /// P3.1 — Local snapshot export.
  /// When false: no local export functionality is available.
  static const bool isLocalBackupEnabled = false;

  /// P3.1 — Cloud backup upload.
  /// When false: no cloud upload functionality is available.
  /// Note: upload success != sync success. Cloud is backup container, NOT sync endpoint.
  static const bool isCloudBackupEnabled = false;

  /// P3.1 — Restore from backup.
  /// Phase 4: enabled. Restore is gated with pre-check + confirmation dialog.
  static const bool isRestoreEnabled = true;

  /// P3.1 — Backup settings entry (settings/my page visibility).
  /// When false: no backup-related entry point is visible in any navigation.
  static const bool isBackupSettingsEntryEnabled = false;

  // ==================== P3.1 Delta — Download / Manual Upload / Daily Goal ====================

  /// P3.1 Delta Phase 1 — Daily goal setting UI in settings page.
  /// Enabled: user can change daily word count in settings.
  static const bool isDailyGoalSettingEnabled = true;

  /// P3.1 Delta Phase 2 — Manual upload (user-initiated upload progress to cloud).
  /// Enabled: upload button in settings page is functional.
  static const bool isManualUploadEnabled = true;

  /// P3.1 Delta Phase 3 — Download cloud progress to local device.
  /// Enabled: download/restore in settings page is functional.
  static const bool isDownloadToLocalEnabled = true;
}
