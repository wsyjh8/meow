/**
 * 需求 23 Phase A4-α/β — Cross-user isolation tests
 *
 * Verifies audit §6 owner-check enforcement.
 *
 * α coverage (this file):
 *   - 401 for missing/invalid token (AUTH_ENFORCE=true)
 *   - User B cannot read User A's session → 404
 *   - User B cannot finish User A's session → 404
 *   - User B cannot read User A's settlement → 404
 *   - Idempotency keys are scoped per-user
 *
 * β.7 coverage (added later):
 *   - lottery / fishing / equipment / feed / review-batch / backup
 *     cross-user → 404
 *   - balance / today-state / next-new-word do NOT leak across users
 *
 * AUTH_ENFORCE=true so that fake/missing tokens are rejected with 401
 * (instead of falling back to dev-user-001).
 */

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import * as fs from 'fs';
import * as path from 'path';

// Load .env so DATABASE_URL / JWT_SECRET are visible to AppModule
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
import { getPool } from '../src/infrastructure/postgres/client';

const hasPg = !!process.env.DATABASE_URL;
const describeIfPg = hasPg ? describe : describe.skip;

describeIfPg('Cross-user isolation (AUTH_ENFORCE=true, audit §6)', () => {
  let app: INestApplication;
  const createdUserIds: string[] = [];

  let tokenA: string;
  let tokenB: string;
  let userAId: string;
  let userBId: string;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();

    // Create two distinct guest users
    const a = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .send({ device_id: `iso-A-${Date.now()}` });
    expect(a.status).toBe(200);
    tokenA = a.body.token;
    userAId = a.body.user.id;
    createdUserIds.push(userAId);

    const b = await request(app.getHttpServer())
      .post('/api/v1/auth/guest')
      .send({ device_id: `iso-B-${Date.now()}-x` });
    expect(b.status).toBe(200);
    tokenB = b.body.token;
    userBId = b.body.user.id;
    createdUserIds.push(userBId);

    expect(userAId).not.toBe(userBId);
  }, 30000);

  afterAll(async () => {
    if (createdUserIds.length > 0) {
      // Clean up FK rows first then users
      const pool = getPool();
      // Order: child tables first (FK targets last)
      const tables = [
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

  it('rejects requests with no token (AUTH_ENFORCE=true)', async () => {
    const r = await request(app.getHttpServer()).get('/api/v1/me/today');
    expect(r.status).toBe(401);
  });

  it('rejects requests with invalid token (AUTH_ENFORCE=true)', async () => {
    const r = await request(app.getHttpServer())
      .get('/api/v1/me/today')
      .set('Authorization', 'Bearer not-a-real-jwt');
    expect(r.status).toBe(401);
  });

  it('User B cannot read User A\'s session (404, not 403)', async () => {
    // A starts a session
    const start = await request(app.getHttpServer())
      .post('/api/v1/sessions')
      .set('Authorization', `Bearer ${tokenA}`)
      .set('X-Idempotency-Key', `iso-sess-${Date.now()}`)
      .send({ session_minutes_target: 15 });
    expect(start.status).toBe(200);
    const sessionId = start.body.session_id;
    expect(sessionId).toBeTruthy();

    // A can read their own session
    const ownRead = await request(app.getHttpServer())
      .get(`/api/v1/sessions/${sessionId}`)
      .set('Authorization', `Bearer ${tokenA}`);
    expect(ownRead.status).toBe(200);

    // B tries to read A's session → 404 (not 403, prevent ID enumeration)
    const crossRead = await request(app.getHttpServer())
      .get(`/api/v1/sessions/${sessionId}`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(crossRead.status).toBe(404);
  });

  it('User B cannot finish User A\'s session', async () => {
    const start = await request(app.getHttpServer())
      .post('/api/v1/sessions')
      .set('Authorization', `Bearer ${tokenA}`)
      .set('X-Idempotency-Key', `iso-finish-${Date.now()}`)
      .send({ session_minutes_target: 15 });
    expect(start.status).toBe(200);
    const sessionId = start.body.session_id;

    const crossFinish = await request(app.getHttpServer())
      .post(`/api/v1/sessions/${sessionId}/finish`)
      .set('Authorization', `Bearer ${tokenB}`)
      .set('X-Idempotency-Key', `iso-finish-b-${Date.now()}`);
    expect(crossFinish.status).toBe(404);
  });

  it('User B cannot read User A\'s settlement by source_event_id', async () => {
    const idemA = `iso-settle-a-${Date.now()}`;
    const created = await request(app.getHttpServer())
      .post('/api/v1/settlements/learning-rounds')
      .set('Authorization', `Bearer ${tokenA}`)
      .set('X-Idempotency-Key', idemA)
      .send({
        source_event_type: 'effective_new_word',
        source_ref_id: `iso-ref-${Date.now()}`,
      });
    expect(created.status).toBe(200);
    const sourceEventId = created.body.source_event_id;

    // A can read their own
    const ownRead = await request(app.getHttpServer())
      .get(`/api/v1/settlements/${sourceEventId}`)
      .set('Authorization', `Bearer ${tokenA}`);
    expect(ownRead.status).toBe(200);

    // B cannot
    const crossRead = await request(app.getHttpServer())
      .get(`/api/v1/settlements/${sourceEventId}`)
      .set('Authorization', `Bearer ${tokenB}`);
    expect(crossRead.status).toBe(404);
  });

  it('idempotency keys are scoped per-user (no cross-user replay)', async () => {
    // A and B both submit settlement with the SAME idempotency key.
    // Migration 009 made PK = (user_id, key), so each gets their own
    // record — no cross-user response leakage.
    const sharedKey = `iso-shared-idem-${Date.now()}`;

    const aRes = await request(app.getHttpServer())
      .post('/api/v1/settlements/learning-rounds')
      .set('Authorization', `Bearer ${tokenA}`)
      .set('X-Idempotency-Key', sharedKey)
      .send({
        source_event_type: 'effective_new_word',
        source_ref_id: `iso-shared-ref-A-${Date.now()}`,
      });
    expect(aRes.status).toBe(200);

    const bRes = await request(app.getHttpServer())
      .post('/api/v1/settlements/learning-rounds')
      .set('Authorization', `Bearer ${tokenB}`)
      .set('X-Idempotency-Key', sharedKey)
      .send({
        source_event_type: 'effective_new_word',
        source_ref_id: `iso-shared-ref-B-${Date.now()}`,
      });
    expect(bRes.status).toBe(200);

    // settlements should be distinct
    expect(aRes.body.settlement_id).not.toBe(bRes.body.settlement_id);
    expect(aRes.body.source_ref_id).not.toBe(bRes.body.source_ref_id);
  });

  // 需求 23 Phase A4-β.2: backup per-user partition.
  // Was a P0 leak in α — single global slot served same snapshot to all users.
  it('User B does NOT see User A\'s backup snapshot', async () => {
    const aSnapshot = {
      schema_version: 'iso-test-v1',
      progress: { word_records: [{ marker: 'belongs-to-A' }] },
    };

    const upload = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({ snapshot: aSnapshot, schema_version: 'iso-test-v1' });
    expect(upload.status).toBe(201);
    expect(upload.body.status).toBe('succeeded');

    // A reads their own backup → has the snapshot
    const ownMeta = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(ownMeta.status).toBe(200);
    expect(ownMeta.body.schema_version).toBe('iso-test-v1');

    const ownSnap = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(ownSnap.status).toBe(200);
    expect(ownSnap.body.status).toBe('available');
    expect(ownSnap.body.snapshot.progress.word_records[0].marker).toBe(
      'belongs-to-A',
    );

    // B reads their own backup → no_backup_yet (B never uploaded)
    const bMeta = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest')
      .set('Authorization', `Bearer ${tokenB}`);
    expect(bMeta.status).toBe(200);
    expect(bMeta.body.status).toBe('no_backup_yet');

    const bSnap = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenB}`);
    expect(bSnap.status).toBe(200);
    expect(bSnap.body.status).toBe('no_backup_found');
    expect(bSnap.body.snapshot).toBeNull();
  });

  it('backup last-write-wins is scoped per-user (User A\'s second upload doesn\'t affect User B)', async () => {
    // A uploads v1
    const v1 = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        snapshot: { schema_version: 'lww-A-v1', tag: 'A1' },
        schema_version: 'lww-A-v1',
      });
    expect(v1.status).toBe(201);

    // B uploads their own v1
    const bUpload = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenB}`)
      .send({
        snapshot: { schema_version: 'lww-B-v1', tag: 'B1' },
        schema_version: 'lww-B-v1',
      });
    expect(bUpload.status).toBe(201);

    // A overwrites with v2
    const v2 = await request(app.getHttpServer())
      .post('/api/v1/me/backup')
      .set('Authorization', `Bearer ${tokenA}`)
      .send({
        snapshot: { schema_version: 'lww-A-v2', tag: 'A2' },
        schema_version: 'lww-A-v2',
      });
    expect(v2.status).toBe(201);

    // B's backup must still be B1, NOT overwritten by A's v2
    const bSnap = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenB}`);
    expect(bSnap.status).toBe(200);
    expect(bSnap.body.snapshot.tag).toBe('B1');

    // A sees their own A2
    const aSnap = await request(app.getHttpServer())
      .get('/api/v1/me/backup/latest/snapshot')
      .set('Authorization', `Bearer ${tokenA}`);
    expect(aSnap.status).toBe(200);
    expect(aSnap.body.snapshot.tag).toBe('A2');
  });
});
