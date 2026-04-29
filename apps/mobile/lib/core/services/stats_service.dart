import 'dart:math' as math;

import 'package:drift/drift.dart' show Variable;
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/drift/app_database.dart';
import '../storage/local_database.dart';
import '../storage/local_settings_service.dart';
import '../../spec/pages/stats/models/stats_models.dart';

/// 统计服务 — 集中所有统计页跨表查询。
///
/// 设计要点：
/// - 外部注入 [AppDatabase] / [LocalDatabase] / [SharedPreferences]，避免新建多
///   instance 引发 Drift 警告
/// - 所有"按本地日分组"在 Dart 侧 `.toLocal()` 后字符串化，**禁用** SQLite `date()`
/// - new 计数源 = `word_records WHERE study_type='new' AND action_result='know'`
/// - review 计数源 = `review_logs`（FSRS 真相，避免与 word_records 重复计数）
class StatsService {
  final LocalDatabase _localDb;
  final AppDatabase _driftDb;
  final SharedPreferences _prefs;

  StatsService({
    required LocalDatabase localDb,
    required AppDatabase driftDb,
    required SharedPreferences prefs,
  })  : _localDb = localDb,
        _driftDb = driftDb,
        _prefs = prefs;

  // ── Tab 1: 概览趋势 ────────────────────────────────────────────────────────

  /// 4 数字卡 + 顶部 hero 数据。
  Future<OverviewHeader> getOverviewHeader() async {
    // 累计学习的不同词数（不限本词书）
    final masteredIds = await _localDb.getMasteredWordIds();
    final totalMastered = masteredIds.length;

    // 累计学习数 = 所有 word_records 的 distinct word_id
    final allLearnedRows = await _localDb.db.rawQuery(
      'SELECT COUNT(DISTINCT word_id) AS cnt FROM word_records',
    );
    final totalWordsLearned = (allLearnedRows.first['cnt'] as int?) ?? 0;

    // 较上周 = 7 天前到现在新增的 distinct word_id 数
    final now = DateTime.now();
    final sevenDaysAgoUtc =
        DateTime(now.year, now.month, now.day).subtract(const Duration(days: 7));
    final weeklyRows = await _localDb.db.rawQuery(
      'SELECT COUNT(DISTINCT word_id) AS cnt FROM word_records '
      "WHERE study_type='new' AND action_result='know' AND created_at >= ?",
      [sevenDaysAgoUtc.toUtc().toIso8601String()],
    );
    final weeklyDelta = (weeklyRows.first['cnt'] as int?) ?? 0;

    // 总词数 / mastery 百分比 = active wordbook
    final activeBook = LocalSettingsService(_prefs).activeWordbook;
    final totalInBook = await _driftDb.countWordsInBook(activeBook);
    final bookWordIds = await _driftDb.getWordIdsForBook(activeBook);
    final bookMastered = masteredIds.intersection(bookWordIds).length;
    final masteryPercent =
        totalInBook == 0 ? 0 : (bookMastered * 100 / totalInBook).round();

    // 连续打卡天数（基于 daily_checkins，与 LocalTodayService 对齐）
    final streak = await _computeStreak();

    // 今日完成 / 目标
    final todayNew = await _localDb.countTodayNewCompleted();
    int todayReview = 0;
    int reviewTarget = 0;
    try {
      todayReview = await _countTodayReviewLogs();
      // 目标：FSRS 当下到期数 + 已复习数
      final dueCount = await _countDueCardsNow();
      reviewTarget = dueCount + todayReview;
    } catch (_) {}
    final dailyGoal = LocalSettingsService(_prefs).dailyGoal;
    final todayCompleted = todayNew + todayReview;
    final todayGoal = dailyGoal + reviewTarget;

    return OverviewHeader(
      totalWordsLearned: totalWordsLearned,
      weeklyDelta: weeklyDelta,
      totalMastered: totalMastered,
      masteryPercent: masteryPercent,
      currentStreak: streak,
      todayCompleted: todayCompleted,
      todayGoal: todayGoal,
    );
  }

