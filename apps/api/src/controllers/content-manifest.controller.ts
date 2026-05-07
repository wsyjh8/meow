/**
 * GET /api/v1/content/manifest — v0.3 PR-A Day 4
 *
 * 客户端发现入口：返回当前 active release 的 active manifest packages。
 *
 * Query params (all optional):
 *   since_release  仅返回比该 release.activated_at 更晚激活的包
 *   app_version    semver string (X.Y.Z 严格三段)；过滤 min_app_version > app_version
 *
 * Dual-condition filter (v0.2 评审采纳 #11):
 *   release.status='active' AND manifest.is_active=true
 *
 * Errors:
 *   400 — unknown since_release / invalid app_version format
 *
 * Production safety (Day 4 review采纳):
 *   - When NODE_ENV='production', file:// URLs are skipped + logged
 *   - size_bytes returned as JS number (BIGINT → string conversion handled)
 *   - Manifests with invalid min_app_version are skipped with warn
 */
import {
  BadRequestException,
  Controller,
  Get,
  Query,
} from '@nestjs/common';
import { getPool } from '../infrastructure/postgres/client';

interface ManifestPackage {
  package_id: string;
  package_kind: string;
  package_name: string;
  book_id: string | null;
  content_version: string;
  file_url: string;
  checksum_sha256: string;
  size_bytes: number;
  compression: string | null;
  min_app_version: string;
  release_id: string;
}

interface ManifestResponse {
  release_ids: string[];
  packages: ManifestPackage[];
}

/**
 * Strict X.Y.Z semver — three non-negative integers, no pre-release / build / leading zeros.
 * NOTE: leading zero check via regex prevents '01.02.03' style which can be ambiguous.
 */
