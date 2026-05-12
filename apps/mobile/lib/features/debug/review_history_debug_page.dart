import 'package:flutter/material.dart';

import '../../core/api/api_client.dart';
import '../../core/auth/auth.dart';
import '../../core/services/review_log_service.dart';
import '../../core/storage/drift/app_database.dart';

/// Need #10 — Debug page for inspecting a word's review history.
///
/// Pure debug surface: shows cloud-accepted history (server truth) and
/// local pending/unsynced entries (offline-stored attempts), tagged so
/// it is obvious which is which. No editing, no FSRS, no rewards.
class ReviewHistoryDebugPage extends StatefulWidget {
  const ReviewHistoryDebugPage({super.key});

  @override
  State<ReviewHistoryDebugPage> createState() => _ReviewHistoryDebugPageState();
}

class _ReviewHistoryDebugPageState extends State<ReviewHistoryDebugPage> {
  final TextEditingController _wordIdCtrl = TextEditingController();
  final ApiClient _api = ApiClient();
  late final ReviewLogService _log;

  bool _loading = false;
  String? _error;
  List<WordReviewHistoryItem> _cloud = const [];
  List<ReviewRecord> _local = const [];

  @override
  void initState() {
    super.initState();
    // PR-C-β: per-user via factory ctor.
    _log = ReviewLogService.forUser(
      apiClient: _api,
      driftDb: AppDatabase(),
      userId: AuthScope.currentUserIdOf(context),
    );
  }

  @override
  void dispose() {
    _wordIdCtrl.dispose();
    _api.dispose();
    super.dispose();
  }

  Future<void> _query() async {
    final wid = _wordIdCtrl.text.trim();
    if (wid.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
      _cloud = const [];
      _local = const [];
    });
    try {
      final localFuture = _log.getLocalForWord(wid, limit: 50);
      final cloudFuture =
          _log.getCloudForWord(wid, limit: 50).catchError((e) {
        // Cloud failure is non-fatal — debug page still shows local.
        debugPrint('[ReviewHistoryDebug] cloud fetch failed: $e');
        return <WordReviewHistoryItem>[];
      });
      final results = await Future.wait([localFuture, cloudFuture]);
      if (!mounted) return;
      setState(() {
        _local = results[0] as List<ReviewRecord>;
        _cloud = results[1] as List<WordReviewHistoryItem>;
      });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _local.where((r) => r.synced == 0).length;
    return Scaffold(
      appBar: AppBar(title: const Text('复习历史 (调试)')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _wordIdCtrl,
                    decoration: const InputDecoration(
                      labelText: 'word_id',
                      hintText: '输入要查询的单词 id',
                      border: OutlineInputBorder(),
                    ),
                    onSubmitted: (_) => _query(),
                  ),
                ),
                const SizedBox(width: 12),
                FilledButton(
                  onPressed: _loading ? null : _query,
                  child: const Text('查询'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            if (_loading) const LinearProgressIndicator(),
            const SizedBox(height: 8),
            _SectionHeader(
              title: '云端 accepted history',
              subtitle: '共 ${_cloud.length} 条 · 来自 GET /me/words/:id/review-history',
            ),
            Expanded(
              child: _cloud.isEmpty
                  ? const _EmptyHint(text: '— 无云端记录 —')
                  : ListView.builder(
                      itemCount: _cloud.length,
                      itemBuilder: (_, i) => _CloudRow(item: _cloud[i]),
                    ),
            ),
            const Divider(),
            _SectionHeader(
              title: '本地 review log',
              subtitle:
                  '共 ${_local.length} 条 · pending: $pendingCount · 来自 review_records 表',
            ),
            Expanded(
              child: _local.isEmpty
                  ? const _EmptyHint(text: '— 无本地记录 —')
                  : ListView.builder(
                      itemCount: _local.length,
                      itemBuilder: (_, i) => _LocalRow(record: _local[i]),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.subtitle});
  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleSmall),
          Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

class _EmptyHint extends StatelessWidget {
  const _EmptyHint({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) =>
      Center(child: Text(text, style: const TextStyle(color: Colors.grey)));
}

class _CloudRow extends StatelessWidget {
  const _CloudRow({required this.item});
  final WordReviewHistoryItem item;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      dense: true,
      leading: const Icon(Icons.cloud_done_outlined, size: 18),
      title: Text(
        '${item.actionResult} · ${item.reviewedAt}',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        'attempt=${item.attemptId}\nsession=${item.sessionId ?? "(none)"}',
        style: const TextStyle(fontSize: 11),
      ),
    );
  }
}

class _LocalRow extends StatelessWidget {
  const _LocalRow({required this.record});
  final ReviewRecord record;

  @override
  Widget build(BuildContext context) {
    final isPending = record.synced == 0;
    return ListTile(
      dense: true,
      leading: Icon(
        isPending ? Icons.cloud_upload_outlined : Icons.check_circle_outline,
        size: 18,
        color: isPending ? Colors.orange : Colors.green,
      ),
      title: Text(
        '${record.actionResult} · ${record.createdAt}',
        style: const TextStyle(fontSize: 13),
      ),
      subtitle: Text(
        'rating=${record.rating ?? "—"} · session=${record.sessionId ?? "(none)"} · '
        '${isPending ? "PENDING" : "SYNCED"}',
        style: TextStyle(
          fontSize: 11,
          color: isPending ? Colors.orange[800] : null,
        ),
      ),
    );
  }
}