  /// 周/月趋势 —— 返回最近 [days] 天每天的 (newCount, reviewCount)。
  ///
  /// granularity = 'week' → 7 天；'month' → 30 天。
  Future<List<DailyActivity>> getActivityTrend({
    String granularity = 'week',
  }) async {
    final days = granularity == 'month' ? 30 : 7;
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final startLocal = todayLocal.subtract(Duration(days: days - 1));
    final startUtcIso = startLocal.toUtc().toIso8601String();

    // ── 新词：word_records ────────────────────────────────────────────────
    final newRows = await _localDb.db.rawQuery(
      'SELECT created_at FROM word_records '
      "WHERE study_type='new' AND action_result='know' AND created_at >= ?",
      [startUtcIso],
    );
    final newByDay = <String, int>{};
    for (final r in newRows) {
      final localDate = DateTime.parse(r['created_at'] as String).toLocal();
      final key = _dateKey(localDate);
      newByDay[key] = (newByDay[key] ?? 0) + 1;
    }

    // ── 复习：review_logs ─────────────────────────────────────────────────
    final startUtcMs = startLocal.toUtc().millisecondsSinceEpoch;
    final reviewRows = await _driftDb.customSelect(
      'SELECT review_time_utc FROM review_logs WHERE review_time_utc >= ?',
      variables: [Variable.withInt(startUtcMs)],
    ).get();
    final reviewByDay = <String, int>{};
    for (final r in reviewRows) {
      final ms = r.read<int>('review_time_utc');
      final localDate = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      final key = _dateKey(localDate);
      reviewByDay[key] = (reviewByDay[key] ?? 0) + 1;
    }

    // ── 合并到完整 [days] 天序列（缺失日填 0）──────────────────────────
    final result = <DailyActivity>[];
    for (var i = 0; i < days; i++) {
      final d = startLocal.add(Duration(days: i));
      final key = _dateKey(d);
      result.add(DailyActivity(
        localDate: d,
        newCount: newByDay[key] ?? 0,
        reviewCount: reviewByDay[key] ?? 0,
      ));
    }
    return result;
  }

  /// 24 小时活跃次数：基于 `review_logs.review_time_utc`，转本地时区分桶。
  /// 默认采样近 30 天。返回长度 24 的列表，下标 = 本地小时 (0..23)。
  Future<List<int>> getHourlyActivity({int days = 30}) async {
    final now = DateTime.now();
    final startLocal = DateTime(now.year, now.month, now.day)
        .subtract(Duration(days: days - 1));
    final startUtcMs = startLocal.toUtc().millisecondsSinceEpoch;

    final rows = await _driftDb.customSelect(
      'SELECT review_time_utc FROM review_logs WHERE review_time_utc >= ?',
      variables: [Variable.withInt(startUtcMs)],
    ).get();

    final hours = List<int>.filled(24, 0);
    for (final r in rows) {
      final ms = r.read<int>('review_time_utc');
      final localDt = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      hours[localDt.hour] += 1;
    }
    return hours;
  }

  /// 365 天年度热力图。返回 365 个 [HeatmapCell]，从 [今天 - 364] 到 [今天]。
  Future<List<HeatmapCell>> getYearHeatmap() async {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final startLocal = todayLocal.subtract(const Duration(days: 364));
    final startUtcIso = startLocal.toUtc().toIso8601String();
    final startUtcMs = startLocal.toUtc().millisecondsSinceEpoch;

    // word_records (new + know)
    final wrRows = await _localDb.db.rawQuery(
      'SELECT created_at FROM word_records '
      "WHERE study_type='new' AND action_result='know' AND created_at >= ?",
      [startUtcIso],
    );
    // review_logs
    final rlRows = await _driftDb.customSelect(
      'SELECT review_time_utc FROM review_logs WHERE review_time_utc >= ?',
      variables: [Variable.withInt(startUtcMs)],
    ).get();

    final countByDay = <String, int>{};
    for (final r in wrRows) {
      final localDate = DateTime.parse(r['created_at'] as String).toLocal();
      final key = _dateKey(localDate);
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }
    for (final r in rlRows) {
      final ms = r.read<int>('review_time_utc');
      final localDate =
          DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      final key = _dateKey(localDate);
      countByDay[key] = (countByDay[key] ?? 0) + 1;
    }

    // 5 档紫色梯度阈值
    final cells = <HeatmapCell>[];
    for (var i = 0; i < 365; i++) {
      final d = startLocal.add(Duration(days: i));
      final key = _dateKey(d);
      final count = countByDay[key] ?? 0;
      cells.add(HeatmapCell(
        localDate: d,
        count: count,
        level: _bucketLevel(count),
      ));
    }
    return cells;
  }

