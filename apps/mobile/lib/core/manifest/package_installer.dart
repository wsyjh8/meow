// PR-B2 Day 2 v0.2: gzip → drift install for examples kind.
//
// Per master plan v0.4 + Day 2 plan v0.2 review-adopted decisions:
//   #1 (R1#1/R2#1): _upsertPackageState uses DELETE WHERE packageName +
//                   INSERT (not just InsertOrReplace on packageId), so
//                   state table holds at most ONE row per packageName.
//                   Otherwise upgrades leave stale rows of old versions.
//   #3 (R2#3):      Empty examples package (0 valid jsonl rows) throws
//                   InstallFailedError → transaction rollback → state NOT
//                   written. Prevents server-side empty package bugs from
//                   silently marking client "installed".
//   #4 (R2#4):      stable_id missing/empty throws InstallFailedError.
//                   SQLite unique index does NOT constrain NULL, so
//                   manifest's "覆盖 bundle by stable_id" semantics fail
//                   silently if stable_id is null.
//   #7 (R1#4):      Double unique index `(stableId)` + `(wordId, sortOrder)`
//                   on example_sentences. InsertOrReplace triggers DELETE
//                   on either conflict. Server build_examples_package MUST
//                   guarantee `(wordId, sortOrder)` unique within a single
//                   package — otherwise client silently dedups (last row
//                   wins). PR-A README §6 design point 5 (Full snapshot)
//                   covers this; mismatch → check server build first.
//   #13 (R1#9):     catch (e, st) + Error.throwWithStackTrace preserves
//                   stack trace through the InstallFailedError wrapper.
//   #16 (R1#12):    `db` is required (no AppDatabase() default). Forces
//                   call sites to be explicit about which database
//                   instance, avoiding "two DBs in one process" bugs.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:drift/drift.dart';

import '../storage/drift/app_database.dart';
import 'manifest_client.dart' show ManifestPackage;

class UnsupportedKindError implements Exception {
  final String packageKind;
  UnsupportedKindError(this.packageKind);

  @override
  String toString() =>
      'UnsupportedKindError($packageKind): only "examples" implemented in PR-B2';
}

class InstallFailedError implements Exception {
  final String packageId;
  final String message;
  InstallFailedError(this.packageId, this.message);

  @override
  String toString() => 'InstallFailedError($packageId, $message)';
}

class PackageInstaller {
  final AppDatabase _db;

  PackageInstaller({required AppDatabase db}) : _db = db;

  /// Install a verified .gz package into drift.
  ///
  /// Atomic semantics: drift transaction wraps both the example_sentences
  /// batch insert AND the content_package_state UPSERT. If either fails,
  /// both are rolled back — no partial state.
  ///
  /// Errors:
  ///   - [UnsupportedKindError]: package_kind != "examples" (PR-B2 v1)
  ///   - [InstallFailedError]: file missing / empty package /
  ///     null-or-empty stable_id / drift errors. Stack trace preserved
  ///     via Error.throwWithStackTrace.
  Future<void> install(File gzFile, ManifestPackage pkg) async {
    if (pkg.packageKind != 'examples') {
      throw UnsupportedKindError(pkg.packageKind);
    }
    if (!await gzFile.exists()) {
      throw InstallFailedError(pkg.packageId, 'file not found: ${gzFile.path}');
    }

    await _db.transaction(() async {
      try {
        final rowsInstalled = await _installExamples(gzFile, pkg);
        if (rowsInstalled == 0) {
          // #3: empty packages must NOT mark "installed".
          throw InstallFailedError(
            pkg.packageId,
            'installed 0 rows from gz; package is empty or all rows invalid',
          );
        }
        await _upsertPackageState(pkg);
      } on InstallFailedError {
        rethrow;
      } on UnsupportedKindError {
        rethrow;
      } on Object catch (e, st) {
        // #13: preserve stack trace through wrapper.
        Error.throwWithStackTrace(
          InstallFailedError(pkg.packageId, '$e'),
          st,
        );
      }
    });
  }

