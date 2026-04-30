import 'dart:ui';
import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../theme/tokens.dart';
import '../widgets/spec_back_to_study_chip.dart';

/// home-c · 夜晚主题版 Mochi 主页
///
/// 纯本地设置（SharedPreferences），零 DB / API 变更。
/// 数据源复用 GET /me/secondary-summary（同白天版）。
/// 副机制纪律（CLAUDE.md §3.2）：不产生任何学习收益。
class SpecMochiHomeNight extends StatefulWidget {
  const SpecMochiHomeNight({super.key, required this.onToggleDay});

  /// 切回白天主题的回调（由 SpecShell 注入）
  final VoidCallback onToggleDay;

  @override
  State<SpecMochiHomeNight> createState() => _SpecMochiHomeNightState();
}

class _SpecMochiHomeNightState extends State<SpecMochiHomeNight> {
  final ApiClient _apiClient = ApiClient();
  SecondarySummary? _summary;
  bool _isLoading = true;

  static const _kBgTop = Color(0xFF14121C);
  static const _kBgBottom = Color(0xFF2A2438);
  static const _kMoon = Color(0xFFF5EFD9);
  static const _kGlass = Color(0x14FFFFFF); // rgba 0.08
  static const _kGlassBorder = Color(0x1EFFFFFF); // rgba 0.12

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _apiClient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final s = await _apiClient.getSecondarySummary();
      if (mounted) setState(() { _summary = s; _isLoading = false; });
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // ── 背景渐变
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [_kBgTop, _kBgBottom],
              ),
            ),
          ),

          // ── 星星纹理（低透明度装饰点）
          _buildStarField(),

          // ── 月亮
          Positioned(
            top: 70,
            right: 32,
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: _kMoon,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _kMoon.withValues(alpha: 0.45),
                    blurRadius: 18,
                    spreadRadius: 4,
                  ),
                ],
              ),
            ),
          ),

          // ── 猫咪区（屏幕中央偏上）
          Positioned(
            top: 130,
            left: 0,
            right: 0,
            child: Column(
              children: [
                // 对话气泡
                _buildDarkBubble('猫猫趴在单词书上等你喵。'),
                const SizedBox(height: 12),

                // 猫咪占位（MochiCat 待美术资源）
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    const Text('🐱', style: TextStyle(fontSize: 90)),
                    // 紫色书条
                    Positioned(
                      bottom: -8,
                      child: Container(
                        width: 110,
                        height: 8,
                        decoration: BoxDecoration(
                          color: SpecBrand.purple.withValues(alpha: 0.7),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ── 底部玻璃卡（今晚的提议）
          Positioned(
            bottom: 80,
            left: SpecSpacing.pageH,
            right: SpecSpacing.pageH,
            child: _buildGlassCard(),
          ),

          // ── 回到学习 chip（深色模式）
          Positioned(
            top: 56,
            right: SpecSpacing.pageH,
            child: const SpecBackToStudyChip(dark: true),
          ),

          // ── 切回白天按钮（左上角太阳图标）
          Positioned(
            top: 56,
            left: SpecSpacing.pageH,
            child: GestureDetector(
              onTap: widget.onToggleDay,
              child: Container(
                height: 30,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                    width: 0.5,
                  ),
                  borderRadius: SpecRadius.pillRadius,
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('☀️', style: TextStyle(fontSize: 11)),
                    SizedBox(width: 4),
                    Text(
                      '白天模式',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: SpecTypo.medium,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 深色气泡
  Widget _buildDarkBubble(String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(14),
          topRight: Radius.circular(14),
          bottomRight: Radius.circular(14),
          bottomLeft: Radius.circular(4),
        ),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 0.5),
      ),
      child: Text(
        text,
        style: const TextStyle(fontSize: 13, color: Colors.white, height: 1.4),
        textAlign: TextAlign.center,
      ),
    );
  }

  // ── 玻璃卡（今晚的提议）
  Widget _buildGlassCard() {
    final debt = _summary?.reviewDebt ?? 0;
    final hasDebt = debt > 0;

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          padding: const EdgeInsets.fromLTRB(18, 16, 18, 16),
          decoration: BoxDecoration(
            color: _kGlass,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: _kGlassBorder, width: 0.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 标题行
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    '今晚的提议',
                    style: TextStyle(
                      fontSize: SpecTypo.sizeLabelSmall,
                      fontWeight: SpecTypo.medium,
                      color: Colors.white,
                    ),
                  ),
                  if (!_isLoading && hasDebt)
                    Text(
                      '$debt 个旧词待复习',
                      style: TextStyle(
                        fontSize: SpecTypo.sizeTiny,
                        color: Colors.white.withValues(alpha: 0.65),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // CTA 行
              Row(
                children: [
                  // 主 CTA
                  Expanded(
                    child: GestureDetector(
                      onTap: () => Navigator.pushNamed(
                        context,
                        hasDebt ? '/review' : '/study',
                      ),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          hasDebt ? '复习一会儿喵' : '去学几个词喵',
                          style: const TextStyle(
                            fontSize: SpecTypo.sizeLabel,
                            fontWeight: SpecTypo.medium,
                            color: SpecBrand.purple,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  // 次 CTA
                  GestureDetector(
                    onTap: widget.onToggleDay,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.4),
                          width: 0.5,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '明天见喵',
                        style: TextStyle(
                          fontSize: SpecTypo.sizeLabel,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── 星星纹理（简化版，用小圆点模拟）
  Widget _buildStarField() {
    const stars = [
      _Star(0.15, 0.08, 1.5),
      _Star(0.42, 0.05, 1.0),
      _Star(0.70, 0.12, 2.0),
      _Star(0.88, 0.07, 1.2),
      _Star(0.25, 0.18, 1.0),
      _Star(0.60, 0.22, 1.5),
      _Star(0.80, 0.28, 1.0),
      _Star(0.10, 0.30, 1.2),
      _Star(0.50, 0.15, 0.8),
      _Star(0.35, 0.35, 1.0),
    ];

    return LayoutBuilder(builder: (context, constraints) {
      return Stack(
        children: stars.map((s) {
          return Positioned(
            left: s.xFraction * constraints.maxWidth,
            top: s.yFraction * constraints.maxHeight,
            child: Container(
              width: s.size,
              height: s.size,
              decoration: const BoxDecoration(
                color: Color(0x14FFFFFF),
                shape: BoxShape.circle,
              ),
            ),
          );
        }).toList(),
      );
    });
  }
}

class _Star {
  final double xFraction;
  final double yFraction;
  final double size;
  const _Star(this.xFraction, this.yFraction, this.size);
}
