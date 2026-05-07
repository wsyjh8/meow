// PR-B3 Day 2 v0.2: WordbookLoader._clearContentTables D1 收口 — 2 cases.
//
// 关键策略 (v0.2 §"D1 收口策略 v0.2"):
//   - 本 book 有 manifest examples → 仅清 stable_id IS NULL legacy 行；
//     stable_id 非 null 的 bundle/manifest 行都保留
//   - 无 manifest → 4 张表全清 (PR-B2 之前行为)
//
// 测试用 assetLoader DI 注入 fake JSON (v0.2 #2 R1#2 review-adopted)，避开
// 仓内首次 setMockMessageHandler('flutter/assets') 的风险路径。

import 'dart:convert';

import 'package:drift/drift.dart' hide isNull, isNotNull;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:meow_mobile/core/memory/wordbook_loader.dart';
import 'package:meow_mobile/core/storage/drift/app_database.dart';

/// Build a minimal bundle JSON string with one word + one example row.
/// Mirrors `assets/words/{slug}.json` schema (per WordbookLoader._loadFromData).
String _bundleJson({
  required String contentVersion,
  required String wordId,
  required int exampleSortOrder,
  required String stableId,
  required String exampleEn,
}) =>
    jsonEncode({
      'displayName': '中考',
      'contentVersion': contentVersion,
      'words': [
        {
          'wordId': wordId,
          'wordText': wordId,
          'meaning': 'noun',
          'sortOrder': 0,
          'examples': [
            {
              'sense': 'noun',
              'en': exampleEn,
              'cn': '示例',
              'sortOrder': exampleSortOrder,
              'stableId': stableId,
            }
          ],
        }
      ],
    });

