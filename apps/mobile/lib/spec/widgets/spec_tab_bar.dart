import 'package:flutter/material.dart';
import '../theme/tokens.dart';
import '../icons/tab_icons.dart';

/// SPEC Section 5.1 — Tab Bar
///
/// 6 tabs (dev phase): 首页 / 词书 / Mochi / 统计 / 我的 / 原版
/// Height: 64px (including safe area)
/// Border-top: 0.5px #ECE3D2
/// Background: #FDFBF7
/// NO animation on tab switch — direct page switch
/// NO badges, NO red dots

enum SpecTab { home, books, mochi, stats, profile, legacy }

class SpecTabBar extends StatelessWidget {
  final SpecTab currentTab;
  final ValueChanged<SpecTab> onTabChanged;

  const SpecTabBar({
    super.key,
    required this.currentTab,
    required this.onTabChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: SpecBg.canvas,
        border: Border(
          top: BorderSide(color: SpecBorder.divider, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          height: 48, // 64 - ~16 safe area
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: SpecTab.values.map((tab) => _buildTab(tab)).toList(),
          ),
        ),
      ),
    );
  }

  Widget _buildTab(SpecTab tab) {
    final isSelected = tab == currentTab;
    final isLegacy = tab == SpecTab.legacy;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTabChanged(tab),
        child: Container(
          constraints: const BoxConstraints(minHeight: SpecSpacing.minTouch),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Icon
              _buildIcon(tab, isSelected),
              SizedBox(height: SpecSpacing.tabIconLabelGap),
              // Label
              if (isLegacy) ...[
                // Legacy: always #B4A89A, add underline when selected
                Column(
                  children: [
                    Text(
                      _tabLabel(tab),
                      style: TextStyle(
                        fontSize: SpecTabIcon.labelSize,
                        fontWeight: SpecTypo.regular,
                        color: SpecText.tertiary,
                      ),
                    ),
                    if (isSelected)
                      Container(
                        margin: const EdgeInsets.only(top: 2),
                        width: 16,
                        height: 2,
                        color: SpecText.tertiary,
                      )
                    else
                      const SizedBox(height: 4), // Reserve space
                  ],
                ),
              ] else ...[
                Text(
                  _tabLabel(tab),
                  style: TextStyle(
                    fontSize: SpecTabIcon.labelSize,
                    fontWeight: isSelected ? SpecTypo.medium : SpecTypo.regular,
                    color: isSelected ? SpecText.primary : SpecText.secondary,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(SpecTab tab, bool isSelected) {
    switch (tab) {
      case SpecTab.home:
        return IconHome(isSelected: isSelected);
      case SpecTab.books:
        return IconBooks(isSelected: isSelected);
      case SpecTab.mochi:
        return IconMochi(isSelected: isSelected, size: SpecTabIcon.mochiSize);
      case SpecTab.stats:
        return IconStats(isSelected: isSelected);
      case SpecTab.profile:
        return IconProfile(isSelected: isSelected);
      case SpecTab.legacy:
        return const IconLegacy();
    }
  }

  String _tabLabel(SpecTab tab) {
    switch (tab) {
      case SpecTab.home: return '首页';
      case SpecTab.books: return '词书';
      case SpecTab.mochi: return 'Mochi';
      case SpecTab.stats: return '统计';
      case SpecTab.profile: return '我的';
      case SpecTab.legacy: return '原版';
    }
  }
}
