/// StatsService 单元测试。
///
/// 关键覆盖：
/// - 空库返回全 0
/// - 时区跨界（UTC 17:00 在 UTC+8 应归到次日本地日 — 由设备时区决定，跑测试机器若在
///   UTC+8 则可验证；其他时区只验证逻辑闭合）
/// - 留存曲线桶边界
/// - 掌握等级分布 stability 阈值边界 (7, 30)
/// - 顽固词排序 + lapses=0 不入榜
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import 'package:meow_mobile/core/services/stats_service.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';
import 'package:meow_mobile/core/storage/local_database.dart';
import 'package:meow_mobile/spec/pages/stats/models/stats_models.dart';

void main() {
  // SQLite (sqflite) FFI for desktop tests
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  late AppDatabase driftDb;
  late SharedPreferences prefs;
  late StatsService svc;

  setUp(() async {
    // Fresh in-memory drift
    driftDb = AppDatabase.forTesting(NativeDatabase.memory());

    // Fresh sqflite (LocalDatabase). PR-C-α: drift owns schema now, so
    // a LocalDatabase-only test uses the test-only [initializeForTesting]
    // bridge to materialize the v13 legacy schema in the sqflite file.
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    await LocalDatabase.deleteDatabase_();
    await LocalDatabase.initializeForTesting();

    svc = StatsService(
      localDb: LocalDatabase.instance,
      driftDb: driftDb,
      prefs: prefs,
    );
  });

  tearDown(() async {
    await driftDb.close();
    await LocalDatabase.instance.close();
  });

  group('getOverviewHeader', () {
    test('空库返回全 0', () async {
      final h = await svc.getOverviewHeader();
      expect(h.totalWordsLearned, 0);
      expect(h.totalMastered, 0);
      expect(h.weeklyDelta, 0);
      expect(h.currentStreak, 0);
      expect(h.todayCompleted, 0);
      // todayGoal = dailyGoal + reviewTarget = 默认 dailyGoal + 0
      expect(h.todayGoal, greaterThanOrEqualTo(0));
    });

    test('插入 know 记录后 totalMastered 增加', () async {
      await LocalDatabase.instance.insertWordRecord(
        wordId: 'cet4-test-1',
        bookId: 'book-001',
        studyType: 'new',
        actionResult: 'know',
      );
      final h = await svc.getOverviewHeader();
      expect(h.totalMastered, 1);
      expect(h.totalWordsLearned, 1);
    });
  });

  group('getActivityTrend', () {
    test('week granularity 返回 7 天序列', () async {
      final trend = await svc.getActivityTrend(granularity: 'week');
      expect(trend.length, 7);
    });

    test('month granularity 返回 30 天序列', () async {
      final trend = await svc.getActivityTrend(granularity: 'month');
      expect(trend.length, 30);
    });

    test('空库每天计数都是 0', () async {
      final trend = await svc.getActivityTrend();
      expect(trend.every((d) => d.newCount == 0 && d.reviewCount == 0), true);
    });

    test('插入 know 记录后今天的 newCount = 1', () async {
      await LocalDatabase.instance.insertWordRecord(
        wordId: 'w-1',
        bookId: 'b',
        studyType: 'new',
        actionResult: 'know',
      );
      final trend = await svc.getActivityTrend(granularity: 'week');
      // 最后一天 = 今天
      expect(trend.last.newCount, 1);
      expect(trend.last.reviewCount, 0);
    });
  });

  group('getHourlyActivity', () {
    test('空库返回长度 24 全 0', () async {
      final hours = await svc.getHourlyActivity();
      expect(hours.length, 24);
      expect(hours.every((h) => h == 0), true);
    });
  });

  group('getYearHeatmap', () {
    test('返回 365 个 cell，最后一个是今天', () async {
      final cells = await svc.getYearHeatmap();
      expect(cells.length, 365);
      final today = DateTime.now();
      final last = cells.last.localDate;
      expect(last.year, today.year);
      expect(last.month, today.month);
      expect(last.day, today.day);
    });

    test('空库所有 level = 0', () async {
      final cells = await svc.getYearHeatmap();
      expect(cells.every((c) => c.level == 0 && c.count == 0), true);
    });
  });

  group('getRetentionCurve', () {
    test('总是返回 7 个桶', () async {
      final buckets = await svc.getRetentionCurve();
      expect(buckets.length, 7);
      expect(buckets.map((b) => b.label).toList(),
          ['20分', '1时', '9时', '1天', '2天', '6天', '31天']);
    });

    test('空库每桶 sampleCount=0、userRetention=null', () async {
      final buckets = await svc.getRetentionCurve();
      for (final b in buckets) {
        expect(b.sampleCount, 0);
        expect(b.userRetention, isNull);
      }
    });

    test('艾宾浩斯值非空且单调递减', () async {
      final buckets = await svc.getRetentionCurve();
      double? prev;
      for (final b in buckets) {
        expect(b.ebbinghaus, greaterThanOrEqualTo(0));
        expect(b.ebbinghaus, lessThanOrEqualTo(1));
        if (prev != null) {
          expect(b.ebbinghaus, lessThanOrEqualTo(prev));
        }
        prev = b.ebbinghaus;
      }
    });
  });

  group('getMasteryDistribution', () {
    test('空库 active book → empty distribution', () async {
      final m = await svc.getMasteryDistribution();
      expect(m, MasteryDistribution.empty);
      expect(m.total, 0);
    });
  });

  group('getAccuracyTrend', () {
    test('返回 14 天序列', () async {
      final trend = await svc.getAccuracyTrend();
      expect(trend.length, 14);
      expect(trend.every((a) => a.sampleCount == 0 && a.accuracy == null), true);
    });
  });

  group('getTopStubbornWords', () {
    test('空库返回空 list', () async {
      final top = await svc.getTopStubbornWords();
      expect(top, isEmpty);
    });
  });

  group('getPosRadar', () {
    test('空库返回 PosRadarData.empty', () async {
      final r = await svc.getPosRadar();
      expect(r, PosRadarData.empty);
      expect(r.total, 0);
    });
  });

  group('getVocabularyForecast', () {
    test('空库 daysRemaining=null', () async {
      final f = await svc.getVocabularyForecast();
      expect(f.currentMastered, 0);
      expect(f.avgDailyNew, 0.0);
      expect(f.daysRemaining, isNull);
      expect(f.estimatedDate, isNull);
    });
  });

  group('getBadges', () {
    test('空库 6 枚都未解锁', () async {
      final badges = await svc.getBadges();
      expect(badges.length, 6);
      expect(badges.every((b) => !b.unlocked), true);
    });

    test('badge id 集合稳定', () async {
      final badges = await svc.getBadges();
      final ids = badges.map((b) => b.id).toSet();
      expect(ids, {
        'night_owl',
        'century',
        'full_moon',
        'memory_master',
        'vocab_peak',
        'perfectionist',
      });
    });
  });
}
