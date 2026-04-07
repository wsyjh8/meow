import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../../core/services/study_service.dart';
import '../../core/storage/local_database.dart';

/// StudyPage - 新词学习 (SQLite-first)
///
/// Flow: 点击掌握/模糊 → 立即写入 SQLite → UI 即时反馈 → 后台同步 API
class StudyPage extends StatefulWidget {
  const StudyPage({super.key});

  @override
  State<StudyPage> createState() => _StudyPageState();
}

class _StudyPageState extends State<StudyPage> {
  late final StudyService _studyService;
  Word? _currentWord;
  bool _isLoading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _studyService = StudyService(
      apiClient: ApiClient(),
      db: LocalDatabase.instance,
    );
    // Sync any pending records from previous session
    _studyService.syncPendingAttempts();
    _loadNextWord();
  }

  @override
  void dispose() {
    _studyService.dispose();
    super.dispose();
  }

  Future<void> _loadNextWord() async {
    setState(() { _isLoading = true; _error = null; });

    try {
      final word = await _studyService.getNextWord();
      if (mounted) setState(() { _currentWord = word; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _submitStudy(String actionResult) async {
    if (_currentWord == null) return;

    setState(() { _isLoading = true; _error = null; });

    try {
      // LOCAL FIRST: writes to SQLite immediately, returns instantly
      await _studyService.submitStudyAttempt(
        wordId: _currentWord!.wordId,
        bookId: _currentWord!.bookId,
        studyType: 'new',
        actionResult: actionResult,
      );

      if (mounted) {
        setState(() => _isLoading = false);

        // Immediate feedback — not waiting for API
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(actionResult == 'know' ? '已掌握 ✓' : '已标记模糊'),
            duration: const Duration(milliseconds: 500),
          ),
        );

        // Load next word
        await _loadNextWord();
      }
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('学习新词'),
      ),
      body: _isLoading && _currentWord == null
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, color: Colors.red, size: 48),
                      const SizedBox(height: 16),
                      Text('加载失败：$_error'),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _loadNextWord,
                        child: const Text('重试'),
                      ),
                    ],
                  ),
                )
              : _currentWord == null
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.check_circle, color: Colors.green),
                          const SizedBox(height: 16),
                          const Text('今日新词已学完'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('返回'),
                          ),
                        ],
                      ),
                    )
                  : _buildContent(),
    );
  }

  Widget _buildContent() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 32),

          // Word card
          Card(
            elevation: 4,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Text(
                    _currentWord!.wordText,
                    style: Theme.of(context).textTheme.headlineLarge,
                  ),
                  if (_currentWord!.phonetic != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      _currentWord!.phonetic!,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  Text(
                    _currentWord!.meaning,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
            ),
          ),

          const Spacer(),

          // Action buttons
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: _isLoading ? null : () => _submitStudy('forgot'),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('模糊'),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: ElevatedButton(
                  onPressed: _isLoading ? null : () => _submitStudy('know'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text('掌握'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }
}