  /// Decompress the .gz, parse jsonl, batch-insert into example_sentences
  /// using InsertMode.insertOrReplace (manifest is authoritative — overwrites
  /// rows previously written by bundle path or older manifest snapshots).
  ///
  /// Implementation note (Day 1 plan v0.2 R1#2 + Day 2 plan v0.2 #5):
  /// drift's batch callback is sync, so we MUST `.toList()` all jsonl lines
  /// before iterating. Per-package memory peak: ≤ 2MB compressed, ~5-10MB
  /// decompressed — acceptable on mobile (60-80MB process limit).
  /// Streaming line-by-line + single inserts is the alternative but loses
  /// batch's bulk-commit speedup.
  ///
  /// Returns: count of valid rows inserted (caller checks > 0).
  Future<int> _installExamples(File gzFile, ManifestPackage pkg) async {
    final lines = await gzFile
        .openRead()
        .transform(gzip.decoder)
        .transform(utf8.decoder)
        .transform(const LineSplitter())
        .toList();

    var inserted = 0;
    await _db.batch((batch) {
      for (final line in lines) {
        if (line.trim().isEmpty) continue;
        final j = jsonDecode(line) as Map<String, dynamic>;

        // #4: stable_id is the manifest's "covering" key. NULL/empty would
        // make InsertOrReplace fall back to (wordId, sortOrder) only, which
        // can silently drop rows that belong in the new snapshot but happen
        // to share a (wordId, sortOrder) with an outgoing row. Reject.
        final stableId = j['stable_id'] as String?;
        if (stableId == null || stableId.isEmpty) {
          throw InstallFailedError(
            pkg.packageId,
            'jsonl line missing stable_id; manifest covering semantics '
            'depend on it (SQLite unique index does not constrain NULL)',
          );
        }

        batch.insert(
          _db.exampleSentences,
          ExampleSentencesCompanion.insert(
            wordId: j['word_id'] as String,
            sense: (j['sense_label'] as String?) ?? '',
            en: j['en'] as String,
            cn: j['cn'] as String,
            sortOrder: Value((j['ordinal'] as int?) ?? 0),
            stableId: Value(stableId),
          ),
          mode: InsertMode.insertOrReplace,
        );
        inserted++;
      }
    });
    return inserted;
  }

  /// #1 review-adopted (R1#1/R2#1): DELETE WHERE packageName + INSERT.
  ///
  /// `content_package_state` PK is `packageId` ("examples-zk@v5"), but the
  /// state-diff in ContentPackageService indexes by `packageName`
  /// ("examples-zk"). A bare InsertOrReplace on packageId would leave old
  /// version rows lingering forever (each upgrade adds a row, never removes
  /// the previous). Long-term: state table grows unbounded; the
  /// localStates[packageName] index becomes a SELECT-order race (which
  /// version wins depends on drift's default ORDER BY).
  ///
  /// Solution: explicitly delete all rows with the same packageName before
  /// inserting the new packageId row. Same transaction → atomic.
  Future<void> _upsertPackageState(ManifestPackage pkg) async {
    await (_db.delete(_db.contentPackageStates)
          ..where((t) => t.packageName.equals(pkg.packageName)))
        .go();
    await _db.into(_db.contentPackageStates).insert(
          ContentPackageStatesCompanion.insert(
            packageId: pkg.packageId,
            packageName: pkg.packageName,
            packageKind: pkg.packageKind,
            contentVersion: pkg.contentVersion,
            releaseId: pkg.releaseId,
            checksumSha256: pkg.checksumSha256,
            installedAt: DateTime.now().millisecondsSinceEpoch,
            bookId: Value(pkg.bookId),
            sizeBytes: Value(pkg.sizeBytes),
            compression: Value(pkg.compression),
            minAppVersion: Value(pkg.minAppVersion),
            fileUrl: Value(pkg.fileUrl),
          ),
        );
  }
}
