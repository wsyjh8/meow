import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/auth/auth.dart';
import '../../core/storage/drift/app_database.dart';
import '../../core/storage/local_settings_service.dart';
import '../theme/tokens.dart';

/// SPEC Books Tab — Wordbook catalogue + active book switcher.
///
/// Shows all supported wordbooks (CET-4 hardcoded + preset wordbooks from DB).
/// Tapping a non-active card immediately switches the active wordbook and
/// shows a SnackBar confirmation.
///
/// Switching only affects "new word source" (StudyService reads activeWordbook
/// on every getNextWord() call). Review queue (card_states / review_logs) is
/// NOT affected — those tables have no book_slug field.
class BooksPage extends StatefulWidget {
  const BooksPage({super.key});

  @override
  State<BooksPage> createState() => _BooksPageState();
}

class _BooksPageState extends State<BooksPage> {
  final AppDatabase _db = AppDatabase();

  List<_BookItem> _books = [];
  String _activeSlug = 'book-001';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    // Do not close: sqflite uses a per-path singleton; closing here
    // would invalidate DB connections held by other active widgets.
    super.dispose();
  }

  Future<void> _load() async {
    final userId = AuthScope.currentUserIdOf(context);
    final prefs = await SharedPreferences.getInstance();
    final active = LocalSettingsService(prefs, userId: userId).activeWordbook;

    // CET-4 is in cached_words, not preset_wordbooks — hard-code meta.
    final cet4Total = await _db.countWordsInBook('book-001');

    // ZK / GK come from preset_wordbooks, ordered by sort_order.
    final presets = await _db.getAllPresetWordbooks();

    if (!mounted) return;
    setState(() {
      _activeSlug = active;
      _books = [
        _BookItem(
          slug: 'book-001',
          displayName: 'CET-4 核心词汇',
          description: '大学英语四级',
          totalWords: cet4Total,
        ),
        for (final p in presets)
          _BookItem(
            slug: p.slug,
            displayName: p.displayName,
            description: p.description ?? '',
            totalWords: p.totalWords,
          ),
      ];
      _loading = false;
    });
  }

  Future<void> _switchBook(String slug) async {
    if (slug == _activeSlug) return;

    final userId = AuthScope.currentUserIdOf(context);
    final prefs = await SharedPreferences.getInstance();
    await LocalSettingsService(prefs, userId: userId).setActiveWordbook(slug);

    final name = _books.firstWhere((b) => b.slug == slug).displayName;

    if (!mounted) return;
    setState(() => _activeSlug = slug);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('已切换到 $name'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecBg.canvas,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            Expanded(
              child: _loading
                  ? const Center(
                      child: CircularProgressIndicator(color: SpecBrand.purple),
                    )
                  : _buildList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(
          SpecSpacing.pageH, 16, SpecSpacing.pageH, 8),
      child: const Text(
        '词书',
        style: TextStyle(
          fontSize: SpecTypo.sizePageTitle,
          fontWeight: SpecTypo.medium,
          color: SpecText.purpleDeep,
        ),
      ),
    );
  }

  Widget _buildList() {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: SpecSpacing.pageH,
        vertical: 8,
      ),
      itemCount: _books.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, i) => _buildCard(_books[i]),
    );
  }

  Widget _buildCard(_BookItem book) {
    final isActive = book.slug == _activeSlug;

    return GestureDetector(
      onTap: () => _switchBook(book.slug),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: Curves.easeOut,
        padding: const EdgeInsets.all(SpecSpacing.cardPadSm),
        decoration: BoxDecoration(
          color: isActive ? SpecBg.heroPurple : SpecBg.card,
          borderRadius: BorderRadius.circular(SpecRadius.large),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    book.displayName,
                    style: const TextStyle(
                      fontSize: SpecTypo.sizeCardTitle,
                      fontWeight: SpecTypo.medium,
                      color: SpecText.primary,
                    ),
                  ),
                  if (book.description.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      book.description,
                      style: const TextStyle(
                        fontSize: SpecTypo.sizeLabelSmall,
                        fontWeight: SpecTypo.regular,
                        color: SpecText.tertiary,
                      ),
                    ),
                  ],
                  const SizedBox(height: 6),
                  Text(
                    '${book.totalWords} 词',
                    style: const TextStyle(
                      fontSize: SpecTypo.sizeLabelSmall,
                      fontWeight: SpecTypo.regular,
                      color: SpecText.secondary,
                    ),
                  ),
                ],
              ),
            ),
            if (isActive)
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Text(
                  '✓ 当前',
                  style: TextStyle(
                    fontSize: SpecTypo.sizeLabelSmall,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.purple,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Private model ──────────────────────────────────────────────────────────────
/// UI-only model for a single wordbook entry in the catalogue.
class _BookItem {
  final String slug;
  final String displayName;
  final String description;
  final int totalWords;

  const _BookItem({
    required this.slug,
    required this.displayName,
    required this.description,
    required this.totalWords,
  });
}
