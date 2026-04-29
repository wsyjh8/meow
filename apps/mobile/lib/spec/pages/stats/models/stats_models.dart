import 'package:flutter/foundation.dart';

/// 全部统计页 DTO，集中放置便于测试断言。
/// 全部 immutable，equatable 比较语义。

// ── Tab 1: 概览趋势 ─────────────────────────────────────────────────────────

/// 概览页头部 4 数字卡。
@immutable
class OverviewHeader {
  /// 累计学习的不同单词数（不限本词书）
  final int totalWordsLearned;

  /// 较上周新增数量
  final int weeklyDelta;

  /// 已掌握的不同单词数
  final int totalMastered;

  /// 已掌握 / 总词汇 百分比 (0–100)
  final int masteryPercent;

  /// 连续打卡天数（基于 daily_checkins）
  final int currentStreak;

  /// 今日完成数（新词 + 复习）
  final int todayCompleted;

  /// 今日目标（新词 + 复习总和）
  final int todayGoal;

  const OverviewHeader({
    required this.totalWordsLearned,
    required this.weeklyDelta,
    required this.totalMastered,
    required this.masteryPercent,
    required this.currentStreak,
    required this.todayCompleted,
    required this.todayGoal,
  });

  static const empty = OverviewHeader(
    totalWordsLearned: 0,
    weeklyDelta: 0,
    totalMastered: 0,
    masteryPercent: 0,
    currentStreak: 0,
    todayCompleted: 0,
    todayGoal: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is OverviewHeader &&
          totalWordsLearned == other.totalWordsLearned &&
          weeklyDelta == other.weeklyDelta &&
          totalMastered == other.totalMastered &&
          masteryPercent == other.masteryPercent &&
          currentStreak == other.currentStreak &&
          todayCompleted == other.todayCompleted &&
          todayGoal == other.todayGoal;

  @override
  int get hashCode => Object.hash(totalWordsLearned, weeklyDelta, totalMastered,
      masteryPercent, currentStreak, todayCompleted, todayGoal);
}

/// 单日活动数据（趋势柱状图用）。
@immutable
class DailyActivity {
  /// 本地日期（仅 yyyy-MM-dd 部分有意义）
  final DateTime localDate;

  /// 当日新学完成词数（来自 word_records）
  final int newCount;

  /// 当日复习次数（来自 review_logs）
  final int reviewCount;

  const DailyActivity({
    required this.localDate,
    required this.newCount,
    required this.reviewCount,
  });

  int get total => newCount + reviewCount;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyActivity &&
          localDate == other.localDate &&
          newCount == other.newCount &&
          reviewCount == other.reviewCount;

  @override
  int get hashCode => Object.hash(localDate, newCount, reviewCount);
}

/// 年度热力图单元格。
@immutable
class HeatmapCell {
  /// 本地日期
  final DateTime localDate;

  /// 当日活动总数（new + review）
  final int count;

  /// 紫色梯度等级 0..4（0 = 无活动，4 = 最深）
  final int level;

