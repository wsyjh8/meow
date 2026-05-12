/**
 * 需求 23 Phase D PR-D-β — backup persistence e2e.
 *
 * Verifies plan-023-D-v2 §4.2 / §6 D-T1..D-T8:
 *   D-T1  upload → server restart → fetch (server restart simulated by
 *         dropping the in-memory backup map; only PG persists)
 *   D-T3  user A upload → user B fetch → no_backup_yet
 *   D-T4  device 1 upload → device 2 (same user A) fetch → snapshot +
 *         device_id intact
 *   D-T8  client uploads polluted snapshot (user_id != token user) →
 *         400 INVALID_SNAPSHOT_USER_ID
 *   D-T2  same user multiple uploads → last-write-wins (single slot)
 *   D-T6  body limit 10MB — server accepts ≥9MB JSONB
 *   D-T10 DELETE users row → backup_snapshots cascades
 *
 * Runs under AUTH_ENFORCE=true with two real guest users so the path
 * exercises actual JWT signing / verification.
 */

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import { json, urlencoded } from 'express';
import * as request from 'supertest';
import * as fs from 'fs';
import * as path from 'path';

const envPath = path.resolve(__dirname, '..', '.env');
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, 'utf-8').split('\n')) {
    const t = line.trim();
    if (t && !t.startsWith('#')) {
      const eq = t.indexOf('=');
      if (eq > 0 && !process.env[t.substring(0, eq)]) {
        process.env[t.substring(0, eq)] = t.substring(eq + 1);
      }
    }
  }
}

process.env.PERSISTENCE_BACKEND = 'pg';
process.env.AUTH_ENFORCE = 'true';

import { AppModule } from '../src/app.module';
import { devStore } from '../src/domain';
import { getPool } from '../src/infrastructure/postgres/client';

const hasPg = !!process.env.DATABASE_URL;
const describeIfPg = hasPg ? describe : describe.skip;