  // ── Tab 2: 记忆分析 ────────────────────────────────────────────────────────

  /// 遗忘曲线 / 记忆留存率：基于 `review_logs.elapsed_days` 分 7 桶。
  ///
  /// 每桶: userRetention = COUNT(rating ≥ 3) / COUNT(*)；样本 < 3 时为 null。
  /// 同时给出艾宾浩斯标准曲线值 R(t) = exp(-t / 1.0) 在桶中点的取值。
  Future<List<RetentionBucket>> getRetentionCurve() async {
    final rows = await _driftDb.customSelect(
      'SELECT elapsed_days, rating FROM review_logs WHERE elapsed_days > 0',
    ).get();

    // 桶定义：(label, midDays, lower, upper)
    const buckets = [
      ('20分', 0.014, 0.0, 0.021),
      ('1时', 0.042, 0.021, 0.083),
      ('9时', 0.292, 0.083, 0.5),
      ('1天', 1.0, 0.5, 1.5),
      ('2天', 2.5, 1.5, 4.0),
      ('6天', 9.0, 4.0, 15.0),
      ('31天', 30.0, 15.0, double.infinity),
    ];
    // 累加每桶 (correct, total)
    final counts = List<List<int>>.generate(buckets.length, (_) => [0, 0]);
    for (final r in rows) {
      final ed = r.read<double>('elapsed_days');
      final rating = r.read<int>('rating');
      for (var i = 0; i < buckets.length; i++) {
        final (_, _, lo, hi) = buckets[i];
        if (ed > lo && ed <= hi) {
          counts[i][1] += 1; // total
          if (rating >= 3) counts[i][0] += 1; // correct
          break;
        }
      }
    }
    return List.generate(buckets.length, (i) {
      final (label, mid, _, _) = buckets[i];
      final correct = counts[i][0];
      final total = counts[i][1];
      // Ebbinghaus R(t) = exp(-t / S), S=1.0 (天)
      final ebb = _ebbinghaus(mid);
      return RetentionBucket(
        label: label,
        midDays: mid,
        userRetention: total >= 3 ? correct / total : null,
        ebbinghaus: ebb,
        sampleCount: total,
      );
    });
  }

  /// 词汇掌握等级分布（环形图）：陌生 / 学习中 / 熟悉 / 牢记。
  ///
  /// 阈值（FROZEN）：
  ///   陌生 = active book 总词数 - card_states 中本书命中数
  ///   学习中 = state IN (1, 3) 或 stability < 7
  ///   熟悉 = state == 2 AND 7 ≤ stability < 30
  ///   牢记 = state == 2 AND stability ≥ 30
  Future<MasteryDistribution> getMasteryDistribution() async {
    final activeBook = LocalSettingsService(_prefs).activeWordbook;
    final total = await _driftDb.countWordsInBook(activeBook);
    if (total == 0) return MasteryDistribution.empty;

    final bookIds = await _driftDb.getWordIdsForBook(activeBook);

    // 全量 SELECT card_states，内存交集（避免 SQLite IN 999 限制）
    final csRows = await _driftDb.customSelect(
      'SELECT word_id, state, stability FROM card_states',
    ).get();

    var learning = 0, familiar = 0, mastered = 0;
    final hitIds = <String>{};
    for (final r in csRows) {
      final wid = r.read<String>('word_id');
      if (!bookIds.contains(wid)) continue;
      hitIds.add(wid);
      final state = r.read<int>('state');
      final stability = r.readNullable<double>('stability') ?? 0.0;
      if (state == 1 || state == 3 || stability < 7) {
        learning++;
      } else if (state == 2 && stability < 30) {
        familiar++;
      } else if (state == 2 && stability >= 30) {
        mastered++;
      } else {
        learning++; // fallback
      }
    }
    final unfamiliar = total - hitIds.length;
    return MasteryDistribution(
      unfamiliar: unfamiliar < 0 ? 0 : unfamiliar,
      learning: learning,
      familiar: familiar,
      mastered: mastered,
    );
  }