const SEMVER_RE = /^(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$/;

function parseStrictSemver(v: string): [number, number, number] | null {
  const m = SEMVER_RE.exec(v);
  if (!m) return null;
  return [Number(m[1]), Number(m[2]), Number(m[3])];
}

/** Returns true iff a >= b. */
function semverGte(
  a: [number, number, number],
  b: [number, number, number],
): boolean {
  for (let i = 0; i < 3; i++) {
    if (a[i] > b[i]) return true;
    if (a[i] < b[i]) return false;
  }
  return true;
}

/**
 * Derive book_id from package_name based on naming convention.
 * Returns null for kinds that aren't book-scoped (dictionary).
 */
function deriveBookId(
  packageName: string,
  packageKind: string,
): string | null {
  if (packageKind === 'dictionary') return null;
  const prefixes: Record<string, string> = {
    examples: 'examples-',
    audio_meta: 'audio-meta-',
    wordbook: 'wordbook-',
  };
  const prefix = prefixes[packageKind];
  if (!prefix || !packageName.startsWith(prefix)) return null;
  return packageName.slice(prefix.length);
}

/** Derive compression from file_url suffix. Returns null if unknown. */
function deriveCompression(fileUrl: string): string | null {
  if (fileUrl.endsWith('.gz')) return 'gzip';
  if (fileUrl.endsWith('.br')) return 'brotli';
  return null;
}

// PR-B3 Day 1 transformFileUrlForDev helper removed in PR-C. With pipeline.py
// uploading manifest packages to Tencent COS and writing https URLs directly
// to content_manifest.file_url, the manifest API can pass URLs through
// unchanged. dev/local fallback for file:// → http://host/cdn/staging is no
// longer needed.

@Controller('content')
export class ContentManifestController {
  @Get('manifest')
  async getManifest(
    @Query('since_release') sinceRelease?: string,
    @Query('app_version') appVersion?: string,
  ): Promise<ManifestResponse> {
    const pool = getPool();

    // Strict app_version validation (review-driven)
    let parsedAppVersion: [number, number, number] | null = null;
    if (appVersion !== undefined && appVersion !== '') {
      parsedAppVersion = parseStrictSemver(appVersion);
      if (parsedAppVersion === null) {
        throw new BadRequestException({
          error: 'invalid app_version',
          expected: 'X.Y.Z (three non-negative integers, no leading zeros)',
          got: appVersion,
        });
      }
    }

    // since_release validation
    let sinceActivatedAt: Date | null = null;
    if (sinceRelease) {
      const releaseRows = await pool.query<{ activated_at: Date | null }>(
        'SELECT activated_at FROM content_release WHERE release_id = $1',
        [sinceRelease],
      );
      if (releaseRows.rows.length === 0) {
        throw new BadRequestException({
          error: 'unknown release_id',
          release_id: sinceRelease,
        });
      }
      sinceActivatedAt = releaseRows.rows[0].activated_at;
      // If activated_at IS NULL (release never activated), treat as
      // "no since filter" — same as not passing the param.
    }

    // Main query — dual-condition filter; COALESCE min_app_version against
    // pre-NOT-NULL legacy rows (defensive even though schema enforces NOT NULL).
    const sinceClause = sinceActivatedAt ? 'AND r.activated_at > $1' : '';
    const params: unknown[] = sinceActivatedAt ? [sinceActivatedAt] : [];
    const result = await pool.query(
      `SELECT m.id AS package_id, m.package_kind, m.package_name,
              m.content_version, m.file_url, m.checksum_sha256,
              m.size_bytes,
              COALESCE(m.min_app_version, '0.0.0') AS min_app_version,
              m.release_id
         FROM content_manifest m
         JOIN content_release r ON m.release_id = r.release_id
        WHERE r.status = 'active'
          AND m.is_active = true
          ${sinceClause}
        ORDER BY r.activated_at, m.package_name, m.content_version`,
      params,
    );

    const packages: ManifestPackage[] = [];
    for (const row of result.rows) {
      // Skip rows with NULL file_url (e.g., legacy audio-meta packages
      // pre-Day-4) — not downloadable, would crash deriveCompression too
      if (typeof row.file_url !== 'string' || row.file_url.length === 0) {
        // eslint-disable-next-line no-console
        console.warn(
          `[content/manifest] skipping ${row.package_id}: file_url is null/empty`,
        );
        continue;
      }

      // PR-C: defensive — pipeline.py always writes https COS URLs now, so
      // file:// rows in PG are pre-PR-C legacy data or a bug. Skip them in
      // every environment (was production-only in PR-A/PR-B3).
      if (row.file_url.startsWith('file://')) {
        // eslint-disable-next-line no-console
        console.error(
          `[content/manifest] file:// URL in DB after PR-C — skipping: ${row.package_id}`,
        );
        continue;
      }

      // app_version filter (if requested)
      if (parsedAppVersion !== null) {
        const minParsed = parseStrictSemver(row.min_app_version);
        if (minParsed === null) {
          // Server-side data is invalid; conservatively skip rather than include
          // eslint-disable-next-line no-console
          console.warn(
            `[content/manifest] manifest ${row.package_id} has invalid min_app_version: ${row.min_app_version}; skipping`,
          );
          continue;
        }
        if (!semverGte(parsedAppVersion, minParsed)) {
          continue; // app too old for this package
        }
      }

      // PR-C: pipeline.py writes real https COS URLs straight to file_url,
      // so the manifest API just passes them through unchanged. The PR-B3
      // Day 1 dev-mode transform helper has been removed.
      packages.push({
        package_id: row.package_id,
        package_kind: row.package_kind,
        package_name: row.package_name,
        book_id: deriveBookId(row.package_name, row.package_kind),
        content_version: row.content_version,
        file_url: row.file_url,
        checksum_sha256: row.checksum_sha256,
        // BIGINT in PG → string in node-pg by default; explicit Number()
        // is safe for our range (manifest sizes well under 2^53).
        size_bytes: Number(row.size_bytes),
        compression: deriveCompression(row.file_url),
        min_app_version: row.min_app_version,
        release_id: row.release_id,
      });
    }

    const release_ids = [...new Set(packages.map((p) => p.release_id))];
    return { release_ids, packages };
  }
}
