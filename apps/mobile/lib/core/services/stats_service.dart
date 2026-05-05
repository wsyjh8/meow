import 'dart:math' as math;

import 'package:drift/drift.dart' show Variable;
import 'package:shared_preferences/shared_preferences.dart';

import '../storage/drift/app_database.dart';
import '../storage/local_database.dart';
import '../storage/local_settings_service.dart';
import '../util/pos_label.dart';
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

  // ── Tab 3: 重点难点 ────────────────────────────────────────────────────────

  /// Top N 顽固单词：按 lapses DESC, reps ASC 排序。
  ///
  /// v0.3.0 P1: 单一 word_entries 查 word_text + meaning（CET-4 / ZK / GK 统一表）。
  /// lapses=0 不入榜。
  Future<List<StubbornWord>> getTopStubbornWords({int limit = 10}) async {
    final csRows = await _driftDb.customSelect(
      'SELECT word_id, lapses, reps FROM card_states '
      'WHERE lapses > 0 '
      'ORDER BY lapses DESC, reps ASC '
      'LIMIT ?',
      variables: [Variable.withInt(limit)],
    ).get();
    if (csRows.isEmpty) return [];

    final wordIds = csRows.map((r) => r.read<String>('word_id')).toList();
    final wePh = wordIds.map((_) => '?').join(', ');
    final weRows = await _driftDb.customSelect(
      'SELECT word_id, word_text, meaning FROM word_entries WHERE word_id IN ($wePh)',
      variables: wordIds.map(Variable.withString).toList(),
    ).get();
    final wordMap = <String, (String, String)>{};
    for (final r in weRows) {
      wordMap[r.read<String>('word_id')] =
          (r.read<String>('word_text'), r.read<String>('meaning'));
    }

    return csRows
        .map((r) {
          final wid = r.read<String>('word_id');
          final tuple = wordMap[wid];
          if (tuple == null) return null;
          return StubbornWord(
            wordId: wid,
            wordText: tuple.$1,
            meaning: tuple.$2,
            lapses: r.read<int>('lapses'),
            reps: r.read<int>('reps'),
          );
        })
        .whereType<StubbornWord>()
        .toList();
  }

  /// 词性雷达图（4 项）：基于已掌握单词集 (word_records WHERE action_result='know')。
  Future<PosRadarData> getPosRadar() async {
    final masteredIds = (await _localDb.getMasteredWordIds()).toList();
    if (masteredIds.isEmpty) return PosRadarData.empty;

    final translations = await _driftDb.getTranslationsForIds(masteredIds);
    var noun = 0, verb = 0, adj = 0, adv = 0;
    for (final t in translations.values) {
      switch (posCategoryOf(t)) {
        case PosCategory.noun: noun++; break;
        case PosCategory.verb: verb++; break;
        case PosCategory.adj: adj++; break;
        case PosCategory.adv: adv++; break;
        case PosCategory.other: break;
      }
    }
    return PosRadarData(noun: noun, verb: verb, adj: adj, adv: adv);
  }

  // ── Tab 4: 激励成就 ────────────────────────────────────────────────────────

  /// 词汇增长预测：当前掌握 / 目标 (active book 总词) / 近 7 天日均 →
  /// 预计还需天数 + 预计达成日。
  Future<VocabularyForecast> getVocabularyForecast() async {
    final activeBook = LocalSettingsService(_prefs).activeWordbook;
    final target = await _driftDb.countWordsInBook(activeBook);
    final masteredIds = await _localDb.getMasteredWordIds();
    final bookWordIds = await _driftDb.getWordIdsForBook(activeBook);
    final bookMastered = masteredIds.intersection(bookWordIds).length;

    // 近 7 天日均新掌握数
    final now = DateTime.now();
    final todayLocal = DateTime(now.year, now.month, now.day);
    final sevenAgo = todayLocal.subtract(const Duration(days: 7));
    final rows = await _localDb.db.rawQuery(
      'SELECT COUNT(DISTINCT word_id) AS cnt FROM word_records '
      "WHERE study_type='new' AND action_result='know' AND created_at >= ?",
      [sevenAgo.toUtc().toIso8601String()],
    );
    final last7 = (rows.first['cnt'] as int?) ?? 0;
    final avgDaily = last7 / 7.0;

    final remaining = target - bookMastered;
    if (avgDaily <= 0 || remaining <= 0) {
      return VocabularyForecast(
        currentMastered: bookMastered,
        targetTotal: target,
        avgDailyNew: avgDaily,
        daysRemaining: null,
        estimatedDate: null,
      );
    }
    final daysNeeded = (remaining / avgDaily).ceil();
    final estDate = todayLocal.add(Duration(days: daysNeeded));
    return VocabularyForecast(
      currentMastered: bookMastered,
      targetTotal: target,
      avgDailyNew: avgDaily,
      daysRemaining: daysNeeded,
      estimatedDate: estDate,
    );
  }

  /// 6 枚勋章状态。规则与 plan 文件一致。
  Future<List<BadgeStatus>> getBadges() async {
    // ── 满月战士：streak ≥ 30 ─────────────────────────────────────────────
    final streak = await _computeStreak();

    // ── 记忆大师：card_states.stability ≥ 30 计数 ≥ 1000 ─────────────────
    final masterRows = await _driftDb.customSelect(
      'SELECT COUNT(*) AS cnt FROM card_states WHERE stability >= 30',
    ).get();
    final masterCount = masterRows.first.read<int>('cnt');

    // ── 百日斩：单日 word_records new+know 计数 ≥ 100 ─────────────────────
    final allWrRows = await _localDb.db.rawQuery(
      'SELECT created_at FROM word_records '
      "WHERE study_type='new' AND action_result='know'",
    );
    final byDay = <String, int>{};
    for (final r in allWrRows) {
      final localDate = DateTime.parse(r['created_at'] as String).toLocal();
      final key = _dateKey(localDate);
      byDay[key] = (byDay[key] ?? 0) + 1;
    }
    final maxDaily = byDay.values.fold<int>(0, (a, b) => a > b ? a : b);

    // ── 凌晨学习者：近 7 天 review_logs 在本地 23:00–04:00 不同日 ≥ 3 ───
    final now = DateTime.now();
    final sevenAgoUtcMs = DateTime(now.year, now.month, now.day)
        .subtract(const Duration(days: 7))
        .toUtc()
        .millisecondsSinceEpoch;
    final rlRows = await _driftDb.customSelect(
      'SELECT review_time_utc FROM review_logs WHERE review_time_utc >= ?',
      variables: [Variable.withInt(sevenAgoUtcMs)],
    ).get();
    final nightDays = <String>{};
    for (final r in rlRows) {
      final ms = r.read<int>('review_time_utc');
      final localDt =
          DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
      if (localDt.hour >= 23 || localDt.hour < 4) {
        nightDays.add(_dateKey(localDt));
      }
    }

    // ── 完美主义：连续 7 个本地日，每天 review_logs 中 rating=4 占比 = 1.0
    //   且当日 ≥ 1 条 ─────────────────────────────────────────────────────
    int perfectDays = 0;
    final rlWithRating = await _driftDb.customSelect(
      'SELECT review_time_utc, rating FROM review_logs '
      'WHERE review_time_utc >= ?',
      variables: [Variable.withInt(sevenAgoUtcMs)],
    ).get();
    if (rlWithRating.isNotEmpty) {
      // 按本地日分组 (count4, total)
      final perDay = <String, List<int>>{};
      for (final r in rlWithRating) {
        final ms = r.read<int>('review_time_utc');
        final localDt =
            DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true).toLocal();
        final key = _dateKey(localDt);
        final entry = perDay.putIfAbsent(key, () => [0, 0]);
        entry[1] += 1;
        if (r.read<int>('rating') == 4) entry[0] += 1;
      }
      // 检查最近 7 天是否都满足
      final today = DateTime(now.year, now.month, now.day);
      var consecutive = 0;
      for (var i = 0; i < 7; i++) {
        final d = today.subtract(Duration(days: i));
        final key = _dateKey(d);
        final entry = perDay[key];
        if (entry != null && entry[1] > 0 && entry[0] == entry[1]) {
          consecutive++;
        } else {
          break;
        }
      }
      perfectDays = consecutive;
    }

    // ── 词汇巅峰：暂无 ky 词库 → 永远未解锁 ──────────────────────────────
    // (按计划文件，目前 active book 是 book-001/zk/gk，没有 ky 数据)

    return [
      BadgeStatus(
        id: 'night_owl',
        title: '凌晨学习者',
        desc: '连续3天在23点后学习',
        unlocked: nightDays.length >= 3,
        progress: (nightDays.length / 3).clamp(0.0, 1.0),
      ),
      BadgeStatus(
        id: 'century',
        title: '百日斩',
        desc: '单日学习超过100词',
        unlocked: maxDaily >= 100,
        progress: (maxDaily / 100).clamp(0.0, 1.0),
      ),
      BadgeStatus(
        id: 'full_moon',
        title: '满月战士',
        desc: '连续打卡满30天',
        unlocked: streak >= 30,
        progress: (streak / 30).clamp(0.0, 1.0),
      ),
      BadgeStatus(
        id: 'memory_master',
        title: '记忆大师',
        desc: '掌握词汇突破1000',
        unlocked: masterCount >= 1000,
        progress: (masterCount / 1000).clamp(0.0, 1.0),
      ),
      const BadgeStatus(
        id: 'vocab_peak',
        title: '词汇巅峰',
        desc: '完成考研词库（未解锁）',
        unlocked: false,
        progress: 0.0,
      ),
      BadgeStatus(
        id: 'perfectionist',
        title: '完美主义',
        desc: '连续7天正确率100%',
        unlocked: perfectDays >= 7,
        progress: (perfectDays / 7).clamp(0.0, 1.0),
      ),
    ];
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
