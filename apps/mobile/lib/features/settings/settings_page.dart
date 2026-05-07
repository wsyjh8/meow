import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/api/api_client.dart';
import '../../core/storage/local_settings_service.dart';
import '../../core/storage/local_progress_repository.dart';
import '../../core/storage/snapshot_export_service.dart';
import '../../core/storage/backup_upload_service.dart';
import '../../core/storage/backup_restore_service.dart';
import '../../core/storage/local_database.dart';
import '../../core/device/device_info_service.dart';
import '../../core/guards/p3_feature_guard.dart';
import '../../core/services/enrichment_bootstrap.dart';
import '../debug/review_history_debug_page.dart';
import '../../shared/theme.dart';
import '../../shared/widgets/meow_card.dart';
import '../../shared/widgets/meow_chip.dart';

/// P3.1 Phase 3 — Minimal settings page with backup entry.
///
/// This is NOT a full backup center. It provides:
/// - "立即备份" button
/// - Latest backup status display (with device info)
/// - Retry on failure
/// - Restore from backup (P3.1 Phase 4, gated by feature flag)
///
/// It does NOT provide:
/// - Delete backup
/// - Clear local data
/// - Sync controls
///
/// backup_restore_semantic_contract_v1 (FROZEN, P3.3.5):
///   Three-layer separation enforced:
///     Layer 1 — backup_success:  source device only, NOT cross-device
///     Layer 2 — restore_success: target device only, NOT cross-device
///     Layer 3 — sync_success:    NOT a valid user-facing state this round
///
///   MUST NOT display:
///     "已同步" / "云端与本地已统一" / "跨设备已一致" /
///     "恢复后所有设备自动更新" / "无需担心冲突" / "无冲突" /
///     "现在所有设备的学习计划都一样"
///
///   See `lib/core/backup/backup_restore_semantics.dart` for the full
///   forbidden list and frozen rule references (RF-P3.3.5-012/013/014).
///
/// Multi-device conflict policy: last-write-wins.
/// device_id + device_model are informational only.
class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  BackupUploadStatus _backupStatus = BackupUploadStatus.noBackupYet;
  String? _lastBackupTime;
  bool _isUploading = false;
  String? _error;

  // Device info (loaded async in initState)
  String? _deviceId;
  String? _deviceModel;

  // PR-B3 Day 3: manifest sync feature flag (debug-only switch).
  bool _manifestSyncEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadLatestStatus();
    _loadDeviceInfo();
    _loadManifestSyncFlag();
  }

  Future<void> _loadLatestStatus() async {
    final prefs = await SharedPreferences.getInstance();
    final uploadService = BackupUploadService(
      baseUrl: 'http://10.0.2.2:3000/api/v1',
      prefs: prefs,
    );
    final info = uploadService.getLatestBackupInfo();
    if (mounted) {
      setState(() {
        _backupStatus = info.status;
        _lastBackupTime = info.uploadedAt;
      });
    }
  }

  Future<void> _loadDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    final deviceInfo = DeviceInfoService();
    final id = await deviceInfo.getDeviceId(prefs);
    final model = await deviceInfo.getDeviceModel();
    if (mounted) {
      setState(() {
        _deviceId = id;
        _deviceModel = model;
      });
    }
  }

  // ===== PR-B3 manifest sync flag (Day 3 debug-only switch) =====
  // Sync uses the same `await SharedPreferences.getInstance() +
  // LocalSettingsService(prefs)` pattern the rest of this page already
  // follows (see _loadDeviceInfo / _performBackup), avoiding the need
  // for an InheritedWidget DI scaffold.
  Future<void> _loadManifestSyncFlag() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() {
        _manifestSyncEnabled =
            LocalSettingsService(prefs).manifestSyncEnabled;
      });
    }
  }

  Future<void> _setManifestSyncFlag(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await LocalSettingsService(prefs).setManifestSyncEnabled(value);
    if (mounted) setState(() => _manifestSyncEnabled = value);
  }

  Future<void> _performBackup() async {
    if (_isUploading) return;
    setState(() { _isUploading = true; _error = null; });

    try {
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);
      final progress = LocalProgressRepository(prefs);
      final deviceInfo = DeviceInfoService();

      final exportService = SnapshotExportService(
        settings: settings,
        progress: progress,
        db: LocalDatabase.instance,
        deviceInfo: deviceInfo,
        prefs: prefs,
      );
      final uploadService = BackupUploadService(
        baseUrl: 'http://10.0.2.2:3000/api/v1',
        prefs: prefs,
      );

      // Step 1: Export snapshot locally (async — reads SQLite + drift + device_info)
      final exportResult = await exportService.export();
      if (!exportResult.isSuccess) {
        setState(() {
          _error = '导出失败';
          _isUploading = false;
        });
        return;
      }

      // Step 2: Upload to cloud backup container
      final uploadResult = await uploadService.upload(exportResult);

      if (mounted) {
        setState(() {
          _backupStatus = uploadResult.status;
          _lastBackupTime = uploadResult.uploadedAt;
          _isUploading = false;
          _error = uploadResult.isSuccess ? null : (uploadResult.errorCode ?? 'UNKNOWN');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(uploadResult.isSuccess
                ? '备份成功'
                : '备份失败，可重试',
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = e.toString();
          _isUploading = false;
          _backupStatus = BackupUploadStatus.uploadFailed;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: MeowColors.background,
      appBar: AppBar(title: const Text('设置')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(MeowSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ===== Daily Goal Setting (P3.1 Delta Phase 1) =====
            if (P3FeatureGuard.isDailyGoalSettingEnabled)
              _buildDailyGoalSection(),

            // ===== FSRS Memory Settings =====
            _buildRetentionSection(),

            // ===== Backup Section =====
            _buildBackupSection(),

            // ===== Debug: review history (Need #10) =====
            const SizedBox(height: MeowSpacing.md),
            _buildDebugSection(context),
          ],
        ),
      ),
    );
  }

  Widget _buildDebugSection(BuildContext context) {
    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🔧', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('调试', style: MeowTextStyles.label),
            ],
          ),
          const SizedBox(height: MeowSpacing.md),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.history),
            title: const Text('复习历史'),
            subtitle: const Text('按 word_id 查看云端 + 本地复习记录'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const ReviewHistoryDebugPage(),
                ),
              );
            },
          ),
          ListTile(
            dense: true,
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.cloud_download_outlined),
            title: const Text('重新导入增强数据'),
            subtitle: const Text(
              '从内置 SQLite seed 文件重新填充三张表（恢复用，通常不需要）',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _runEnrichmentImport(context),
          ),
          // PR-B3 Day 3 v0.2: manifest sync debug switch (kDebugMode-only).
          // Existing debug ListTiles ("复习历史" / "重新导入增强数据") keep
          // their pre-PR-B3 release visibility; only this new switch is
          // hidden in release builds. Recon confirmed _buildDebugSection's
          // call site (line 188) has no outer kDebugMode guard, so this
          // local guard is not redundant (v0.2 #10 R1#8 review-adopted).
          if (kDebugMode)
            SwitchListTile(
              dense: true,
              contentPadding: EdgeInsets.zero,
              secondary: const Icon(Icons.cloud_sync_outlined),
              title: const Text('Manifest sync (PR-B3 dev)'),
              subtitle: const Text('开/关后下次重启 App 生效。失败静默。'),
              value: _manifestSyncEnabled,
              onChanged: _setManifestSyncFlag,
            ),
        ],
      ),
    );
  }

  /// Need #11 — Debug import flow. Wipes existing enrichment rows and
  /// re-imports from `assets/forms/*.jsonl`. Shows a simple progress
  /// dialog so the user can tell ~70K relation rows aren't silently
  /// stalled. Result snackbar reports per-table totals.
  Future<void> _runEnrichmentImport(BuildContext context) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('重新导入增强数据？'),
        content: const Text(
          '将清空本地 word_forms / word_relations / word_phrases 三张表，'
          '从 APK 内置的 SQLite seed 文件重新填充。'
          '\n\n通常在 1 秒内完成。',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('取消'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('开始导入'),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    // Show an indeterminate spinner — the seed copy is sub-second on
    // real hardware, so per-table progress would just flash by.
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const AlertDialog(
        title: Text('正在导入增强数据'),
        content: SizedBox(
          height: 24,
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2.5),
            ),
          ),
        ),
      ),
    );

    Object? error;
    try {
      await EnrichmentBootstrap().forceReseed();
    } catch (e) {
      error = e;
    }

    if (!context.mounted) return;
    Navigator.of(context).pop(); // dismiss progress dialog

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('导入失败：$error')),
      );
      return;
    }
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('导入完成'),
        duration: Duration(seconds: 2),
      ),
    );
  }

  Widget _buildBackupSection() {
    return MeowCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              const Text('💾', style: TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text('数据备份', style: MeowTextStyles.label),
            ],
          ),
          const SizedBox(height: MeowSpacing.md),

          // Device info row (informational)
          _buildDeviceInfoRow(),
          const SizedBox(height: MeowSpacing.sm),

          // Latest backup status
          _buildLatestStatus(),
          const SizedBox(height: MeowSpacing.md),

          // Backup button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              key: const Key('settings-backup-button'),
              onPressed: _isUploading ? null : _performBackup,
              child: Text(_isUploading
                  ? '备份中...'
                  : _backupStatus == BackupUploadStatus.uploadFailed
                      ? '重试备份'
                      : '立即备份',
              ),
            ),
          ),

          // Error message
          if (_error != null) ...[
            const SizedBox(height: MeowSpacing.sm),
            Text(
              '备份失败: $_error',
              style: MeowTextStyles.caption.copyWith(color: MeowColors.error),
            ),
          ],

          // Note: not sync.
          // backup_restore_semantic_contract_v1 (FROZEN, P3.3.5):
          //   Layer 1 backup_success is SOURCE-device only. The note must
          //   explicitly disclaim real-time sync AND cross-device consistency.
          const SizedBox(height: MeowSpacing.sm),
          Text(
            '备份会将当前进度保存到云端，不是实时同步，也不代表其他设备自动一致',
            style: MeowTextStyles.caption.copyWith(color: MeowColors.textHint),
          ),

          // P3.1 Phase 4: Restore section (gated)
          if (P3FeatureGuard.isRestoreEnabled) ...[
            const Divider(height: MeowSpacing.xxl),
            _buildRestoreSection(),
          ],
        ],
      ),
    );
  }

  Widget _buildDeviceInfoRow() {
    final shortId = _deviceId != null && _deviceId!.length >= 8
        ? '…${_deviceId!.substring(_deviceId!.length - 8)}'
        : (_deviceId ?? '加载中…');
    final model = _deviceModel ?? '加载中…';

    return Row(
      children: [
        const Text('📱', style: TextStyle(fontSize: 14)),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            '设备: $model · ID: $shortId',
            style: MeowTextStyles.caption.copyWith(color: MeowColors.textSecondary),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  // ==================== Restore Section (P3.1 Phase 4) ====================

  bool _isRestoring = false;

  Widget _buildRestoreSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('🔄', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 8),
            Text('恢复备份', style: MeowTextStyles.label),
          ],
        ),
        const SizedBox(height: MeowSpacing.sm),
        Text(
          '从云端备份恢复数据到当前设备',
          style: MeowTextStyles.caption.copyWith(color: MeowColors.textSecondary),
        ),
        const SizedBox(height: MeowSpacing.md),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            key: const Key('settings-restore-button'),
            onPressed: _isRestoring ? null : _handleRestore,
            style: OutlinedButton.styleFrom(
              foregroundColor: MeowColors.warning,
              side: BorderSide(color: MeowColors.warning.withValues(alpha: 0.5)),
            ),
            child: Text(_isRestoring ? '恢复中...' : '恢复备份'),
          ),
        ),
      ],
    );
  }

  Future<void> _handleRestore() async {
    final prefs = await SharedPreferences.getInstance();
    final settings = LocalSettingsService(prefs);
    final progress = LocalProgressRepository(prefs);
    final restoreService = BackupRestoreService(
      baseUrl: 'http://10.0.2.2:3000/api/v1',
      settings: settings,
      progress: progress,
      db: LocalDatabase.instance,
    );

    // Pre-check
    final preCheck = await restoreService.preCheck();
    if (!mounted) return;

    if (!preCheck.isRestorable) {
      String msg;
      switch (preCheck.status) {
        case RestorePreCheckStatus.noBackupFound:
          msg = '没有可恢复的备份';
          break;
        case RestorePreCheckStatus.versionNotSupported:
          msg = '备份版本暂不支持恢复';
          break;
        default:
          msg = '服务暂不可用，请稍后再试';
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));
      return;
    }

    // Show source device info in confirmation dialog (if available)
    final sourceDevice = preCheck.deviceModel != null
        ? '来自设备: ${preCheck.deviceModel}'
        : '';
    final sourceId = preCheck.deviceId != null && preCheck.deviceId!.length >= 8
        ? '设备ID: …${preCheck.deviceId!.substring(preCheck.deviceId!.length - 8)}'
        : '';

    // Confirmation dialog — HIGH RISK action
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('确认恢复'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (sourceDevice.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  '$sourceDevice\n$sourceId',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ),
            const Text(
              '将使用最近一次云端备份恢复当前设备数据。\n\n'
              '• 这可能覆盖当前设备上的本地学习进度\n'
              '• 也可能覆盖设置项（如每日学习目标）\n'
              '• 这不是实时同步，不代表其他设备也自动一致\n'
              '• 建议先手动备份当前设备',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('取消'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: MeowColors.warning),
            child: const Text('确认恢复'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    // Execute restore
    setState(() => _isRestoring = true);

    final result = await restoreService.restore();

    if (mounted) {
      setState(() => _isRestoring = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.isSuccess
              ? '恢复成功，当前设备数据已更新'
              : '恢复失败: ${result.errorCode ?? ""}',
          ),
        ),
      );
    }
  }

  // ==================== Daily Goal Setting (P3.1 Delta Phase 1) ====================

  int _currentDailyGoal = 20;
  bool _dailyGoalLoaded = false;

  Widget _buildDailyGoalSection() {
    if (!_dailyGoalLoaded) {
      SharedPreferences.getInstance().then((prefs) {
        if (mounted) {
          setState(() {
            _currentDailyGoal = LocalSettingsService(prefs).dailyGoal;
            _dailyGoalLoaded = true;
          });
        }
      });
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: MeowSpacing.md),
      child: MeowCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Text('📖', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 8),
                Text('每日学习目标', style: MeowTextStyles.label),
              ],
            ),
            const SizedBox(height: MeowSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '每日学习单词数量',
                    style: MeowTextStyles.bodySmall,
                  ),
                ),
                GestureDetector(
                  key: const Key('settings-daily-goal-entry'),
                  onTap: _showDailyGoalDialog,
                  child: Row(
                    children: [
                      Text(
                        '$_currentDailyGoal 个',
                        style: MeowTextStyles.subtitle.copyWith(color: MeowColors.primary),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.edit, size: 16, color: MeowColors.primary),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: MeowSpacing.sm),
            Text(
              '修改后当天生效，不会回算历史日',
              style: MeowTextStyles.caption.copyWith(color: MeowColors.textHint),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showDailyGoalDialog() async {
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController(text: '$_currentDailyGoal');
        String? errorText;

        return StatefulBuilder(
          builder: (ctx, setDialogState) => AlertDialog(
            title: const Text('设置每日学习单词数量'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: controller,
                  keyboardType: TextInputType.number,
                  autofocus: true,
                  decoration: InputDecoration(
                    labelText: '单词数量',
                    hintText: '1 - 500',
                    errorText: errorText,
                    suffixText: '个',
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  '建议范围: 1 - 500',
                  style: MeowTextStyles.caption.copyWith(color: MeowColors.textHint),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('取消'),
              ),
              TextButton(
                onPressed: () {
                  final text = controller.text.trim();
                  if (text.isEmpty) {
                    setDialogState(() => errorText = '请输入数字');
                    return;
                  }
                  final value = int.tryParse(text);
                  if (value == null) {
                    setDialogState(() => errorText = '请输入整数');
                    return;
                  }
                  if (value <= 0) {
                    setDialogState(() => errorText = '必须大于 0');
                    return;
                  }
                  if (value > 500) {
                    setDialogState(() => errorText = '建议不超过 500');
                    return;
                  }
                  Navigator.pop(ctx, value);
                },
                child: const Text('确认'),
              ),
            ],
          ),
        );
      },
    );

    if (result != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      final settings = LocalSettingsService(prefs);
      await settings.setDailyGoal(result);

      try {
        await ApiClient().updateDailyGoal(result);
      } catch (_) {
        // Backend sync failed — local setting saved, will take effect on next restart
      }

      setState(() => _currentDailyGoal = result);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('已更新为 $result 个/天'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }

  Widget _buildLatestStatus() {
    MeowChipVariant variant;
    String statusText;

    switch (_backupStatus) {
      case BackupUploadStatus.noBackupYet:
        variant = MeowChipVariant.neutral;
        statusText = '尚未备份';
        break;
      case BackupUploadStatus.uploadInProgress:
      case BackupUploadStatus.retrying:
        variant = MeowChipVariant.info;
        statusText = '备份中';
        break;
      case BackupUploadStatus.uploadSucceeded:
        variant = MeowChipVariant.success;
        statusText = '已备份';
        break;
      case BackupUploadStatus.uploadFailed:
        variant = MeowChipVariant.warning;
        statusText = '备份失败';
        break;
      case BackupUploadStatus.temporarilyUnavailable:
        variant = MeowChipVariant.neutral;
        statusText = '服务暂不可用';
        break;
    }

    return Row(
      children: [
        MeowChip(label: statusText, variant: variant, small: true),
        if (_lastBackupTime != null) ...[
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '最近一次: ${_formatTime(_lastBackupTime!)}',
              style: MeowTextStyles.caption.copyWith(color: MeowColors.textSecondary),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }

  String _formatTime(String isoTime) {
    try {
      final dt = DateTime.parse(isoTime).toLocal();
      return '${dt.month}/${dt.day} '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return isoTime;
    }
  }

  // ==================== FSRS Retention Setting ====================

  Widget _buildRetentionSection() {
    return FutureBuilder<SharedPreferences>(
      future: SharedPreferences.getInstance(),
      builder: (context, snap) {
        if (!snap.hasData) return const SizedBox.shrink();
        final settings = LocalSettingsService(snap.data!);
        final current = settings.desiredRetention;

        return MeowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '记忆设置',
                style: MeowTextStyles.label,
              ),
              const SizedBox(height: MeowSpacing.md),
              InkWell(
                onTap: () => _showRetentionDialog(settings, current),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '记忆保留率',
                              style: MeowTextStyles.body,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '调高→复习量增加但记忆更牢；调低→复习量减少但可能遗忘更多',
                              style: MeowTextStyles.caption.copyWith(
                                  color: MeowColors.textHint),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        current.toStringAsFixed(2),
                        style: MeowTextStyles.body
                            .copyWith(fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 4),
                      Icon(Icons.chevron_right,
                          size: 18, color: MeowColors.textHint),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _showRetentionDialog(
      LocalSettingsService settings, double current) async {
    double tempValue = current;

    final result = await showDialog<double>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: const Text('记忆保留率'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    tempValue.toStringAsFixed(2),
                    style: Theme.of(ctx)
                        .textTheme
                        .headlineMedium
                        ?.copyWith(fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 8),
                  Slider(
                    value: tempValue,
                    min: 0.85,
                    max: 0.95,
                    divisions: 10,
                    label: tempValue.toStringAsFixed(2),
                    onChanged: (v) {
                      setDialogState(() => tempValue = v);
                    },
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '默认 0.90。调高复习更频繁但记忆更牢固，调低复习量少但可能遗忘更多。',
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600]),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('取消'),
                ),
                TextButton(
                  onPressed: () => Navigator.pop(ctx, tempValue),
                  child: const Text('确认'),
                ),
              ],
            );
          },
        );
      },
    );

    if (result != null && mounted) {
      await settings.setDesiredRetention(result);
      setState(() {}); // rebuild to show new value

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('记忆保留率已更新为 ${result.toStringAsFixed(2)}'),
            duration: const Duration(seconds: 1),
          ),
        );
      }
    }
  }
}

