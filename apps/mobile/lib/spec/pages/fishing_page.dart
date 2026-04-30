import 'package:flutter/material.dart';
import '../../core/api/api_client.dart';
import '../theme/tokens.dart';
import '../widgets/spec_back_to_study_chip.dart';

/// 钓鱼小游戏页（Phase D）
///
/// 副机制纪律（CLAUDE.md §3.2）：本页面奖励仅产生小鱼干 / 盲盒，
/// 不会产生任何学习进度。
///
/// 文案纪律（§3.4）：猫猫语气句尾以「喵」收尾。
///
/// 玩法：
///   每天 3 轮（北京时间凌晨 5 点重置）。
///   每轮 5 个候选词，1 个是用户已学过的「真鱼」，4 个是没学过的「假饵」。
///   选中真鱼 → +2 小鱼干；3 轮全部完成 → +1 盲盒。
class FishingPage extends StatefulWidget {
  const FishingPage({super.key, ApiClient? apiClient}) : _apiClient = apiClient;

  final ApiClient? _apiClient;

  @override
  State<FishingPage> createState() => _FishingPageState();
}

class _FishingPageState extends State<FishingPage> {
  late final ApiClient _apiClient;
  late final bool _ownsClient;

  DailyTaskStatus? _status;
  FishingRoundQuestion? _question;
  bool _isLoading = true;
  bool _isSubmitting = false;
  String? _selectedWordId;
  FishingAttemptResult? _lastResult;
  String? _errorMessage;

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
    _load();
  }

  @override
  void dispose() {
    if (_ownsClient) {
      _apiClient.dispose();
    }
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final status = await _apiClient.getDailyTask();
      if (!mounted) return;
      setState(() {
        _status = status;
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

  Future<void> _startRound() async {
    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
      _lastResult = null;
      _selectedWordId = null;
    });
    try {
      final q = await _apiClient.startFishingRound();
      if (!mounted) return;
      setState(() {
        _question = q;
        _isSubmitting = false;
      });
      if (q == null) {
        // No round started — refresh status (likely exhausted or no studied words)
        await _load();
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = '出错了：$e';
      });
    }
  }

  Future<void> _submit(String wordId) async {
    if (_question == null || _isSubmitting) return;
    setState(() {
      _isSubmitting = true;
      _selectedWordId = wordId;
    });
    try {
      final r = await _apiClient.submitFishingAttempt(
        taskId: _question!.taskId,
        chosenWordId: wordId,
        idempotencyKey: 'fish-${_question!.taskId}-${_question!.roundNumber}',
      );
      if (!mounted) return;
      setState(() {
        _lastResult = r;
        _question = null;
        _isSubmitting = false;
        _status = DailyTaskStatus(
          taskId: _status?.taskId ?? '',
          taskDate: _status?.taskDate ?? '',
          roundsCompleted: r.roundsCompleted,
          roundsTotal: r.roundsTotal,
          status: r.status,
          hasActiveRound: false,
          fishTreatsBalance: r.fishTreatsBalance,
        );
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _errorMessage = '提交失败：$e';
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
        title: const Text('钓鱼小游戏', style: SpecTypo.pageTitle),
        foregroundColor: SpecText.primary,
        actions: [
          if (_status != null)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Text(
                  '🐟 ${_status!.fishTreatsBalance}',
                  style: const TextStyle(
                    fontSize: SpecTypo.sizeCardTitle,
                    fontWeight: SpecTypo.medium,
                    color: SpecText.coral,
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
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(
        horizontal: SpecSpacing.pageH, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSeparationNotice(),
          const SizedBox(height: 16),
          _buildProgressCard(),
          const SizedBox(height: 16),
          if (_question != null)
            _buildQuestionCard()
          else if (_lastResult != null)
            _buildResultCard()
          else
            _buildStartCard(),
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
        children: [
          const Text('🐱', style: TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          const Expanded(
            child: Text(
              '钓到的鱼只是装扮副线，不会变成学习进度喵。',
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

  Widget _buildProgressCard() {
    final s = _status!;
    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: SpecBg.card,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('今日进度', style: SpecTypo.cardTitle),
              Text(
                '${s.roundsCompleted}/${s.roundsTotal}',
                style: const TextStyle(
                  fontSize: SpecTypo.sizeBlockNumber,
                  fontWeight: SpecTypo.medium,
                  color: SpecText.purple,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: s.roundsTotal == 0 ? 0 : s.roundsCompleted / s.roundsTotal,
              minHeight: 6,
              backgroundColor: SpecBg.cardDeep,
              valueColor: const AlwaysStoppedAnimation(SpecBrand.purple),
            ),
          ),
          if (s.status == 'exhausted') ...[
            const SizedBox(height: 8),
            const Text(
              '今天已经钓完啦，明天再来喵～',
              style: TextStyle(
                fontSize: SpecTypo.sizeLabelSmall,
                color: SpecText.secondary,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildStartCard() {
    final s = _status!;
    final exhausted = s.status == 'exhausted';
    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: SpecBg.mochiWarm,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Column(
        children: [
          const Text('🎣', style: TextStyle(fontSize: 56)),
          const SizedBox(height: 8),
          Text(
            exhausted ? '今天的鱼都钓完啦' : '准备好开始钓鱼了喵？',
            style: const TextStyle(
              fontSize: SpecTypo.sizeCardTitle,
              fontWeight: SpecTypo.medium,
              color: SpecText.mochi,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            '在 5 个词里挑出你学过的那一个',
            style: TextStyle(
              fontSize: SpecTypo.sizeLabelSmall,
              color: SpecText.secondary,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: exhausted || _isSubmitting ? null : _startRound,
              style: ElevatedButton.styleFrom(
                backgroundColor: SpecBrand.mochiRose,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: SpecRadius.ctaRadius),
                disabledBackgroundColor: SpecBg.cardDeep,
              ),
              child: Text(
                exhausted ? '明天再来喵' : '开始钓鱼喵',
                style: const TextStyle(
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

  Widget _buildQuestionCard() {
    final q = _question!;
    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: SpecBg.card,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '第 ${q.roundNumber} 轮 · 挑出你学过的那个',
            style: SpecTypo.cardSmall,
          ),
          const SizedBox(height: 12),
          ...q.choices.map(_buildChoiceTile),
        ],
      ),
    );
  }

  Widget _buildChoiceTile(FishingChoice c) {
    final isSelected = _selectedWordId == c.wordId;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected ? SpecBg.heroPurple : SpecBg.canvas,
        borderRadius: SpecRadius.smallRadius,
        child: InkWell(
          borderRadius: SpecRadius.smallRadius,
          onTap: _isSubmitting ? null : () => _submit(c.wordId),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              borderRadius: SpecRadius.smallRadius,
              border: Border.all(
                color: isSelected ? SpecBrand.purple : SpecBorder.defaultColor,
                width: SpecBorder.width,
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    c.wordText,
                    style: const TextStyle(
                      fontSize: SpecTypo.sizeCardTitle,
                      fontWeight: SpecTypo.medium,
                      color: SpecText.primary,
                    ),
                  ),
                ),
                if (_isSubmitting && isSelected)
                  const SizedBox(
                    width: 16, height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultCard() {
    final r = _lastResult!;
    final emoji = r.isCorrect ? '🐟' : '🫧';
    final headline = r.isCorrect ? '钓到啦！' : '差一点喵';
    final bgColor = r.isCorrect ? SpecBg.highlightGreen : SpecBg.mochiWarm;
    final textColor = r.isCorrect ? SpecText.green : SpecText.mochi;

    return Container(
      padding: const EdgeInsets.all(SpecSpacing.cardPadLg),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: SpecRadius.cardRadius,
        border: Border.all(color: SpecBorder.defaultColor, width: SpecBorder.width),
      ),
      child: Column(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 4),
          Text(
            headline,
            style: TextStyle(
              fontSize: SpecTypo.sizeCardTitle,
              fontWeight: SpecTypo.medium,
              color: textColor,
            ),
          ),
          if (r.fishWord != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.6),
                borderRadius: SpecRadius.smallRadius,
              ),
              child: Column(
                children: [
                  Text(
                    r.fishWord!.wordText,
                    style: const TextStyle(
                      fontSize: SpecTypo.sizeCardTitle,
                      fontWeight: SpecTypo.medium,
                      color: SpecText.purple,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    r.fishWord!.meaning,
                    style: const TextStyle(
                      fontSize: SpecTypo.sizeCardSmall,
                      color: SpecText.secondary,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
          if (r.fishTreatsEarned > 0) ...[
            const SizedBox(height: 10),
            Text(
              '+${r.fishTreatsEarned} 小鱼干',
              style: const TextStyle(
                fontSize: SpecTypo.sizeCardTitle,
                fontWeight: SpecTypo.medium,
                color: SpecText.coral,
              ),
            ),
          ],
          if (r.boxEarned) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: SpecBrand.mochiRose,
                borderRadius: SpecRadius.pillRadius,
              ),
              child: const Text(
                '🎁 收到 1 个盲盒',
                style: TextStyle(
                  fontSize: SpecTypo.sizeLabelSmall,
                  fontWeight: SpecTypo.medium,
                  color: Colors.white,
                ),
              ),
            ),
          ],
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSubmitting
                  ? null
                  : (r.status == 'exhausted'
                      ? () => Navigator.pushNamed(context, '/lottery')
                      : _startRound),
              style: ElevatedButton.styleFrom(
                backgroundColor: SpecBrand.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: SpecRadius.ctaRadius),
              ),
              child: Text(
                r.status == 'exhausted' ? '去开盲盒喵' : '继续下一轮喵',
                style: const TextStyle(
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
}