WordbookLoader _loader(AppDatabase db, Map<String, String> assets) {
  return WordbookLoader(
    db: db,
    assetLoader: (path) async {
      final v = assets[path];
      if (v == null) {
        throw Exception('fake asset not found: $path');
      }
      return v;
    },
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    db = AppDatabase.forTesting(NativeDatabase.memory());
  });
  tearDown(() async {
    await db.close();
  });

  group('WordbookLoader._clearContentTables D1 收口 v0.2 (PR-B3 Day 2)', () {
    test(
        'manifest examples present: stable_id 非 null 行（v3-bundle + manifest-row）'
        '保留；v4 用不冲突 sortOrder=2 写入；legacy null stable_id 清掉',
        () async {
      // 1. 模拟 bundle v3 已加载
      await db.into(db.presetWordbooks).insert(
            PresetWordbooksCompanion.insert(
              slug: 'zk',
              displayName: '中考',
              contentVersion: const Value('v3'),
            ),
          );
      await db.into(db.wordEntries).insert(
            WordEntriesCompanion.insert(
              wordId: 'apple',
              wordText: 'apple',
              meaning: 'noun',
              importedAt: 1,
            ),
          );
      await db.into(db.wordBookAssignments).insert(
            WordBookAssignmentsCompanion.insert(
              wordId: 'apple',
              bookSlug: 'zk',
              sortOrder: const Value(0),
            ),
          );
      // bundle 旧行：stable_id 非 null（v0.2 fixture 调整 R1#1）
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'V3 BUNDLE',
              cn: 'v3 例句',
              sortOrder: const Value(0),
              stableId: const Value('v3-bundle'),
            ),
          );
      // legacy null stable_id 行（v0.2 #4 R2#P1.3：覆盖 integrity 死循环修复）
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'LEGACY no-stableId',
              cn: '老',
              sortOrder: const Value(3),
              stableId: const Value.absent(),
            ),
          );

      // 2. 模拟 PackageInstaller 写 manifest examples 包（按本 book）
      await db.into(db.contentPackageStates).insert(
            ContentPackageStatesCompanion.insert(
              packageId: 'examples-zk@v1',
              packageName: 'examples-zk',
              packageKind: 'examples',
              contentVersion: 'v1',
              releaseId: 'rel-1',
              checksumSha256: 'h',
              installedAt: 1,
            ),
          );
      // manifest 行：(apple, sortOrder=1) 与 bundle (apple, 0) 不冲突
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'MANIFEST example',
              cn: '清单例句',
              sortOrder: const Value(1),
              stableId: const Value('manifest-row'),
            ),
          );

      // 3. bundle v4 升级（v4 新增一条 example，sortOrder=2 不冲突任何已有行）
      final assets = {
        'assets/words/zk.json': _bundleJson(
          contentVersion: 'v4',
          wordId: 'apple',
          exampleSortOrder: 2,
          stableId: 'v4-bundle',
          exampleEn: 'V4 BUNDLE NEW',
        ),
      };

      // 4. loadIfNeeded → 触发 D1 收口分支（_hasManifestExamplesForBook=true）
      await _loader(db, assets).loadIfNeeded('zk');

      // 5. 断言
      final rows = await db.select(db.exampleSentences).get();
      final stableIds = rows.map((r) => r.stableId).toSet();

      // (a) manifest-row 保留（D1 收口主目标）
      expect(stableIds, contains('manifest-row'),
          reason: 'manifest-installed row must survive (D1 收口 主目标)');
      // (b) v3-bundle 保留（D1 收口副作用：stable_id 非 null 的 bundle 行也留下）
      expect(stableIds, contains('v3-bundle'),
          reason: 'non-null stable_id bundle row preserved (D1 收口 副作用)');
      // (c) v4-bundle 写入成功（sortOrder=2 不冲突，stable_id 不冲突）
      expect(stableIds, contains('v4-bundle'),
          reason:
              'v4 bundle row with non-conflicting sort_order writes through');
      // (d) legacy null stable_id 清掉（避免 integrity backstop 死循环；R2#P1.3）
      final nullCount = rows.where((r) => r.stableId == null).length;
      expect(nullCount, 0,
          reason: 'legacy null stable_id rows must be cleared even in D1 收口');

      // (e) preset_wordbooks 升到 v4
      final pw = await db.select(db.presetWordbooks).get();
      expect(pw.single.contentVersion, 'v4');
    });

    test(
        'no manifest data: classic clear-and-reload (PR-B2 之前行为不变)',
        () async {
      // 1. bundle v3 状态
      await db.into(db.presetWordbooks).insert(
            PresetWordbooksCompanion.insert(
              slug: 'zk',
              displayName: '中考',
              contentVersion: const Value('v3'),
            ),
          );
      await db.into(db.wordEntries).insert(
            WordEntriesCompanion.insert(
              wordId: 'apple',
              wordText: 'apple',
              meaning: 'noun',
              importedAt: 1,
            ),
          );
      await db.into(db.exampleSentences).insert(
            ExampleSentencesCompanion.insert(
              wordId: 'apple',
              sense: 'noun',
              en: 'V3 BUNDLE',
              cn: 'v3',
              sortOrder: const Value(0),
              stableId: const Value('v3-bundle'),
            ),
          );

      // 2. content_package_state 为空
      expect(await db.select(db.contentPackageStates).get(), isEmpty);

      // 3. bundle v4
      final assets = {
        'assets/words/zk.json': _bundleJson(
          contentVersion: 'v4',
          wordId: 'apple',
          exampleSortOrder: 0,
          stableId: 'v4-bundle',
          exampleEn: 'V4 BUNDLE',
        ),
      };

      // 4. loadIfNeeded → 走经典清表分支（_hasManifestExamplesForBook=false）
      await _loader(db, assets).loadIfNeeded('zk');

      // 5. v3 行被清；只剩 v4 行（PR-B2 之前行为；regression）
      final rows = await db.select(db.exampleSentences).get();
      expect(rows, hasLength(1));
      expect(rows.first.stableId, 'v4-bundle');
    });
  });
}
