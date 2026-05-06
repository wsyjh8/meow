import 'package:drift/drift.dart';

/// PR-B2 Day 1: 追踪 mobile 端已 imported 的 content package 状态。
///
/// Each row mirrors a `content_manifest` row on the server (1:1 by
/// `packageId == manifest.id == "{packageName}@{contentVersion}"`).
/// PR-B3+ WordbookLoader will query this table to decide whether to skip
/// bundle clear-on-version-change (avoiding the "manifest data wiped on
/// app upgrade" failure mode).
///
/// 12 columns per master plan v0.4 §3.3 (review-adopted from v0.3):
///   - 8 core (packageId / packageName / packageKind / contentVersion /
///     releaseId / checksumSha256 / installedAt / fileUrl)
///   - 4 added in v0.4: bookId / sizeBytes / compression / minAppVersion
class ContentPackageStates extends Table {
  /// Composite manifest id, e.g. "examples-zk@v5".
  /// Matches server `content_manifest.id` exactly.
  TextColumn get packageId => text().named('package_id')();

  /// Logical package name without version, e.g. "examples-zk".
  TextColumn get packageName => text().named('package_name')();

  /// One of: "examples" / "audio_meta" / "wordbook" / "dictionary".
  /// PR-B2 only fully implements `examples`; others rejected upstream
  /// in ContentPackageService kind filter (R1#5 review-adopted).
  TextColumn get packageKind => text().named('package_kind')();

  /// e.g. "v5". Used by ContentPackageService to decide upgrade vs skip.
  TextColumn get contentVersion => text().named('content_version')();

  /// release_id of the manifest response that brought this package most
  /// recently. Audit / debug aid only — rollback decisions live server-side.
  TextColumn get releaseId => text().named('release_id')();

  /// "zk" / "cet4" / "gk" / null when kind=dictionary. UI can group progress
  /// by book; debug-friendly. nullable per server contract (controller.ts:33).
  TextColumn get bookId => text().named('book_id').nullable()();

  /// SHA-256 of the .gz package binary at install time. Detects server-side
  /// replacements; never recomputed at runtime (DB v0.3.0 §7.4.1 rule).
  TextColumn get checksumSha256 => text().named('checksum_sha256')();

  /// Compressed package size in bytes. Optional; used for download progress
  /// bars and future cache budget calculations.
  IntColumn get sizeBytes => integer().named('size_bytes').nullable()();

  /// "gzip" / "brotli" / null. PR-B2 v1 only supports gzip; brotli rejected
  /// at DownloadManager level. Stored for future PR-B3+ multi-codec support.
  TextColumn get compression => text().named('compression').nullable()();

  /// Minimum app version required to use this package. Nullable; client-side
  /// guard only (server already filters min_app_version vs request app_version).
  TextColumn get minAppVersion => text().named('min_app_version').nullable()();

  /// UTC epoch ms when this row was last written.
  IntColumn get installedAt => integer().named('installed_at')();

  /// Source URL (file:// dev / http:// prod). Debug + manual re-download.
  TextColumn get fileUrl => text().named('file_url').nullable()();

  @override
  Set<Column> get primaryKey => {packageId};
}
