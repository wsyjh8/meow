/// backup_restore_semantic_contract_v1 (FROZEN, P3.3.5)
///
/// This file is a CONTRACT ANCHOR — it captures Room 1's pinned decisions
/// about the three-layer backup / restore / sync semantic boundary.
/// It does not run code; it only exposes constants for tests and for
/// other files to reference as the single source of truth.
///
/// ============================================================================
/// Three-layer separation (RF-P3.3.5-013)
/// ============================================================================
///
///   LAYER 1 — backup_success:
///     Current device local runtime truth has been successfully exported
///     and uploaded as a cloud snapshot artifact.
///     Scope: SOURCE device only.
///     Does NOT imply:
///       - other devices are updated
///       - state consistency across devices
///       - target device runtime changed
///       - sync is active
///
///   LAYER 2 — restore_success:
///     Target device has successfully applied a downloaded snapshot,
///     rewriting that device's local planner / local runtime state.
///     Scope: TARGET device only (the device that called restore).
///     Does NOT imply:
///       - other devices are updated
///       - the snapshot is fresh
///       - sync is active
///       - multi-device consistency guaranteed
///
///   LAYER 3 — sync_success:
///     NOT a valid user-facing state in this round.
///     The current regime is manual-backup-only. No real-time sync.
///     No auto merge. No auto recovery.
///     "sync_success" MUST NOT appear as a state, status label, or
///     copy string in any user-facing surface.
///
/// ============================================================================
/// Related frozen rules
/// ============================================================================
///
/// RF-P3.3.5-012: cloud backup rebase only changes cloud's role in
///                review-planning (future target-state candidate);
///                it does NOT change the manual-only / no-real-time-sync /
///                no-auto-merge principle.
///
/// RF-P3.3.5-014: multi-device inconsistency remains a manual restore
///                boundary problem — NOT automatically resolved by
///                backup existence.
///
/// ============================================================================
/// Forbidden copy (must never appear in UI)
/// ============================================================================
///
///   - 已同步
///   - 云端与本地已统一
///   - 跨设备已一致
///   - 无冲突
///   - 恢复后所有设备自动更新
///   - 现在所有设备的学习计划都一样
///   - backup 成功 = 其他设备已更新
///   - restore success = sync success
abstract final class BackupRestoreSemantics {
  /// Layer 1 scope — source device only.
  /// A successful backup upload affects only the device that initiated it.
  static const String kBackupSuccessScope = 'source_device_only';

  /// Layer 2 scope — target device only.
  /// A successful restore rewrites only the device that applied it.
  static const String kRestoreSuccessScope = 'target_device_only';

  /// Layer 3 — sync_success is NOT a valid user-facing state this round.
  /// This flag exists so tests can lock in the decision and any future
  /// attempt to flip it to true requires an explicit Room 1 pin.
  static const bool kSyncSuccessIsValidState = false;

  /// Forbidden cross-device claim phrases.
  /// Tests assert none of these appear in any visible UI copy.
  static const List<String> kForbiddenCrossDeviceClaims = [
    '已同步',
    '云端与本地已统一',
    '跨设备已一致',
    '无冲突',
    '恢复后所有设备自动更新',
    '现在所有设备的学习计划都一样',
  ];

  /// Allowed backup / restore copy phrases per UI_SPEC P3.3.5 preflight Q8.4.
  /// These are the only "reference phrasings" Room 5 has preflighted for
  /// this round. Other wordings remain allowed as long as they do not
  /// cross the forbidden zone.
  static const List<String> kAllowedBackupCopy = [
    '立即备份',
    '最近一次备份时间',
    '最近一次备份状态',
    '从备份恢复',
    '恢复将覆盖本机当前本地进度',
  ];
}