describeIfPg('Backup persistence (PR-D-β / e2e)', () => {
  let app: INestApplication;
  const createdUserIds: string[] = [];

  let tokenA: string;
  let tokenB: string;
  let userAId: string;
  let userBId: string;

  beforeAll(async () => {
    await devStore.initAsync();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    // PR-D-α: production main.ts raises body limit to 10MB. Mirror it
    // here so D-T6 (large-snapshot upload) passes the same way
    // production does.
    app.use(json({ limit: '10mb' }));
    app.use(urlencoded({ extended: true, limit: '10mb' }));
    app.useGlobalPipes(new ValidationPipe());
    app.setGlobalPrefix('api/v1');
    await app.init();

    const a = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .send({ device_id: `bk-A-${Date.now()}` });
    expect(a.status).toBe(200);
    tokenA = a.body.token;
    userAId = a.body.user.id;
    createdUserIds.push(userAId);

    const b = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .send({ device_id: `bk-B-${Date.now()}-x` });
    expect(b.status).toBe(200);
    tokenB = b.body.token;
    userBId = b.body.user.id;
    createdUserIds.push(userBId);

    expect(userAId).not.toBe(userBId);
  }, 30000);

  afterAll(async () => {
    if (createdUserIds.length > 0) {
      const pool = getPool();
      // backup_snapshots cascades on DELETE users; but the
      // auth-isolation cleanup pattern lists every table explicitly,
      // which also covers fishing/equipment/etc.
      const tables = [
        'backup_snapshots',
        'review_attempts', 'review_groups', 'study_attempts',
        'settlements', 'reward_ledger', 'reward_source_events',
        'idempotency_keys', 'session_records', 'feed_events',
        'equipment_slots', 'inventory_items', 'lottery_boxes',
        'fishing_attempts', 'daily_fishing_tasks', 'check_in_records',
        'streak_records', 'learning_day_facts', 'daily_goal_progress',
        'secondary_wallets', 'pet_profiles', 'user_book_settings',
      ];
      for (const t of tables) {
        await pool.query(
          `DELETE FROM ${t} WHERE user_id = ANY($1::text[])`,
          [createdUserIds],
        ).catch(() => {});
      }
      await pool.query(
        'DELETE FROM users WHERE id = ANY($1::text[])',
        [createdUserIds],
      );
    }
    await app.close();
  });

  /// Build a minimal snapshot whose embedded user_id rows match
  /// [userId]. Mirrors the v13 mobile snapshot shape closely enough
  /// that validateSnapshotUserIds finds something to walk.
  function buildSnapshotForUser(userId: string, opts: {
    extraWordId?: string;
  } = {}): any {
    return {
      schema_version: 'p3_2_snapshot_v1',
      exported_at: new Date().toISOString(),
      export_format: 'full_snapshot_json',
      device: { device_id: 'dev-test-001', device_model: 'TestPhone' },
      settings: { daily_goal: 20, sound_enabled: true, theme: 'light' },
      progress: {
        word_records: [
          {
            user_id: userId,
            word_id: opts.extraWordId ?? 'abandon',
            book_id: 'zk',
            study_type: 'new',
            action_result: 'know',
            created_at: '2026-05-11T00:00:00Z',
            synced: 0,
          },
        ],
        card_states: [
          {
            user_id: userId,
            word_id: opts.extraWordId ?? 'abandon',
            due: 1700000000000,
            created_at: 1700000000000,
            state: 1,
            reps: 0,
            lapses: 0,
          },
        ],
        daily_checkins: [
          {
            user_id: userId,
            date: '2026-05-11',
            checked_in: 1,
            created_at: '2026-05-11T00:00:00Z',
          },
        ],
        wordbook_progress: null,
        custom_wordbooks: [],
        vocabulary_notebook: [],
      },
    };
  }

  // ── D-T1: upload → server-restart → fetch ──────────────────────────
  it('D-T1: upload persists; dev-store backup map reset still serves snapshot from PG (server restart proxy)', async () => {
    const snap = buildSnapshotForUser(userAId, { extraWordId: 'resilient' });

    const up = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: snap });
    expect(up.status).toBe(201);
    expect(up.body.status).toBe('succeeded');
    expect(up.body.backup_id).toBeTruthy();

    // Simulate server restart: blow away dev-store in-memory backup map
    // for user A. After PR-D-β, the controller reads PG directly, so
    // this must STILL serve the snapshot.
    devStore.reset();
    await new Promise(r => setTimeout(r, 200));

    const fetchMeta = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(fetchMeta.status).toBe(200);
    expect(fetchMeta.body.status).toBe('available');
    expect(fetchMeta.body.backup_id).toBe(up.body.backup_id);

    const fetchFull = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(fetchFull.status).toBe(200);
    expect(fetchFull.body.status).toBe('available');
    expect(fetchFull.body.snapshot.progress.word_records[0].word_id).toBe(
      'resilient',
    );
  });

  // ── D-T2: last-write-wins single slot ──────────────────────────────
  it('D-T2: same user, two uploads — fetch returns the latest', async () => {
    const first = buildSnapshotForUser(userAId, { extraWordId: 'first' });
    const second = buildSnapshotForUser(userAId, { extraWordId: 'second' });

    await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: first })
      .expect(201);
    const secondUp = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: second });
    expect(secondUp.status).toBe(201);

    const fetchFull = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(fetchFull.body.snapshot.progress.word_records[0].word_id).toBe(
      'second',
    );
  });

  // ── D-T3: A upload → B fetch → no_backup_yet ──────────────────────
  it('D-T3: user B fetching after only user A has uploaded sees no_backup_yet (PG row keyed by user_id)', async () => {
    // Clean B's bucket if previous test left anything.
    await getPool()
      .query('DELETE FROM backup_snapshots WHERE user_id = $1', [userBId])
      .catch(() => {});

    const snap = buildSnapshotForUser(userAId);
    await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: snap })
      .expect(201);

    const bMeta = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest')
      .set('Authorization', `Bearer ${tokenB}`);
    expect(bMeta.status).toBe(200);
    expect(bMeta.body.status).toBe('no_backup_yet');

    const bFull = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenB}`);
    expect(bFull.status).toBe(200);
    expect(bFull.body.status).toBe('no_backup_found');
    expect(bFull.body.snapshot).toBeNull();
  });

  // ── D-T4: device 1 upload → device 2 (same user) fetch ────────────
  it('D-T4: device 1 upload preserves device_id/device_model through device 2 fetch', async () => {
    const snap = {
      ...buildSnapshotForUser(userAId),
      device: { device_id: 'dev-original-123', device_model: 'PixelPhone' },
    };
    const up = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: snap })
      .expect(201);
    expect(up.body.device_id).toBe('dev-original-123');
    expect(up.body.device_model).toBe('PixelPhone');

    // Reset dev-store map → simulates a different device session
    // for the same user (the new device has empty in-memory).
    devStore.reset();
    await new Promise(r => setTimeout(r, 200));

    const fetchFull = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(fetchFull.body.device_id).toBe('dev-original-123');
    expect(fetchFull.body.device_model).toBe('PixelPhone');
  });

  // ── D-T8: server rejects snapshot with foreign user_id rows ───────
  it('D-T8: snapshot with progress.word_records[*].user_id != token user → 400 INVALID_SNAPSHOT_USER_ID', async () => {
    const poisoned = buildSnapshotForUser(userAId);
    // Inject a foreign user_id into one of the rows.
    poisoned.progress.word_records[0].user_id = userBId;

    const up = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: poisoned });

    expect(up.status).toBe(400);
    // NestJS error envelope path depends on filter; the inner
    // payload's error_code is what we set in HttpException.
    const code =
      up.body?.error_code ??
      up.body?.message?.error_code ??
      up.body?.message;
    expect(JSON.stringify(up.body)).toContain('INVALID_SNAPSHOT_USER_ID');
    void code; // silence lint about the unused destructured fallback
  });

  // ── D-T6: 10MB body limit ─────────────────────────────────────────
  it('D-T6: ~9MB snapshot upload succeeds (body limit raised to 10MB)', async () => {
    const snap = buildSnapshotForUser(userAId);
    // Pad an inert field so the JSON encodes to ~9MB. A single big
    // string field is cheaper to build than thousands of rows and
    // exercises the same body-parser limit.
    snap.padding = 'x'.repeat(9 * 1024 * 1024);

    const up = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: snap });
    expect(up.status).toBe(201);
    expect(up.body.status).toBe('succeeded');
    // snapshot_size is in bytes; assert it's plausible.
    const fetchMeta = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(fetchMeta.body.snapshot_size).toBeGreaterThan(8 * 1024 * 1024);
  }, 60000);

  // ── D-T10: DELETE users → backup_snapshots cascades ───────────────
  it('D-T10: DELETE users row cascades to backup_snapshots', async () => {
    // Create a throwaway user, upload a backup, then delete from users.
    const c = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .send({ device_id: `bk-cascade-${Date.now()}` });
    expect(c.status).toBe(200);
    const tokenC = c.body.token;
    const userCId = c.body.user.id;
    createdUserIds.push(userCId);

    await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenC}`)
      .send({ snapshot: buildSnapshotForUser(userCId) })
      .expect(201);

    const pool = getPool();
    const before = await pool.query(
      'SELECT count(*)::int AS n FROM backup_snapshots WHERE user_id = $1',
      [userCId],
    );
    expect(before.rows[0].n).toBe(1);

    // Drop the user row — backup_snapshots.user_id is ON DELETE CASCADE.
    await pool.query('DELETE FROM users WHERE id = $1', [userCId]);

    const after = await pool.query(
      'SELECT count(*)::int AS n FROM backup_snapshots WHERE user_id = $1',
      [userCId],
    );
    expect(after.rows[0].n).toBe(0);

    // Remove from cleanup list since we already deleted it.
    const idx = createdUserIds.indexOf(userCId);
    if (idx >= 0) createdUserIds.splice(idx, 1);
  });

  // ── D-T13: PRD §9.5 — bind keeps backup ───────────────────────────
  it('D-T13: guest uploads backup → bind to registered → backup still '
      + 'visible (same-row bind preserves users.id and backup row)',
      async () => {
    // Create a fresh guest (we want bind to upgrade, not collide).
    const guest = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .send({ device_id: `bk-bind-${Date.now()}` });
    expect(guest.status).toBe(200);
    const guestToken = guest.body.token;
    const guestUserId = guest.body.user.id;
    createdUserIds.push(guestUserId);

    // Upload a backup as the guest.
    const guestSnap = buildSnapshotForUser(guestUserId, {
      extraWordId: 'pre-bind',
    });
    const up = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${guestToken}`)
      .send({ snapshot: guestSnap })
      .expect(201);
    const backupIdBeforeBind = up.body.backup_id;
    expect(backupIdBeforeBind).toBeTruthy();

    // Bind the guest to email/password. A4-α §6.2 same-row upgrade:
    // users.id stays the same; only account_type + email + password
    // change.
    const email = `bk-bind-${Date.now()}@test.local`;
    const bound = await request(app.getHttpServer())
      .post('/api/v1/auth/bind')
      .set('Authorization', `Bearer ${guestToken}`)
      .send({ email, password: 'pa55w0rd!' });
    expect(bound.status).toBe(200);
    const boundToken = bound.body.token;
    const boundUserId = bound.body.user.id;

    // Critical assertion: users.id is stable through bind.
    expect(boundUserId).toBe(guestUserId);

    // GET /me/backup/latest with the post-bind token still returns
    // the SAME backup row (PRIMARY KEY is user_id, which didn't
    // move).
    const metaAfterBind = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest')
      .set('Authorization', `Bearer ${boundToken}`);
    expect(metaAfterBind.status).toBe(200);
    expect(metaAfterBind.body.status).toBe('available');
    expect(metaAfterBind.body.backup_id).toBe(backupIdBeforeBind);

    // Full snapshot fetch also works.
    const fullAfterBind = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${boundToken}`);
    expect(fullAfterBind.status).toBe(200);
    expect(fullAfterBind.body.status).toBe('available');
    expect(
      fullAfterBind.body.snapshot.progress.word_records[0].word_id,
    ).toBe('pre-bind');
  });

  // ── D-T14: PRD §9.7 — token guard on backup endpoints ─────────────
  describe('D-T14: AUTH_ENFORCE=true → /me/backup/* rejects missing / invalid token', () => {
    it('POST /me/backup with no Authorization → 401', async () => {
      const r = await request(app.getHttpServer())
        .post('/api/v1/me/backup')
        .send({ snapshot: buildSnapshotForUser(userAId) });
      expect(r.status).toBe(401);
    });

    it('GET /me/backup/latest with no Authorization → 401', async () => {
      const r = await request(app.getHttpServer())
        .get('/api/v1/me/backup/latest');
      expect(r.status).toBe(401);
    });

    it('GET /me/backup/latest/snapshot with no Authorization → 401',
        async () => {
      const r = await request(app.getHttpServer())
        .get('/api/v1/me/backup/latest/snapshot');
      expect(r.status).toBe(401);
    });

    it('GET /me/backup/latest with invalid Bearer → 401', async () => {
      const r = await request(app.getHttpServer())
        .get('/api/v1/me/backup/latest')
        .set('Authorization', 'Bearer not-a-real-jwt');
      expect(r.status).toBe(401);
    });
  });
});