  /// 测试正确率趋势：近 [days] 天每天 review_logs 的 (rating ≥ 3) 占比。
  Future<List<DailyAccuracy>> getAccuracyTrend({int days = 14}) async {
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final startLocal = todayLocal.subtract(Duration(days: days - 1));
    final startUtcMs = startLocal.toUtc().millisecondsSinceEpoch;

    final rows = await _driftDb.customSelect(
      'SELECT review_time_utc, rating FROM review_logs WHERE review_time_utc >= ?',
      variables: [Variable.withInt(startUtcMs)],
    ).get();

    // 按本地日累加 (correct, total)
    final byDay = <String, List<int>>{};
    for (final r in rows) {
      final ms = r.read<int>('review_time_utc');
      final localDate =
          DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      final key = _dateKey(localDate);
      final entry = byDay.putIfAbsent(key, () => [0, 0]);
      entry[1] += 1; // total
      if (r.read<int>('rating') >= 3) entry[0] += 1; // correct
    }

    final result = <DailyAccuracy>[];
    for (var i = 0; i < days; i++) {
      final d = startLocal.add(Duration(days: i));
      final key = _dateKey(d);
      final entry = byDay[key];
      if (entry == null || entry[1] == 0) {
        result.add(DailyAccuracy(localDate: d, accuracy: null, sampleCount: 0));
      } else {
        result.add(DailyAccuracy(
          localDate: d,
          accuracy: entry[0] / entry[1],
          sampleCount: entry[1],
        ));
      }
    }
    return result;
  }

  /// 艾宾浩斯遗忘曲线：R(t) = exp(-t / S)，S=1.0 (默认稳定常数，单位天)。
  static double _ebbinghaus(double days, {double s = 1.0}) {
    final r = -days / s;
    if (r < -100) return 0.0;
    return math.exp(r).clamp(0.0, 1.0);
  }

  // ── 私有辅助 ───────────────────────────────────────────────────────────────

  /// 复用 LocalTodayService 的 streak 算法（基于 daily_checkins 倒序扫描）。
  Future<int> _computeStreak() async {
    final rows = await _driftDb.customSelect(
      'SELECT date FROM daily_checkins ORDER BY date DESC',
    ).get();
    if (rows.isEmpty) return 0;

    final today = _todayLocalDateString();
    final yesterday = _dateKey(
      DateTime.now().subtract(const Duration(days: 1)),
    );

    // 第一天必须是今天或昨天，否则 streak = 0
    final firstDate = rows.first.read<String>('date');
    if (firstDate != today && firstDate != yesterday) return 0;

    int streak = 0;
    var expected = DateTime.parse(firstDate);
    for (final r in rows) {
      final d = DateTime.parse(r.read<String>('date'));
      if (_dateKey(d) != _dateKey(expected)) break;
      streak++;
      expected = expected.subtract(const Duration(days: 1));
    }
    return streak;
  }

  /// 今日复习次数：`review_logs` 中 review_time_utc 落在本地今日的行数。
  Future<int> _countTodayReviewLogs() async {
    final now = DateTime.now();
    final localMidnight = DateTime(now.year, now.month, now.day);
    final startMs = localMidnight.toUtc().millisecondsSinceEpoch;
    final endMs = localMidnight
        .add(const Duration(days: 1))
        .toUtc()
        .millisecondsSinceEpoch;
    final rows = await _driftDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM review_logs '
      'WHERE review_time_utc >= ? AND review_time_utc < ?',
      variables: [Variable.withInt(startMs), Variable.withInt(endMs)],
    ).get();
    return rows.first.read<int>('cnt');
  }

  /// 当下到期复习卡片数（card_states.due ≤ 现在）。
  Future<int> _countDueCardsNow() async {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final rows = await _driftDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM card_states WHERE due <= ?',
      variables: [Variable.withInt(nowMs)],
    ).get();
    return rows.first.read<int>('cnt');
  }

  /// 计数 → 5 档紫色梯度等级 [0..4]。
  /// 0 = 无活动；1-4 按经验阈值划分。
  static int _bucketLevel(int count) {
    if (count == 0) return 0;
    if (count <= 5) return 1;
    if (count <= 15) return 2;
    if (count <= 30) return 3;
    return 4;
  }

  static String _dateKey(DateTime d) {
    final m = d.month.toString().padLeft(2, '0');
    final day = d.day.toString().padLeft(2, '0');
    return '${d.year}-$m-$day';
  }

  static String _todayLocalDateString() {
    final now = DateTime.now();
    return _dateKey(DateTime(now.year, now.month, now.day));
  }
}
