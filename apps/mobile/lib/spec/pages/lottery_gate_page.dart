import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../theme/tokens.dart';
import '../widgets/spec_back_to_study_chip.dart';

/// 盲盒入口页（Phase D）
///
/// 副机制纪律（CLAUDE.md §3.2）：本页面只发放装扮币（金币），
/// 不会产生任何学习进度或 EXP。
class LotteryGatePage extends StatefulWidget {
  const LotteryGatePage({super.key, ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;

  @override
  State<LotteryGatePage> createState() => _LotteryGatePageState();
}

class _LotteryGatePageState extends State<LotteryGatePage>
    with SingleTickerProviderStateMixin {
  late final ApiClient _apiClient;
  late final bool _ownsClient;
  late final AnimationController _shakeController;

  LotteryBoxesResponse? _data;
  bool _isLoading = true;
  bool _isOpening = false;
  String? _errorMessage;
  LotteryOpenResult? _lastResult;

  @override
  void initState() {
    super.initState();
    if (widget._apiClient != null) {
      _apiClient = widget._apiClient!;
      _ownsClient = false;
    } else {
      _apiClient = ApiClient();
      _ownsClient = true;
    }
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _load();
  }

  @override
  void dispose() {
    _shakeController.dispose();
    if (_ownsClient) _apiClient.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final data = await _apiClient.getLotteryBoxes();
      if (!mounted) return;
      setState(() {
        _data = data;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = '加载失败：$e';
      });
    }
  }

  Future<void> _openBox(String boxId) async {
    if (_isOpening) return;
    setState(() {
      _isOpening = true;
      _lastResult = null;
    });
    _shakeController.forward(from: 0);
    try {
      final r = await _apiClient.openLotteryBox(
        boxId: boxId,
        idempotencyKey: 'lbox-open-$boxId',
      );
      if (!mounted) return;
      setState(() {
        _lastResult = r;
        _isOpening = false;
        // Remove the opened box from list and update balance
        if (_data != null && r.opened) {
          _data = LotteryBoxesResponse(
            pendingBoxes: _data!.pendingBoxes
                .where((b) => b.id != boxId)
                .toList(),
            totalPending: _data!.totalPending - 1,
            coinsBalance: r.coinsBalance,
            fishTreatsBalance: _data!.fishTreatsBalance,
          );
        }
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isOpening = false;
        _errorMessage = '打开失败：$e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SpecBg.canvas,
      appBar: AppBar(
        backgroundColor: SpecBg.canvas,
        elevation: 0,
        title: const Text('盲盒', style: SpecTypo.pageTitle),
        foregroundColor: SpecText.primary,
        actions: [
          if (_data != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '🪙 ${_data!.coinsBalance}',
                  style: const TextStyle(
                    fontSize: SpecTypo.sizeCardTitle,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.purple,
                  ),
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.only(right: 12),
            child: Center(child: SpecBackToStudyChip()),
          ),
        ],
      ),
      body: SafeArea(child: _buildBody()),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(_errorMessage!, style: SpecTypo.cardBody),
            const SizedBox(height: 12),
            TextButton(onPressed: _load, child: const Text('重试')),
          ],
        ),
      );
    }
    final data = _data!;
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: SpecSpacing.pageH, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSeparationNotice(),
          const SizedBox(height: 16),
          _buildSummaryCard(data),
          const SizedBox(height: 16),
          if (_lastResult != null) ...[
            _buildLastPrizeCard(),
            const SizedBox(height: 16),
          ],
          if (data.pendingBoxes.isEmpty)
            _buildEmptyCard()
          else
            _buildBoxList(data),
        ],
      ),
    );
  }

  Widget _buildSeparationNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: SpecBg.heroPurple,
        borderRadius: SpecRadius.smallRadius,
      ),
      child: Row(
        children: const [
          Text('🐱', style: TextStyle(fontSize: 14)),
          SizedBox(width: 6),
          Expanded(
            child: Text(
              '盲盒奖励只是装扮币，不会变成学习进度喵。',
              style: TextStyle(
                fontSize: SpecTypo.sizeLabelSmall,
                color: SpecText.purpleDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(LotteryBoxesResponse data) {
    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: SpecBg.card,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('未开启盲盒', style: SpecTypo.cardSmall),
                const SizedBox(height: 4),
                Text(
                  '${data.totalPending} 个',
                  style: const TextStyle(
                    fontSize: SpecTypo.sizeBlockNumber,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.purple,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('小鱼干', style: SpecTypo.cardSmall),
                const SizedBox(height: 4),
                Text(
                  '🐟 ${data.fishTreatsBalance}',
                  style: const TextStyle(
                    fontSize: SpecTypo.sizeBlockNumber,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.coral,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyCard() {
    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: SpecBg.mochiWarm,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Column(
        children: [
          const Text('🎁', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          const Text(
            '还没有盲盒喵',
            style: TextStyle(
              fontSize: SpecTypo.sizeCardTitle,
              fontWeight: SpecTypo.medium,
              color: SpecText.mochi,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '完成 3 轮钓鱼可以拿到一个盲盒',
            style: TextStyle(
              fontSize: SpecTypo.sizeLabelSmall,
              color: SpecText.secondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/fishing'),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpecBrand.mochiRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: SpecRadius.ctaRadius),
              ),
              child: const Text(
                '去钓鱼喵',
                style: TextStyle(
                  fontSize: SpecTypo.sizeCardTitle,
                  fontWeight: SpecTypo.medium,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoxList(LotteryBoxesResponse data) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: data.pendingBoxes.map((b) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: AnimatedBuilder(
            animation: _shakeController,
            builder: (context, child) {
              final isThis = _isOpening;
              final dx = isThis ? (_shakeController.value * 6 - 3).abs() - 1.5 : 0.0;
              return Transform.translate(offset: Offset(dx, 0), child: child);
            },
            child: Container(
              padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
              decoration: BoxDecoration(
                color: SpecBg.heroPurple,
                borderRadius: SpecRadius.cardRadius,
                border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
              ),
              child: Row(
                children: [
                  const Text('🎁', style: TextStyle(fontSize: 32)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          '钓鱼盲盒',
                          style: TextStyle(
                            fontSize: SpecTypo.sizeCardTitle,
                            fontWeight: SpecTypo.medium,
                            color: SpecText.purpleDeep,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '来自钓鱼游戏 · ${b.id.substring(0, 6).toUpperCase()}',
                          style: SpecTypo.tiny,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton(
                    onPressed: _isOpening ? null : () => _openBox(b.id),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: SpecBrand.purple,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: SpecRadius.pillRadius,
                      ),
                    ),
                    child: const Text(
                      '打开喵',
                      style: TextStyle(
                        fontSize: SpecTypo.sizeLabel,
                        fontWeight: SpecTypo.medium,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLastPrizeCard() {
    final r = _lastResult!;
    if (!r.opened) {
      return Container(
        padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
        decoration: BoxDecoration(
          color: SpecBg.mochiWarm,
          borderRadius: SpecRadius.cardRadius,
          border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
        ),
        child: const Text(
          '这个盒子已经被打开过了喵～',
          style: TextStyle(
            fontSize: SpecTypo.sizeCardTitle,
            color: SpecText.mochi,
          ),
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: SpecBg.highlightGreen,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Column(
        children: [
          const Text('✨', style: TextStyle(fontSize: 36)),
          const SizedBox(height: 4),
          const Text(
            '抽到啦！',
            style: TextStyle(
              fontSize: SpecTypo.sizeCardTitle,
              fontWeight: SpecTypo.medium,
              color: SpecText.green,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '🪙 +${r.coinsWon}',
            style: const TextStyle(
              fontSize: SpecTypo.sizeBlockNumber,
              fontWeight: SpecTypo.medium,
              color: SpecText.purple,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '装扮币已到账，不会影响学习进度喵',
            style: TextStyle(
              fontSize: SpecTypo.sizeLabelSmall,
              color: SpecText.secondary,
            ),
          ),
        ],
      ),
    );
  }
}