  const HeatmapCell({
    required this.localDate,
    required this.count,
    required this.level,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HeatmapCell &&
          localDate == other.localDate &&
          count == other.count &&
          level == other.level;

  @override
  int get hashCode => Object.hash(localDate, count, level);
}

// ── Tab 2: 记忆分析 ─────────────────────────────────────────────────────────

/// 单个留存率桶。
@immutable
class RetentionBucket {
  /// 桶标签（"20分" / "1时" / "1天" 等）
  final String label;

  /// 桶中点的天数（用于 X 轴对数刻度位置）
  final double midDays;

  /// 用户实测留存率 (0..1)，样本数 < 3 时为 null（折线断开）
  final double? userRetention;

  /// 艾宾浩斯标准遗忘曲线值 (0..1) at midDays
  final double ebbinghaus;

  /// 桶中样本数
  final int sampleCount;

  const RetentionBucket({
    required this.label,
    required this.midDays,
    required this.userRetention,
    required this.ebbinghaus,
    required this.sampleCount,
  });
}

/// 词汇掌握等级分布（环形图）。
@immutable
class MasteryDistribution {
  /// 陌生：active book 内、还没有 card_state 的词数
  final int unfamiliar;

  /// 学习中：state IN (1, 3) 或 stability < 7
  final int learning;

  /// 熟悉：state == 2 AND 7 ≤ stability < 30
  final int familiar;

  /// 牢记：state == 2 AND stability ≥ 30
  final int mastered;

  const MasteryDistribution({
    required this.unfamiliar,
    required this.learning,
    required this.familiar,
    required this.mastered,
  });

  int get total => unfamiliar + learning + familiar + mastered;

  static const empty = MasteryDistribution(
    unfamiliar: 0,
    learning: 0,
    familiar: 0,
    mastered: 0,
  );

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is MasteryDistribution &&
          unfamiliar == other.unfamiliar &&
          learning == other.learning &&
          familiar == other.familiar &&
          mastered == other.mastered;

  @override
  int get hashCode => Object.hash(unfamiliar, learning, familiar, mastered);
}

/// 单日测试正确率（折线图用）。
@immutable
class DailyAccuracy {
  final DateTime localDate;

  /// 选义测试正确率 (0..1)；目前合并到一个 review_logs 来源
  final double? accuracy;

  /// 当日 review_logs 总数
  final int sampleCount;

  const DailyAccuracy({
    required this.localDate,
    required this.accuracy,
    required this.sampleCount,
  });
}

// ── Tab 3: 重点难点 ─────────────────────────────────────────────────────────

/// 顽固单词条目。
@immutable
class StubbornWord {
  final String wordId;
  final String wordText;
  final String meaning;
  final int lapses;
  final int reps;

  const StubbornWord({
    required this.wordId,
    required this.wordText,
    required this.meaning,
    required this.lapses,
    required this.reps,
  });

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is StubbornWord &&
          wordId == other.wordId &&
          wordText == other.wordText &&
          meaning == other.meaning &&
          lapses == other.lapses &&
          reps == other.reps;

  @override
  int get hashCode => Object.hash(wordId, wordText, meaning, lapses, reps);
}

/// 词性雷达图（4 项）。
@immutable
class PosRadarData {
  /// 名词
  final int noun;

  /// 动词（含 vt./vi./v.）
  final int verb;

  /// 形容词（含 a./adj.）
  final int adj;

  /// 副词
  final int adv;

  const PosRadarData({
    required this.noun,
    required this.verb,
    required this.adj,
    required this.adv,
  });

  int get total => noun + verb + adj + adv;

  static const empty = PosRadarData(noun: 0, verb: 0, adj: 0, adv: 0);

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is PosRadarData &&
          noun == other.noun &&
          verb == other.verb &&
          adj == other.adj &&
          adv == other.adv;

  @override
  int get hashCode => Object.hash(noun, verb, adj, adv);
}

// ── Tab 4: 激励成就 ─────────────────────────────────────────────────────────

/// 词汇增长预测。
@immutable
class VocabularyForecast {
  /// 已掌握词数
  final int currentMastered;

  /// 目标（active wordbook 总词数）
  final int targetTotal;

  /// 近 7 天日均新掌握数
  final double avgDailyNew;

  /// 预计还需天数（avg=0 时为 null）
  final int? daysRemaining;

  /// 预计达成日期（avg=0 时为 null）
  final DateTime? estimatedDate;

  const VocabularyForecast({
    required this.currentMastered,
    required this.targetTotal,
    required this.avgDailyNew,
    required this.daysRemaining,
    required this.estimatedDate,
  });

  double get progress => targetTotal == 0
      ? 0.0
      : (currentMastered / targetTotal).clamp(0.0, 1.0);
}

/// 勋章状态。
@immutable
class BadgeStatus {
  /// 唯一 id（用于持久化或追踪）
  final String id;

  /// 名称（"凌晨学习者"）
  final String title;

  /// 一行描述（"连续3天在23点后学习"）
  final String desc;

  /// 是否已解锁
  final bool unlocked;

  /// 进度 (0..1)，未解锁时显示
  final double progress;

  const BadgeStatus({
    required this.id,
    required this.title,
    required this.desc,
    required this.unlocked,
    required this.progress,
  });
}
