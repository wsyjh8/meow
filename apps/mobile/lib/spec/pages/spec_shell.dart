import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../features/today/today_page.dart';
import '../theme/tokens.dart';
import '../widgets/spec_tab_bar.dart';
import 'books_page.dart';
import 'home_page.dart';
import 'mochi_page.dart';
import 'spec_meow_home_night.dart';
import 'stats/stats_page.dart';
import 'profile_page.dart';

const _kNightModeKey = 'mochi_night_mode';

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
  bool _nightMode = false;

  // Incremented each time we return to the home tab so SpecHomePage
  // rebuilds and reloads data (e.g. after switching active wordbook).
  int _homeEpoch = 0;

  @override
  void initState() {
    super.initState();
    _loadNightMode();
  }

  Future<void> _loadNightMode() async {
    final prefs = await SharedPreferences.getInstance();
    if (mounted) {
      setState(() => _nightMode = prefs.getBool(_kNightModeKey) ?? false);
    }
  }

  Future<void> _setNightMode(bool value) async {
    setState(() => _nightMode = value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNightModeKey, value);
  }

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
        return _nightMode
            ? SpecMochiHomeNight(
                key: const ValueKey('night'),
                onToggleDay: () => _setNightMode(false),
              )
            : SpecMochiPage(
                key: const ValueKey('day'),
                onNightToggle: () => _setNightMode(true),
              );
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
        if (kDebugMode)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            color: const Color(0xFFFAEEDA),
            child: const Text(
              '⚠ 这是 v0 旧版首页（开发期参考用，正式版本将移除）',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 11, color: Color(0xFF633806)),
            ),
          ),
        const Expanded(child: TodayPage()),
      ],
    );
  }
}
