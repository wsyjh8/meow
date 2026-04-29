import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../features/today/today_page.dart';
import '../theme/tokens.dart';
import '../widgets/spec_tab_bar.dart';
import 'books_page.dart';
import 'home_page.dart';
import 'mochi_page.dart';
import 'stats_page.dart';
import 'profile_page.dart';

/// SPEC App Shell — Tab Bar + Page Switcher
///
/// 6 tabs: Home / Books / Mochi / Stats / Profile / Legacy
/// NO animation on tab switch — direct page replacement
class SpecShell extends StatefulWidget {
  const SpecShell({super.key});

  @override
  State<SpecShell> createState() => _SpecShellState();
}

class _SpecShellState extends State<SpecShell> {
  SpecTab _currentTab = SpecTab.home;

  // Incremented each time we return to the home tab so SpecHomePage
  // rebuilds and reloads data (e.g. after switching active wordbook).
  int _homeEpoch = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecBg.canvas,
      body: _buildCurrentPage(),
      bottomNavigationBar: SpecTabBar(
        currentTab: _currentTab,
        onTabChanged: (tab) {
          setState(() {
            if (tab == SpecTab.home && _currentTab != SpecTab.home) {
              _homeEpoch++;
            }
            _currentTab = tab;
          });
        },
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_currentTab) {
      case SpecTab.home:
        return SpecHomePage(key: ValueKey(_homeEpoch));
      case SpecTab.books:
        return const BooksPage();
      case SpecTab.mochi:
        return const SpecMochiPage();
      case SpecTab.stats:
        return const SpecStatsPage();
      case SpecTab.profile:
        return const SpecProfilePage();
      case SpecTab.legacy:
        return _buildLegacyTab();
    }
  }

  /// SPEC 5.1.6 — Legacy tab: existing TodayPage, NOT rewritten/modified/beautified.
  /// Dev-only banner visible only in debug mode, hidden in production.
  Widget _buildLegacyTab() {
    return Column(
      children: [
        // Dev-only warning banner (SPEC 5.1.6)
        // Hidden in production via kDebugMode check
        if (kDebugMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFFAEEDA),
            child: const Text(
              '\u26a0 \u8fd9\u662f v0 \u65e7\u7248\u9996\u9875\uff08\u5f00\u53d1\u671f\u53c2\u8003\u7528\uff0c\u6b63\u5f0f\u7248\u672c\u5c06\u79fb\u9664\uff09',
              // ⚠ 这是 v0 旧版首页（开发期参考用，正式版本将移除）
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF633806)),
            ),
          ),
        // Existing TodayPage — DO NOT rewrite, refactor, modify, or beautify
        const Expanded(child: TodayPage()),
      ],
    );
  }
}
