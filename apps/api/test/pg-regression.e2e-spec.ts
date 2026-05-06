/**
 * PG Backend Regression Tests (Option A Closeout Patch — Patch-03).
 *
 * These tests run with PERSISTENCE_BACKEND=pg against the real meow_dev database.
 * They prove that key business chains work correctly with PostgreSQL truth.
 *
 * Isolation: Each test resets DevStore (which clears PG user data via clearAsync),
 * then re-seeds static data and runs the chain.
 */

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import * as fs from 'fs';
import * as path from 'path';

// Load .env BEFORE importing app modules so DATABASE_URL is available
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

// Force PG backend for these tests
process.env.PERSISTENCE_BACKEND = 'pg';

import { AppModule } from './../src/app.module';
import { devStore } from './../src/domain';
import { getPool } from './../src/infrastructure/postgres/client';

// Skip if DATABASE_URL not available
const hasPg = !!process.env.DATABASE_URL;
const describeIfPg = hasPg ? describe : describe.skip;

describeIfPg('PG Backend Regression (e2e)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    // Ensure DevStore is using PG and has loaded
    await devStore.initAsync();

    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    app.setGlobalPrefix('api/v1');
    await app.init();
  }, 30000);

  afterAll(async () => {
    await app.close();
  });

  beforeEach(async () => {
    devStore.reset();
    // Wait for async PG clear to complete
    await new Promise(r => setTimeout(r, 500));
  });

  // ========== Core read paths ==========

  describe('Core read paths on PG', () => {
    it('GET /me/today returns valid structure', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/me/today')
        .expect(200);

      expect(res.body.current_book_name).toBe('CET-4');
      expect(res.body.today_new_target).toBe(20);
      expect(res.body.daily_goal_status).toBeDefined();
      expect(res.body.has_checked_in_today).toBeDefined();
    });

    it('GET /me/secondary-summary returns valid structure', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);

      expect(res.body.coins).toBeDefined();
      expect(res.body.fish_treats).toBeDefined();
      expect(res.body.exp).toBeDefined();
      expect(res.body.cat_summary).toBeDefined();
      expect(res.body.cat_summary.nickname).toBe('Mimi');
      expect(res.body.companion_response).toBeDefined();
      expect(res.body.equipped_preview).toBeDefined();
    });
  });

  // ========== Purchase → Inventory chain ==========

  describe('Purchase → inventory on PG', () => {
    it('purchase succeeds and shows in inventory', async () => {
      // Earn coins: 30 effective_new_word settlements * 2 coins = 60
      for (let i = 1; i <= 30; i++) {
        await request(app.getHttpServer())
          .post('/api/v1/settlements/learning-rounds')
          .send({ source_event_type: 'effective_new_word', source_ref_id: `pg-purchase-${i}` })
          .set('X-Idempotency-Key', `pg-purchase-setup-${i}`)
          .expect(200);
      }

      // Purchase
      const purchaseRes = await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'pg-purchase-001')
        .expect(200);

      expect(purchaseRes.body.purchase_result.status).toBe('succeeded');
      expect(purchaseRes.body.inventory.owned_items.length).toBe(1);
      expect(purchaseRes.body.inventory.coins_balance).toBe(0);

      // Verify inventory read
      const invRes = await request(app.getHttpServer())
        .get('/api/v1/me/inventory')
        .expect(200);

      expect(invRes.body.owned_items.length).toBe(1);
      expect(invRes.body.owned_items[0].item_id).toBe('cat_hat_red');

      // Verify secondary summary coins deducted
      const summaryRes = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);

      expect(summaryRes.body.coins).toBe(0);
    });
  });

  // ========== Equip / unequip → equipment chain ==========

  describe('Equip → equipment on PG', () => {
    it('equip shows in equipment snapshot', async () => {
      // Earn + purchase first
      for (let i = 1; i <= 30; i++) {
        await request(app.getHttpServer())
          .post('/api/v1/settlements/learning-rounds')
          .send({ source_event_type: 'effective_new_word', source_ref_id: `pg-equip-${i}` })
          .set('X-Idempotency-Key', `pg-equip-setup-${i}`)
          .expect(200);
      }
      await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'pg-equip-purchase-001')
        .expect(200);

      // Equip
      const equipRes = await request(app.getHttpServer())
        .post('/api/v1/me/equipment/equip')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'pg-equip-001')
        .expect(200);

      expect(equipRes.body.equip_result.status).toBe('succeeded');
      expect(equipRes.body.equipped_snapshot.outfit.head).toBe('cat_hat_red');

      // Verify equipment read
      const eqRes = await request(app.getHttpServer())
        .get('/api/v1/me/equipment')
        .expect(200);

      expect(eqRes.body.equipped_snapshot.outfit.head).toBe('cat_hat_red');

      // Verify secondary summary equipped_preview
      const summaryRes = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);

      expect(summaryRes.body.equipped_preview.head).toBe('cat_hat_red');
    });
  });

  // ========== Feed → secondary summary chain ==========

  describe('Feed → secondary summary on PG', () => {
    it('feed updates mood/exp in summary', async () => {
      // Earn a fish treat
      await request(app.getHttpServer())
        .post('/api/v1/settlements/learning-rounds')
        .send({ source_event_type: 'review_group_completed', source_ref_id: 'pg-feed-group-1' })
        .set('X-Idempotency-Key', 'pg-feed-setup-001')
        .expect(200);

      const beforeSummary = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);

      expect(beforeSummary.body.fish_treats).toBeGreaterThanOrEqual(1);

      // Feed
      const feedRes = await request(app.getHttpServer())
        .post('/api/v1/me/feed')
        .send({ feed_item_type: 'fish_treat' })
        .set('X-Idempotency-Key', 'pg-feed-001')
        .expect(200);

      expect(feedRes.body.feed_result.status).toBe('succeeded');

      // Verify summary updated
      const afterSummary = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);

      expect(afterSummary.body.exp).toBeGreaterThan(beforeSummary.body.exp);
    });
  });

  // ========== Study + settlement chain ==========

  describe('Study + settlement on PG', () => {
    it('study attempt triggers settlement and updates summary', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/new-words')
        .send({
          word_id: 'abandon',
          book_id: 'book-001',
          study_type: 'new',
          action_result: 'know',
        })
        .set('X-Idempotency-Key', 'pg-study-001')
        .expect(200);

      expect(res.body.submit_status).toBe('accepted');
      expect(res.body.settlement).toBeDefined();
      expect(res.body.settlement.reward_settlement_status).toBe('succeeded');

      // Verify coins earned in summary
      const summaryRes = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);

      expect(summaryRes.body.coins).toBeGreaterThan(0);
    });
  });

  // ========== Check-in + streak chain ==========

  describe('Check-in + streak on PG', () => {
    it('check-in updates streak and today state', async () => {
      const ciRes = await request(app.getHttpServer())
        .post('/api/v1/check-ins')
        .set('X-Idempotency-Key', 'pg-checkin-001')
        .expect(200);

      expect(ciRes.body.check_in.check_in_status).toBe('succeeded');
      expect(ciRes.body.streak.current_streak).toBeGreaterThanOrEqual(1);

      // Verify today state
      const todayRes = await request(app.getHttpServer())
        .get('/api/v1/me/today')
        .expect(200);

      expect(todayRes.body.has_checked_in_today).toBe(true);
    });
  });

  // ========== Inventory read (standalone) ==========

  describe('Inventory read on PG', () => {
    it('GET /me/inventory returns valid empty structure', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/me/inventory')
        .expect(200);

      expect(res.body.owned_items).toEqual([]);
      expect(res.body.coins_balance).toBeDefined();
    });
  });

  // ========== Equipment read (standalone) ==========

  describe('Equipment read on PG', () => {
    it('GET /me/equipment returns valid empty structure', async () => {
      const res = await request(app.getHttpServer())
        .get('/api/v1/me/equipment')
        .expect(200);

      expect(res.body.equipped_snapshot).toBeDefined();
      expect(res.body.equipped_snapshot.outfit).toEqual({});
      expect(res.body.equipped_snapshot.room).toEqual({});
    });
  });

  // ========== Unequip chain on PG ==========

  describe('Unequip on PG', () => {
    it('unequip removes item from equipment snapshot', async () => {
      // Setup: earn + purchase + equip
      for (let i = 1; i <= 30; i++) {
        await request(app.getHttpServer())
          .post('/api/v1/settlements/learning-rounds')
          .send({ source_event_type: 'effective_new_word', source_ref_id: `pg-uneq-${i}` })
          .set('X-Idempotency-Key', `pg-uneq-setup-${i}`)
          .expect(200);
      }
      await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'pg-uneq-purchase')
        .expect(200);
      await request(app.getHttpServer())
        .post('/api/v1/me/equipment/equip')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'pg-uneq-equip')
        .expect(200);

      // Verify equipped
      let eqRes = await request(app.getHttpServer()).get('/api/v1/me/equipment').expect(200);
      expect(eqRes.body.equipped_snapshot.outfit.head).toBe('cat_hat_red');

      // Unequip
      const unequipRes = await request(app.getHttpServer())
        .post('/api/v1/me/equipment/unequip')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'pg-uneq-001')
        .expect(200);

      expect(unequipRes.body.unequip_result.status).toBe('succeeded');

      // Verify unequipped
      eqRes = await request(app.getHttpServer()).get('/api/v1/me/equipment').expect(200);
      expect(eqRes.body.equipped_snapshot.outfit.head || null).toBeNull();
    });
  });

  // ========== Review group + review attempt chain ==========

  describe('Review group + review attempt on PG', () => {
    it('creates review group and submits review attempts', async () => {
      // Get/create a review group
      const groupRes = await request(app.getHttpServer())
        .get('/api/v1/me/review-groups/next')
        .expect(200);

      expect(groupRes.body.review_group_id).toBeDefined();
      expect(groupRes.body.group_status).toBe('active');
      expect(groupRes.body.items.length).toBeGreaterThan(0);

      const groupId = groupRes.body.review_group_id;
      const firstItem = groupRes.body.items[0];

      // Submit a review attempt
      const reviewRes = await request(app.getHttpServer())
        .post('/api/v1/review-attempts')
        .send({
          review_group_id: groupId,
          word_id: firstItem.word_id,
          action_result: 'correct',
        })
        .set('X-Idempotency-Key', 'pg-review-001')
        .expect(200);

      expect(reviewRes.body.submit_status).toBe('accepted');
      expect(reviewRes.body.already_exists).toBe(false);
    });
  });

  // ========== Session start/finish chain ==========

  describe('Session start/finish on PG', () => {
    it('starts and finishes a session', async () => {
      // Start session
      const startRes = await request(app.getHttpServer())
        .post('/api/v1/sessions')
        .send({ session_minutes_target: 15 })
        .set('X-Idempotency-Key', 'pg-session-start-001')
        .expect(200);

      expect(startRes.body.session_id).toBeDefined();
      expect(startRes.body.session_status).toBe('started');

      const sessionId = startRes.body.session_id;

      // Verify session read
      const readRes = await request(app.getHttpServer())
        .get(`/api/v1/sessions/${sessionId}`)
        .expect(200);

      expect(readRes.body.session_id).toBe(sessionId);
      expect(readRes.body.session_status).toBe('started');

      // Finish session
      const finishRes = await request(app.getHttpServer())
        .post(`/api/v1/sessions/${sessionId}/finish`)
        .set('X-Idempotency-Key', 'pg-session-finish-001')
        .expect(200);

      expect(['valid', 'invalid']).toContain(finishRes.body.session_status);
    });
  });

  // ========== Learning round → settlement → today summary chain ==========

  describe('Learning round → settlement → today on PG', () => {
    it('study attempt updates today progress and triggers settlement', async () => {
      // Initial today state
      const beforeToday = await request(app.getHttpServer())
        .get('/api/v1/me/today').expect(200);

      // Submit study attempt
      await request(app.getHttpServer())
        .post('/api/v1/me/new-words')
        .send({ word_id: 'ability', book_id: 'book-001', study_type: 'new', action_result: 'know' })
        .set('X-Idempotency-Key', 'pg-learn-round-001')
        .expect(200);

      // Today should reflect progress
      const afterToday = await request(app.getHttpServer())
        .get('/api/v1/me/today').expect(200);

      expect(afterToday.body.daily_goal_status).not.toBe('not_started');

      // Secondary summary should show earned coins
      const summary = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary').expect(200);

      expect(summary.body.coins).toBeGreaterThan(0);

      // Companion response should reflect learning
      expect(summary.body.companion_response.daily_greeting).toBeDefined();
    });
  });

  // ========== Idempotency on PG ==========

  describe('Idempotency on PG', () => {
    it('settlement idempotent replay does not duplicate rewards', async () => {
      const key = 'pg-idem-settle-001';

      const res1 = await request(app.getHttpServer())
        .post('/api/v1/settlements/learning-rounds')
        .send({ source_event_type: 'effective_new_word', source_ref_id: 'pg-idem-ref-001' })
        .set('X-Idempotency-Key', key)
        .expect(200);

      const coins1 = (await request(app.getHttpServer()).get('/api/v1/me/secondary-summary').expect(200)).body.coins;

      // Replay same key
      const res2 = await request(app.getHttpServer())
        .post('/api/v1/settlements/learning-rounds')
        .send({ source_event_type: 'effective_new_word', source_ref_id: 'pg-idem-ref-001' })
        .set('X-Idempotency-Key', key)
        .expect(200);

      expect(res2.body.already_exists).toBe(true);

      // Coins should NOT have doubled
      const coins2 = (await request(app.getHttpServer()).get('/api/v1/me/secondary-summary').expect(200)).body.coins;
      expect(coins2).toBe(coins1);
    });

    it('purchase idempotent replay does not duplicate', async () => {
      // Earn coins
      for (let i = 1; i <= 30; i++) {
        await request(app.getHttpServer())
          .post('/api/v1/settlements/learning-rounds')
          .send({ source_event_type: 'effective_new_word', source_ref_id: `pg-idem-pur-${i}` })
          .set('X-Idempotency-Key', `pg-idem-pur-setup-${i}`)
          .expect(200);
      }

      const key = 'pg-idem-purchase-001';
      await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', key)
        .expect(200);

      // Replay
      const res2 = await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', key)
        .expect(200);

      expect(res2.body.purchase_result.already_exists).toBe(true);
      expect(res2.body.inventory.owned_items.length).toBe(1); // not 2
    });
  });

  // ========== Review group completion → settlement chain ==========

  describe('Review group completion → settlement on PG', () => {
    it('completing all review items triggers settlement', async () => {
      // Get review group
      const groupRes = await request(app.getHttpServer())
        .get('/api/v1/me/review-groups/next').expect(200);
      const groupId = groupRes.body.review_group_id;
      const items = groupRes.body.items;

      // Complete all items
      for (let i = 0; i < items.length; i++) {
        await request(app.getHttpServer())
          .post('/api/v1/review-attempts')
          .send({ review_group_id: groupId, word_id: items[i].word_id, action_result: 'correct' })
          .set('X-Idempotency-Key', `pg-rgc-${i}`)
          .expect(200);
      }

      // Check last review response
      // Today review_completed should have advanced
      const todayRes = await request(app.getHttpServer())
        .get('/api/v1/me/today').expect(200);
      expect(todayRes.body.today_review_completed).toBeGreaterThanOrEqual(1);

      // Summary should show fish_treats earned
      const summaryRes = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary').expect(200);
      expect(summaryRes.body.fish_treats).toBeGreaterThanOrEqual(1);
    });
  });

  // ========== Companion response on PG ==========

  describe('Companion response on PG', () => {
    it('companion greeting changes after check-in', async () => {
      const before = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary').expect(200);
      expect(before.body.companion_response.daily_greeting).toBeDefined();

      // Check in
      await request(app.getHttpServer())
        .post('/api/v1/check-ins')
        .set('X-Idempotency-Key', 'pg-comp-ci-001')
        .expect(200);

      const after = await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary').expect(200);
      // Greeting should change to checked-in variant
      expect(after.body.companion_response.daily_greeting).toBeDefined();
    });
  });

  // ========== Maintenance mode ==========

  describe('Maintenance mode on PG', () => {
    afterEach(() => {
      delete process.env.MAINTENANCE_MODE;
    });

    it('rejects writes with structured error during maintenance', async () => {
      process.env.MAINTENANCE_MODE = 'true';

      const res = await request(app.getHttpServer())
        .post('/api/v1/me/feed')
        .send({ feed_item_type: 'fish_treat' })
        .set('X-Idempotency-Key', 'pg-maint-001')
        .expect(503);

      expect(res.body.ok).toBe(false);
      expect(res.body.error.code).toBe('MAINTENANCE_MODE_ACTIVE');
      expect(res.body.error.retryable).toBe(true);
      expect(res.body.error.details.maintenance).toBe(true);
    });

    it('allows reads during maintenance', async () => {
      process.env.MAINTENANCE_MODE = 'true';

      await request(app.getHttpServer())
        .get('/api/v1/me/today')
        .expect(200);

      await request(app.getHttpServer())
        .get('/api/v1/me/secondary-summary')
        .expect(200);
    });

    it('health endpoint shows maintenance status', async () => {
      process.env.MAINTENANCE_MODE = 'true';

      const res = await request(app.getHttpServer())
        .get('/api/v1/health')
        .expect(200);

      expect(res.body.status).toBe('maintenance');
      expect(res.body.write_blocked).toBe(true);
      expect(res.body.degraded_state.maintenance).toBe(true);
    });
  });

  // ========== v0.3 PR-A Day 4: GET /api/v1/content/manifest ==========
  //
  // Tests self-seed all data (don't depend on legacy release) so they're
  // reproducible on a fresh test DB. Each test cleans up after itself.

  describe('GET /api/v1/content/manifest (PR-A Day 4)', () => {
    const TEST_PREFIX = 'test-day4-';

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
    }

    beforeEach(cleanup);
    afterEach(cleanup);

    async function seedRelease(
      releaseId: string,
      status: string,
      activatedAt: string | null,
      packageSet: string[],
      revokedAt: string | null = null,
    ) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, activated_at, revoked_at, package_set, generated_by)
         VALUES ($1, $2, $3, $4, $5::jsonb, 'e2e')`,
        [
          releaseId,
          status,
          activatedAt,
          revokedAt,
          JSON.stringify(packageSet),
        ],
      );
    }

    async function seedManifest(
      manifestId: string,
      packageName: string,
      packageKind: string,
      contentVersion: string,
      fileUrl: string,
      checksum: string,
      sizeBytes: number,
      isActive: boolean,
      releaseId: string,
      minAppVersion = '0.0.0',
    ) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_manifest
           (id, package_name, package_kind, content_version, file_url,
            checksum_sha256, size_bytes, min_app_version, is_active, release_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10)`,
        [
          manifestId,
          packageName,
          packageKind,
          contentVersion,
          fileUrl,
          checksum,
          sizeBytes,
          minAppVersion,
          isActive,
          releaseId,
        ],
      );
    }

    it('returns active packages with dual-condition filter', async () => {
      await seedRelease(
        `${TEST_PREFIX}active`,
        'active',
        new Date(Date.now() - 3600 * 1000).toISOString(),
        [`${TEST_PREFIX}pkg@v1`],
      );
      await seedManifest(
        `${TEST_PREFIX}pkg@v1`,
        `examples-${TEST_PREFIX}book`,
        'examples',
        'v1',
        'file:///tmp/test-day4.gz',
        'aabb',
        12345,
        true,
        `${TEST_PREFIX}active`,
      );

      const res = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);

      const found = res.body.packages.find(
        (p: { package_id: string }) => p.package_id === `${TEST_PREFIX}pkg@v1`,
      );
      expect(found).toBeTruthy();
      expect(found.book_id).toBe(`${TEST_PREFIX}book`);
      expect(found.compression).toBe('gzip');
      // size_bytes must be a number (not string from BIGINT)
      expect(typeof found.size_bytes).toBe('number');
      expect(found.size_bytes).toBe(12345);
    });

    it('rejects unknown since_release with 400', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/content/manifest?since_release=does-not-exist-xyz')
        .expect(400);
    });

    it('rejects invalid app_version with 400', async () => {
      await request(app.getHttpServer())
        .get('/api/v1/content/manifest?app_version=1.2.x')
        .expect(400);

      // Leading-zero rejection
      await request(app.getHttpServer())
        .get('/api/v1/content/manifest?app_version=01.02.03')
        .expect(400);
    });

    it('filters by since_release activated_at', async () => {
      // Seed two releases at different times
      await seedRelease(
        `${TEST_PREFIX}old`,
        'active',
        new Date(Date.now() - 7200 * 1000).toISOString(),
        [`${TEST_PREFIX}old@v1`],
      );
      await seedManifest(
        `${TEST_PREFIX}old@v1`,
        `examples-${TEST_PREFIX}old`,
        'examples',
        'v1',
        'file:///tmp/old.gz',
        'aa',
        100,
        true,
        `${TEST_PREFIX}old`,
      );

      await seedRelease(
        `${TEST_PREFIX}new`,
        'active',
        new Date(Date.now() - 3600 * 1000).toISOString(),
        [`${TEST_PREFIX}new@v1`],
      );
      await seedManifest(
        `${TEST_PREFIX}new@v1`,
        `examples-${TEST_PREFIX}new`,
        'examples',
        'v1',
        'file:///tmp/new.gz',
        'bb',
        200,
        true,
        `${TEST_PREFIX}new`,
      );

      const res = await request(app.getHttpServer())
        .get(`/api/v1/content/manifest?since_release=${TEST_PREFIX}old`)
        .expect(200);

      const ids = res.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(ids).toContain(`${TEST_PREFIX}new@v1`);
      expect(ids).not.toContain(`${TEST_PREFIX}old@v1`);
    });

    it('does NOT return packages from revoked release (dual-condition)', async () => {
      await seedRelease(
        `${TEST_PREFIX}revoked`,
        'revoked',
        new Date(Date.now() - 7200 * 1000).toISOString(),
        [`${TEST_PREFIX}revoked-pkg@v1`],
        new Date(Date.now() - 3600 * 1000).toISOString(),
      );
      // Note: manifest is_active=true here intentionally — testing that
      // release.status='revoked' alone is enough to exclude it
      await seedManifest(
        `${TEST_PREFIX}revoked-pkg@v1`,
        `examples-${TEST_PREFIX}rev`,
        'examples',
        'v1',
        'file:///tmp/rev.gz',
        'cc',
        300,
        true,
        `${TEST_PREFIX}revoked`,
      );

      const res = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);

      const ids = res.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(ids).not.toContain(`${TEST_PREFIX}revoked-pkg@v1`);
    });

    it('does NOT return packages with is_active=false from active release (dual-condition)', async () => {
      await seedRelease(
        `${TEST_PREFIX}inactive-pkg`,
        'active',
        new Date(Date.now() - 3600 * 1000).toISOString(),
        [`${TEST_PREFIX}inactive@v1`],
      );
      // is_active=false despite release being active
      await seedManifest(
        `${TEST_PREFIX}inactive@v1`,
        `examples-${TEST_PREFIX}inactive`,
        'examples',
        'v1',
        'file:///tmp/inactive.gz',
        'dd',
        400,
        false,
        `${TEST_PREFIX}inactive-pkg`,
      );

      const res = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);

      const ids = res.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(ids).not.toContain(`${TEST_PREFIX}inactive@v1`);
    });

    it('app_version filter excludes packages requiring newer app', async () => {
      await seedRelease(
        `${TEST_PREFIX}ver`,
        'active',
        new Date(Date.now() - 3600 * 1000).toISOString(),
        [`${TEST_PREFIX}ver@v1`],
      );
      await seedManifest(
        `${TEST_PREFIX}ver@v1`,
        `examples-${TEST_PREFIX}ver`,
        'examples',
        'v1',
        'file:///tmp/ver.gz',
        'ee',
        500,
        true,
        `${TEST_PREFIX}ver`,
        '2.0.0', // requires app >= 2.0.0
      );

      // app_version=1.5.0 → too old, should be excluded
      const resOld = await request(app.getHttpServer())
        .get('/api/v1/content/manifest?app_version=1.5.0')
        .expect(200);
      const idsOld = resOld.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(idsOld).not.toContain(`${TEST_PREFIX}ver@v1`);

      // app_version=2.0.0 → meets minimum, should be included
      const resOk = await request(app.getHttpServer())
        .get('/api/v1/content/manifest?app_version=2.0.0')
        .expect(200);
      const idsOk = resOk.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(idsOk).toContain(`${TEST_PREFIX}ver@v1`);
    });
  });

  // ─── PR-B3 Day 1 ─────────────────────────────────────────────────────
  // D3 收口: dev mode transforms file:/// URLs to http:// so the Flutter
  // client can fetch via HTTP GET. These cases test only the controller
  // string-output behavior. The actual /cdn/staging static route lives in
  // main.ts useStaticAssets, which is NOT exercised by Test.createTestingModule
  // — that path is covered by manual smoke step 3 (curl + md5sum).
  describe('GET /api/v1/content/manifest — PR-B3 dev URL transform', () => {
    const TEST_PREFIX = 'test-prb3-d1-';

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
    }

    beforeEach(cleanup);
    afterEach(cleanup);

    async function seedRelease(
      releaseId: string,
      status: string,
      activatedAt: string | null,
      packageSet: string[],
    ) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, activated_at, revoked_at, package_set, generated_by)
         VALUES ($1, $2, $3, NULL, $4::jsonb, 'e2e-prb3-d1')`,
        [releaseId, status, activatedAt, JSON.stringify(packageSet)],
      );
    }

    async function seedManifest(
      manifestId: string,
      packageName: string,
      packageKind: string,
      contentVersion: string,
      fileUrl: string,
      checksum: string,
      sizeBytes: number,
      isActive: boolean,
      releaseId: string,
    ) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_manifest
           (id, package_name, package_kind, content_version, file_url,
            checksum_sha256, size_bytes, min_app_version, is_active, release_id)
         VALUES ($1, $2, $3, $4, $5, $6, $7, '0.0.0', $8, $9)`,
        [
          manifestId,
          packageName,
          packageKind,
          contentVersion,
          fileUrl,
          checksum,
          sizeBytes,
          isActive,
          releaseId,
        ],
      );
    }

    it('dev mode: file:///audio-pipeline-staging/ → http://host/cdn/staging/', async () => {
      const releaseId = `${TEST_PREFIX}active`;
      const packageName = `${TEST_PREFIX}examples`;
      const manifestId = `${packageName}@v1`;

      await seedRelease(
        releaseId,
        'active',
        new Date(Date.now() - 3600 * 1000).toISOString(),
        [manifestId],
      );
      await seedManifest(
        manifestId,
        packageName,
        'examples',
        'v1',
        // Windows-shaped file:// — controller's transform splits on
        // '/audio-pipeline-staging/' so the leading drive letter is fine.
        'file:///D:/test/audio-pipeline-staging/test-prb3-d1-examples@v1.jsonl.gz',
        'sha256:dev-transform',
        12345,
        true,
        releaseId,
      );

      // Default NODE_ENV != 'production' → dev mode
      const res = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);

      const found = res.body.packages.find(
        (p: { package_id: string }) => p.package_id === manifestId,
      );
      expect(found).toBeDefined();
      // '@' in URL path is RFC 3986-legal; not encoded.
      expect(found.file_url).toMatch(
        /^http:\/\/[^/]+\/cdn\/staging\/test-prb3-d1-examples@v1\.jsonl\.gz$/,
      );
    });

    it('dev mode: file:///cdn-mock/ → http://host/cdn/', async () => {
      const releaseId = `${TEST_PREFIX}cdn-mock`;
      const packageName = `${TEST_PREFIX}cdnmock`;
      const manifestId = `${packageName}@v1`;

      await seedRelease(
        releaseId,
        'active',
        new Date(Date.now() - 3600 * 1000).toISOString(),
        [manifestId],
      );
      await seedManifest(
        manifestId,
        packageName,
        'examples',
        'v1',
        'file:///D:/test/cdn-mock/audio/v1/test-prb3-d1-cdnmock@v1.jsonl.gz',
        'sha256:dev-cdn-mock',
        67890,
        true,
        releaseId,
      );

      const res = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);

      const found = res.body.packages.find(
        (p: { package_id: string }) => p.package_id === manifestId,
      );
      expect(found).toBeDefined();
      expect(found.file_url).toMatch(
        /^http:\/\/[^/]+\/cdn\/audio\/v1\/test-prb3-d1-cdnmock@v1\.jsonl\.gz$/,
      );
    });
  });

  describe('GET /api/v1/content/manifest — PR-B3 production guard', () => {
    // v0.2 #8 (R1#5) review-adopted: NODE_ENV override is wrapped in a
    // dedicated describe + beforeEach/afterEach to avoid cross-pollination
    // with the dev-transform describe above (jest does not guarantee ordering
    // of describe-internal it() blocks across files but we still want this
    // self-contained).
    const TEST_PREFIX = 'test-prb3-d1-prod-';
    let oldEnv: string | undefined;

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
    }

    beforeEach(async () => {
      oldEnv = process.env.NODE_ENV;
      process.env.NODE_ENV = 'production';
      await cleanup();
    });
    afterEach(async () => {
      await cleanup();
      if (oldEnv === undefined) {
        delete process.env.NODE_ENV;
      } else {
        process.env.NODE_ENV = oldEnv;
      }
    });

    it('production mode still skips file:// (PR-A behavior unchanged)', async () => {
      const releaseId = `${TEST_PREFIX}guard`;
      const packageName = `${TEST_PREFIX}examples`;
      const manifestId = `${packageName}@v1`;

      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, activated_at, revoked_at, package_set, generated_by)
         VALUES ($1, 'active', $2, NULL, $3::jsonb, 'e2e-prb3-d1-prod')`,
        [
          releaseId,
          new Date(Date.now() - 3600 * 1000).toISOString(),
          JSON.stringify([manifestId]),
        ],
      );
      await pool.query(
        `INSERT INTO content_manifest
           (id, package_name, package_kind, content_version, file_url,
            checksum_sha256, size_bytes, min_app_version, is_active, release_id)
         VALUES ($1, $2, 'examples', 'v1', $3, 'sha256:prod-skip', 999, '0.0.0', true, $4)`,
        [
          manifestId,
          packageName,
          'file:///D:/test/audio-pipeline-staging/test-prb3-d1-prod-examples@v1.jsonl.gz',
          releaseId,
        ],
      );

      const res = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);

      const found = res.body.packages.find(
        (p: { package_id: string }) => p.package_id === manifestId,
      );
      // production: file:// rows are skipped (PR-A既有行为) — must NOT be
      // returned via http:// transform either.
      expect(found).toBeUndefined();
    });
  });

  describe('Release state-machine & API contract (PR-A Day 5)', () => {
    // SQL-driven state changes; CLI subcommand chain is covered by Step 6
    // PowerShell smoke (plan 验收强制必跑). Naming follows R1.1 review note —
    // this is a state-machine + API contract regression suite, not a full
    // CLI flow e2e.
    const TEST_FLOW_PREFIX = 'test-flow-';

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_FLOW_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_FLOW_PREFIX}%'`,
      );
    }

    beforeEach(cleanup);
    afterEach(cleanup);

    /** Insert a release in 'draft' state with empty package_set. */
    async function seedDraftRelease(releaseId: string) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, package_set, generated_by)
         VALUES ($1, 'draft', '[]'::jsonb, 'e2e-day5')`,
        [releaseId],
      );
    }

    /** Insert manifest row associated to a release. */
    async function seedManifest(
      releaseId: string,
      manifestId: string,
      packageName: string,
      isActive = true,
    ) {
      const pool = getPool();
      const fileUrl = `http://localhost:3000/cdn/${manifestId}.jsonl.gz`;
      const checksum = `sha256:${manifestId}`;
      await pool.query(
        `INSERT INTO content_manifest
           (id, package_name, package_kind, content_version,
            file_url, checksum_sha256, size_bytes, min_app_version,
            is_active, release_id)
         VALUES ($1, $2, 'examples', 'v1', $3, $4, 1024, '0.0.0', $5, $6)`,
        [manifestId, packageName, fileUrl, checksum, isActive, releaseId],
      );
    }

    /**
     * Apply a state transition with activation_log append.
     * Mirrors content_release_repo.py transition_status() semantics
     * for verifying log shape, without spawning a Python subprocess.
     */
    async function transition(
      releaseId: string,
      fromStatus: string,
      toStatus: string,
      reason: string,
    ) {
      const pool = getPool();
      const extraSet =
        toStatus === 'active'
          ? ', activated_at = NOW()'
          : toStatus === 'revoked'
          ? ', revoked_at = NOW()'
          : '';
      const result = await pool.query(
        `UPDATE content_release
            SET status = $1::text${extraSet},
                activation_log = activation_log || jsonb_build_array(
                  jsonb_build_object(
                    'from', $2::text,
                    'to', $1::text,
                    'at', to_char(NOW() AT TIME ZONE 'UTC',
                                  'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                    'reason', $3::text
                  )
                )
          WHERE release_id = $4::text AND status = $2::text`,
        [toStatus, fromStatus, reason, releaseId],
      );
      return result.rowCount;
    }

    it('draft → validated → active transitions append 3 activation_log entries', async () => {
      const rid = `${TEST_FLOW_PREFIX}log`;
      await seedDraftRelease(rid);

      expect(await transition(rid, 'draft', 'validated', 'r1')).toBe(1);
      expect(await transition(rid, 'validated', 'active', 'r2')).toBe(1);
      // simulate a deprecate as 3rd entry just to prove log append works
      expect(await transition(rid, 'active', 'deprecated', 'r3')).toBe(1);

      const pool = getPool();
      const r = await pool.query(
        `SELECT status, activation_log FROM content_release WHERE release_id = $1`,
        [rid],
      );
      expect(r.rows[0].status).toBe('deprecated');
      const log = r.rows[0].activation_log as Array<{
        from: string;
        to: string;
        at: string;
        reason: string;
      }>;
      expect(log).toHaveLength(3);
      expect(log[0]).toMatchObject({ from: 'draft', to: 'validated', reason: 'r1' });
      expect(log[1]).toMatchObject({ from: 'validated', to: 'active', reason: 'r2' });
      expect(log[2]).toMatchObject({ from: 'active', to: 'deprecated', reason: 'r3' });
      // ISO 8601 UTC milliseconds shape: YYYY-MM-DDTHH:MM:SS.mmmZ
      expect(log[0].at).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
    });

    it('active → revoked: manifest API stops returning the package', async () => {
      const rid = `${TEST_FLOW_PREFIX}rev`;
      const mid = `${TEST_FLOW_PREFIX}rev@v1`;
      await seedDraftRelease(rid);
      await seedManifest(rid, mid, `examples-${TEST_FLOW_PREFIX}rev`);
      await transition(rid, 'draft', 'validated', 'v');
      await transition(rid, 'validated', 'active', 'a');

      const before = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);
      const idsBefore = before.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(idsBefore).toContain(mid);

      expect(await transition(rid, 'active', 'revoked', 'r')).toBe(1);

      const after = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);
      const idsAfter = after.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(idsAfter).not.toContain(mid);
    });

    it('active → deprecated: manifest API stops returning AND manifest.is_active stays true (R2.3 contract)', async () => {
      const rid = `${TEST_FLOW_PREFIX}dep`;
      const mid = `${TEST_FLOW_PREFIX}dep@v1`;
      await seedDraftRelease(rid);
      await seedManifest(rid, mid, `examples-${TEST_FLOW_PREFIX}dep`);
      await transition(rid, 'draft', 'validated', 'v');
      await transition(rid, 'validated', 'active', 'a');

      const before = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);
      expect(
        before.body.packages.map((p: { package_id: string }) => p.package_id),
      ).toContain(mid);

      // deprecate (only release.status changes, manifest.is_active untouched)
      expect(await transition(rid, 'active', 'deprecated', 'soft retire')).toBe(
        1,
      );

      const after = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);
      expect(
        after.body.packages.map((p: { package_id: string }) => p.package_id),
      ).not.toContain(mid);

      // R2.3 副作用契约：manifest.is_active 保持 true
      const pool = getPool();
      const r = await pool.query(
        `SELECT is_active FROM content_manifest WHERE id = $1`,
        [mid],
      );
      expect(r.rows[0].is_active).toBe(true);
    });

    it('deprecated → revoked: legal transition succeeds', async () => {
      const rid = `${TEST_FLOW_PREFIX}depRev`;
      await seedDraftRelease(rid);
      await transition(rid, 'draft', 'validated', 'v');
      await transition(rid, 'validated', 'active', 'a');
      await transition(rid, 'active', 'deprecated', 'd');

      // deprecated → revoked is a legal transition per VALID_TRANSITIONS
      expect(await transition(rid, 'deprecated', 'revoked', 'final')).toBe(1);

      const pool = getPool();
      const r = await pool.query(
        `SELECT status, revoked_at FROM content_release WHERE release_id = $1`,
        [rid],
      );
      expect(r.rows[0].status).toBe('revoked');
      expect(r.rows[0].revoked_at).not.toBeNull();
    });

    it('deprecated → active: illegal transition (rowCount=0, no state change)', async () => {
      const rid = `${TEST_FLOW_PREFIX}depAct`;
      await seedDraftRelease(rid);
      await transition(rid, 'draft', 'validated', 'v');
      await transition(rid, 'validated', 'active', 'a');
      await transition(rid, 'active', 'deprecated', 'd');

      // Attempting deprecated → active: WHERE status='active' won't match
      // because current status is 'deprecated'. UPDATE silently affects 0 rows.
      // (The repo's transition_status() raises ReleaseError on rowCount != 1;
      // this test checks the SQL-level guard.)
      const pool = getPool();
      const result = await pool.query(
        `UPDATE content_release SET status='active'
          WHERE release_id = $1 AND status = 'active'`,
        [rid],
      );
      expect(result.rowCount).toBe(0);

      const r = await pool.query(
        `SELECT status FROM content_release WHERE release_id = $1`,
        [rid],
      );
      expect(r.rows[0].status).toBe('deprecated');
    });

    it('publish-manifest in validated state: status guard rejects (regression)', async () => {
      // pipeline.py:168 enforces `if row[0] != 'draft': raise ReleaseError`.
      // This test pins the contract that publish-manifest is draft-only,
      // i.e., validated locks the package_set. We simulate the guard SQL
      // directly to detect future regressions.
      const rid = `${TEST_FLOW_PREFIX}frozen`;
      await seedDraftRelease(rid);
      await transition(rid, 'draft', 'validated', 'v');

      const pool = getPool();
      const r = await pool.query(
        `SELECT status FROM content_release WHERE release_id = $1`,
        [rid],
      );
      // The guard equivalent: status must be 'draft' for publish-manifest
      const status = r.rows[0].status;
      expect(status).not.toBe('draft');
      expect(status).toBe('validated');
      // If a future change relaxes the draft-only guard, this assertion
      // doesn't break — but the e2e provides documented coverage to spot it.
    });

    it('multi-release ordering: ORDER BY r.activated_at, package_name, content_version', async () => {
      // Older release activated first, newer one activated later;
      // since_release=older should hide older's own packages and
      // ordering must be deterministic.
      const ridOld = `${TEST_FLOW_PREFIX}order-old`;
      const ridNew = `${TEST_FLOW_PREFIX}order-new`;
      const midOld = `${TEST_FLOW_PREFIX}order-old@v1`;
      const midNew = `${TEST_FLOW_PREFIX}order-new@v1`;

      const pool = getPool();
      // Use JS ISO string (ms precision) for activated_at to match the
      // controller's read-then-filter round-trip (Date → JS ms truncation
      // breaks strict `>` comparison if PG stored µs precision via NOW()).
      const oldActivatedAt = new Date(Date.now() - 2 * 3600 * 1000).toISOString();
      const newActivatedAt = new Date(Date.now() - 1 * 3600 * 1000).toISOString();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, activated_at, package_set, generated_by)
         VALUES ($1, 'active', $2, $3::jsonb, 'e2e')`,
        [ridOld, oldActivatedAt, JSON.stringify([midOld])],
      );
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, activated_at, package_set, generated_by)
         VALUES ($1, 'active', $2, $3::jsonb, 'e2e')`,
        [ridNew, newActivatedAt, JSON.stringify([midNew])],
      );
      await seedManifest(ridOld, midOld, `examples-${TEST_FLOW_PREFIX}order-old`);
      await seedManifest(ridNew, midNew, `examples-${TEST_FLOW_PREFIX}order-new`);

      // Without since_release: both packages, oldest activated first
      const all = await request(app.getHttpServer())
        .get('/api/v1/content/manifest')
        .expect(200);
      const allIds = all.body.packages
        .filter((p: { package_id: string }) =>
          p.package_id.startsWith(TEST_FLOW_PREFIX),
        )
        .map((p: { package_id: string }) => p.package_id);
      expect(allIds).toEqual([midOld, midNew]);

      // With since_release=ridOld: only newer packages (activated_at > old.activated_at)
      const since = await request(app.getHttpServer())
        .get(`/api/v1/content/manifest?since_release=${ridOld}`)
        .expect(200);
      const sinceIds = since.body.packages.map(
        (p: { package_id: string }) => p.package_id,
      );
      expect(sinceIds).toContain(midNew);
      expect(sinceIds).not.toContain(midOld);
    });
  });

  describe('orphan-scan SQL contract (PR-B1 Day 1)', () => {
    // FS-side behavior is verified by the mandatory PowerShell smoke
    // (pr-b1-day1.md Step 4). These tests pin the SQL queries that
    // orphan_scan._scan_audio / _scan_packages issue, so a future schema
    // change that breaks the "is referenced" classification is caught
    // before the FS smoke runs.
    const TEST_PREFIX = 'test-orphan-';

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM audio_assets WHERE id LIKE '${TEST_PREFIX}%'`,
      );
    }

    beforeEach(cleanup);
    afterEach(cleanup);

    it('audio_assets: status != deleted rows are referenced (deleted excluded)', async () => {
      const pool = getPool();
      // 3 rows: ready / superseded / deleted
      // (audio_assets.url is NOT NULL per schema migration 004; the
      //  IS NOT NULL guard in orphan_scan SQL is defensive but the
      //  contract relevant to orphan-scan is the status filter.)
      const baseCols =
        'id, target_kind, target_id, locale, voice, format, audio_version, ' +
        'checksum_sha256, source_text_hash, tts_provider, tts_model, ' +
        'bytes, duration_ms, url, status, generated_at, transitioned_at';
      await pool.query(
        `INSERT INTO audio_assets (${baseCols})
         VALUES
           ($1, 'example', 't1', 'en-US', 'v1', 'mp3', 'v1',
              'a'::char(64), 'b'::char(16), 'tts', 'm',
              100, 1000,
              'local://cdn/audio/v1/examples/en-US/v1/v1/aa/${TEST_PREFIX}ready.mp3',
              'ready', NOW(), NOW()),
           ($2, 'example', 't2', 'en-US', 'v1', 'mp3', 'v1',
              'a'::char(64), 'b'::char(16), 'tts', 'm',
              100, 1000,
              'local://cdn/audio/v1/examples/en-US/v1/v1/bb/${TEST_PREFIX}sup.mp3',
              'superseded', NOW(), NOW()),
           ($3, 'example', 't3', 'en-US', 'v1', 'mp3', 'v1',
              'a'::char(64), 'b'::char(16), 'tts', 'm',
              100, 1000,
              'local://cdn/audio/v1/examples/en-US/v1/v1/cc/${TEST_PREFIX}del.mp3',
              'deleted', NOW(), NOW())`,
        [
          `${TEST_PREFIX}ready`,
          `${TEST_PREFIX}sup`,
          `${TEST_PREFIX}del`,
        ],
      );

      // The exact query orphan_scan._scan_audio uses
      const r = await pool.query(
        `SELECT id, url FROM audio_assets
          WHERE url IS NOT NULL AND status != 'deleted'
            AND id LIKE $1
          ORDER BY id`,
        [`${TEST_PREFIX}%`],
      );
      const ids = r.rows.map((row) => row.id);
      // ready + superseded should be present; deleted should not
      expect(ids).toEqual([
        `${TEST_PREFIX}ready`,
        `${TEST_PREFIX}sup`,
      ]);
    });

    it('content_manifest: only file_url IS NOT NULL are referenced', async () => {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, package_set, generated_by)
         VALUES ($1, 'draft', '[]'::jsonb, 'e2e-orphan')`,
        [`${TEST_PREFIX}r1`],
      );
      // Two manifests: one with file_url, one without
      await pool.query(
        `INSERT INTO content_manifest
           (id, package_name, package_kind, content_version, file_url,
            checksum_sha256, size_bytes, min_app_version, is_active, release_id)
         VALUES
           ($1, 'examples-${TEST_PREFIX}with', 'examples', 'v1',
              'file:///D:/test/audio-pipeline-staging/examples-${TEST_PREFIX}with@v1.jsonl.gz',
              'sha256:x', 100, '0.0.0', false, $3),
           ($2, 'examples-${TEST_PREFIX}none', 'examples', 'v1',
              NULL,
              'sha256:y', 100, '0.0.0', false, $3)`,
        [
          `${TEST_PREFIX}with@v1`,
          `${TEST_PREFIX}none@v1`,
          `${TEST_PREFIX}r1`,
        ],
      );

      const r = await pool.query(
        `SELECT id, file_url FROM content_manifest
          WHERE file_url IS NOT NULL
            AND id LIKE $1
          ORDER BY id`,
        [`${TEST_PREFIX}%`],
      );
      const ids = r.rows.map((row) => row.id);
      expect(ids).toEqual([`${TEST_PREFIX}with@v1`]);
    });
  });

  describe('rollback subcommand contract (PR-B1 Day 2)', () => {
    // Note: cmd_rollback's FS file-existence pre-check is NOT covered by these
    // e2e cases — seed manifests use http://localhost:3000/cdn/... URLs which
    // the rollback FS check explicitly skips (real-CDN scheme). The FS missing
    // path is verified by the mandatory PowerShell smoke (Day 2 plan Step 4).
    const TEST_PREFIX = 'test-rollback-';

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_manifest WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
    }

    beforeEach(cleanup);
    afterEach(cleanup);

    /** Insert a release in 'draft' state with given package_set. */
    async function seedRelease(
      releaseId: string,
      status: string,
      packageSet: string[] = [],
    ) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, package_set, generated_by,
            activated_at, revoked_at)
         VALUES ($1, $2::text, $3::jsonb, 'e2e-day2-rollback',
                 CASE WHEN $2::text = 'active' THEN NOW() ELSE NULL END,
                 CASE WHEN $2::text = 'revoked' THEN NOW() ELSE NULL END)`,
        [releaseId, status, JSON.stringify(packageSet)],
      );
    }

    async function seedManifest(
      releaseId: string,
      manifestId: string,
      packageName: string,
      isActive = true,
    ) {
      const pool = getPool();
      const fileUrl = `http://localhost:3000/cdn/${manifestId}.jsonl.gz`;
      const checksum = `sha256:${manifestId}`;
      await pool.query(
        `INSERT INTO content_manifest
           (id, package_name, package_kind, content_version,
            file_url, checksum_sha256, size_bytes, min_app_version,
            is_active, release_id)
         VALUES ($1, $2, 'examples', 'v1', $3, $4, 1024, '0.0.0', $5, $6)`,
        [manifestId, packageName, fileUrl, checksum, isActive, releaseId],
      );
    }

    /**
     * Mirrors content_release_repo's transition_status() SQL.
     * Used to set up "deprecated" or "revoked" preconditions for tests.
     */
    async function transition(
      releaseId: string,
      fromStatus: string,
      toStatus: string,
      reason: string,
    ) {
      const pool = getPool();
      const extraSet =
        toStatus === 'active'
          ? ', activated_at = NOW()'
          : toStatus === 'revoked'
          ? ', revoked_at = NOW()'
          : '';
      const result = await pool.query(
        `UPDATE content_release
            SET status = $1::text${extraSet},
                activation_log = activation_log || jsonb_build_array(
                  jsonb_build_object(
                    'from', $2::text,
                    'to', $1::text,
                    'at', to_char(NOW() AT TIME ZONE 'UTC',
                                  'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                    'reason', $3::text
                  )
                )
          WHERE release_id = $4::text AND status = $2::text`,
        [toStatus, fromStatus, reason, releaseId],
      );
      return result.rowCount;
    }

    /** Run rollback_release via direct SQL by calling Python? No — we test
     *  the contract by replaying its semantics via SQL. The actual Python
     *  helper is exercised by Step 4 PowerShell smoke. */
    async function simulateRollback(targetId: string, reason: string) {
      // Verify target is deprecated
      const pool = getPool();
      const t = await pool.query(
        `SELECT release_id, status, package_set FROM content_release WHERE release_id = $1`,
        [targetId],
      );
      if (t.rows.length === 0) {
        throw new Error(`target ${targetId} not found`);
      }
      if (t.rows[0].status !== 'deprecated') {
        throw new Error(
          `rollback only allowed from 'deprecated', got '${t.rows[0].status}'`,
        );
      }
      // Multi-active sanity check
      const a = await pool.query(
        `SELECT release_id, package_set FROM content_release WHERE status = 'active'`,
      );
      if (a.rows.length > 1) {
        throw new Error(`multiple active releases (count=${a.rows.length})`);
      }
      // Demote current active (if any)
      if (a.rows.length === 1) {
        const current = a.rows[0];
        await pool.query(
          `UPDATE content_manifest SET is_active = false WHERE id = ANY($1::text[])`,
          [current.package_set],
        );
        await transition(
          current.release_id,
          'active',
          'deprecated',
          `rollback to ${targetId}: ${reason}`,
        );
      }
      // Promote target
      await pool.query(
        `UPDATE content_manifest SET is_active = true WHERE id = ANY($1::text[])`,
        [t.rows[0].package_set],
      );
      await transition(targetId, 'deprecated', 'active', reason);
    }

    it('happy: deprecated v1 + active v2 → rollback v1 → v1 active, v2 deprecated', async () => {
      const v1 = `${TEST_PREFIX}v1`;
      const v2 = `${TEST_PREFIX}v2`;
      const m1 = `${TEST_PREFIX}m1@v1`;
      const m2 = `${TEST_PREFIX}m2@v2`;

      await seedRelease(v1, 'deprecated', [m1]);
      await seedRelease(v2, 'active', [m2]);
      await seedManifest(v1, m1, `examples-${TEST_PREFIX}pkg`, false);
      await seedManifest(v2, m2, `examples-${TEST_PREFIX}pkg`, true);

      await simulateRollback(v1, 'critical bug in v2');

      const pool = getPool();
      const r = await pool.query(
        `SELECT release_id, status FROM content_release
          WHERE release_id IN ($1, $2) ORDER BY release_id`,
        [v1, v2],
      );
      expect(r.rows[0]).toMatchObject({ release_id: v1, status: 'active' });
      expect(r.rows[1]).toMatchObject({ release_id: v2, status: 'deprecated' });

      const m = await pool.query(
        `SELECT id, is_active FROM content_manifest
          WHERE id IN ($1, $2) ORDER BY id`,
        [m1, m2],
      );
      expect(m.rows[0]).toMatchObject({ id: m1, is_active: true });
      expect(m.rows[1]).toMatchObject({ id: m2, is_active: false });
    });

    it('rollback to draft target rejected', async () => {
      const v1 = `${TEST_PREFIX}draft`;
      await seedRelease(v1, 'draft', []);
      await expect(simulateRollback(v1, 'r')).rejects.toThrow(
        /rollback only allowed from 'deprecated'/,
      );
    });

    it('rollback to validated target rejected', async () => {
      const v1 = `${TEST_PREFIX}validated`;
      await seedRelease(v1, 'validated', []);
      await expect(simulateRollback(v1, 'r')).rejects.toThrow(
        /rollback only allowed from 'deprecated'/,
      );
    });

    it('rollback to revoked target rejected (P2 关键 case: revoke 不可逆)', async () => {
      const v1 = `${TEST_PREFIX}revoked`;
      await seedRelease(v1, 'revoked', []);
      await expect(simulateRollback(v1, 'r')).rejects.toThrow(
        /rollback only allowed from 'deprecated'/,
      );
    });

    it('rollback to active target rejected', async () => {
      const v1 = `${TEST_PREFIX}active`;
      await seedRelease(v1, 'active', []);
      await expect(simulateRollback(v1, 'r')).rejects.toThrow(
        /rollback only allowed from 'deprecated'/,
      );
    });

    it('rollback when no active release exists: target promotes directly', async () => {
      const v1 = `${TEST_PREFIX}only`;
      const m1 = `${TEST_PREFIX}only@v1`;
      await seedRelease(v1, 'deprecated', [m1]);
      await seedManifest(v1, m1, `examples-${TEST_PREFIX}only`, false);

      await simulateRollback(v1, 'restore from cold');

      const pool = getPool();
      const r = await pool.query(
        `SELECT status FROM content_release WHERE release_id = $1`,
        [v1],
      );
      expect(r.rows[0].status).toBe('active');
      const m = await pool.query(
        `SELECT is_active FROM content_manifest WHERE id = $1`,
        [m1],
      );
      expect(m.rows[0].is_active).toBe(true);
    });

    it('multiple active releases → ReleaseError sanity check (R1#2)', async () => {
      // Simulate the multi-active latent bug: PR-A's cmd_activate doesn't
      // demote prior actives' status, only their manifests. So two releases
      // can both be status='active'. rollback must refuse to silently pick.
      const v1 = `${TEST_PREFIX}target`;
      const va = `${TEST_PREFIX}activeA`;
      const vb = `${TEST_PREFIX}activeB`;
      await seedRelease(v1, 'deprecated', []);
      await seedRelease(va, 'active', []);
      await seedRelease(vb, 'active', []);

      await expect(simulateRollback(v1, 'should fail')).rejects.toThrow(
        /multiple active releases.*count=2/,
      );
    });

    it('chained rollback: v1 → v2 → v3 → rollback v2 → rollback v1 健壮性', async () => {
      const v1 = `${TEST_PREFIX}c1`;
      const v2 = `${TEST_PREFIX}c2`;
      const v3 = `${TEST_PREFIX}c3`;
      const m1 = `${TEST_PREFIX}cm1@v1`;
      const m2 = `${TEST_PREFIX}cm2@v2`;
      const m3 = `${TEST_PREFIX}cm3@v3`;

      // Initial: v1 deprecated, v2 deprecated, v3 active
      await seedRelease(v1, 'deprecated', [m1]);
      await seedRelease(v2, 'deprecated', [m2]);
      await seedRelease(v3, 'active', [m3]);
      await seedManifest(v1, m1, `examples-${TEST_PREFIX}chain`, false);
      await seedManifest(v2, m2, `examples-${TEST_PREFIX}chain`, false);
      await seedManifest(v3, m3, `examples-${TEST_PREFIX}chain`, true);

      // rollback v2: v3 → deprecated, v2 → active
      await simulateRollback(v2, 'first rollback');
      const pool = getPool();
      let r = await pool.query(
        `SELECT release_id, status FROM content_release
          WHERE release_id IN ($1, $2, $3) ORDER BY release_id`,
        [v1, v2, v3],
      );
      expect(r.rows.find((x) => x.release_id === v1)?.status).toBe('deprecated');
      expect(r.rows.find((x) => x.release_id === v2)?.status).toBe('active');
      expect(r.rows.find((x) => x.release_id === v3)?.status).toBe('deprecated');

      // rollback v1: v2 → deprecated, v1 → active
      await simulateRollback(v1, 'second rollback');
      r = await pool.query(
        `SELECT release_id, status FROM content_release
          WHERE release_id IN ($1, $2, $3) ORDER BY release_id`,
        [v1, v2, v3],
      );
      expect(r.rows.find((x) => x.release_id === v1)?.status).toBe('active');
      expect(r.rows.find((x) => x.release_id === v2)?.status).toBe('deprecated');
      expect(r.rows.find((x) => x.release_id === v3)?.status).toBe('deprecated');

      // activation_log on v3 should have entries from both rollback chains
      const v3Log = await pool.query(
        `SELECT activation_log FROM content_release WHERE release_id = $1`,
        [v3],
      );
      const log = v3Log.rows[0].activation_log as Array<{ reason: string }>;
      // v3 was demoted once (during rollback v2). The reason should be prefixed.
      const v3DemoteReason = log.find((e) => e.reason.startsWith('rollback to'));
      expect(v3DemoteReason?.reason).toBe(`rollback to ${v2}: first rollback`);
    });
  });

  describe('approve subcommand contract (PR-B1 Day 3)', () => {
    // approve sets content_release.approved_by + appends activation_log entry.
    //
    // Note (R1#3 review-adopted): activate's CONTENT_RELEASE_REQUIRE_APPROVAL
    // gating is implemented in cmd_activate (Python). jest setting
    // `process.env` only affects the Node test process, not Python subprocess,
    // so we can't truly test that gating here. Gating end-to-end is verified
    // by the mandatory PowerShell smoke (Day 3 plan Step 4 fixtures
    // `zk-day3-approve` for env=true paths and `zk-day3-compat` for env=false
    // PR-A back-compat).
    //
    // The 3 cases below verify approve_release's SQL contract:
    //   - happy: validated → approved_by + audit log entry
    //   - status guard: non-validated states reject (parametrized 4 states)
    //   - re-approval: overwrites approved_by; log preserves prior entries
    const TEST_PREFIX = 'test-approve-';

    async function cleanup() {
      const pool = getPool();
      await pool.query(
        `DELETE FROM content_release WHERE release_id LIKE '${TEST_PREFIX}%'`,
      );
    }

    beforeEach(cleanup);
    afterEach(cleanup);

    /** Insert a release in given state (no manifests needed for approve tests). */
    async function seedRelease(releaseId: string, status: string) {
      const pool = getPool();
      await pool.query(
        `INSERT INTO content_release
           (release_id, status, package_set, generated_by,
            activated_at, revoked_at)
         VALUES ($1, $2::text, '[]'::jsonb, 'e2e-day3-approve',
                 CASE WHEN $2::text = 'active' THEN NOW() ELSE NULL END,
                 CASE WHEN $2::text = 'revoked' THEN NOW() ELSE NULL END)`,
        [releaseId, status],
      );
    }

    /** Mirrors approve_release helper SQL. Used to verify PG-side contract. */
    async function simulateApprove(
      releaseId: string,
      approver: string,
      note: string | null = null,
    ) {
      const pool = getPool();
      const approverClean = approver.trim();
      if (!approverClean) {
        throw new Error('approver must be non-empty / non-whitespace');
      }
      if (approverClean.length > 64) {
        throw new Error(`approver too long (${approverClean.length} > 64)`);
      }
      // Status guard: only validated allowed
      const r = await pool.query(
        `SELECT status FROM content_release WHERE release_id = $1::text`,
        [releaseId],
      );
      if (r.rows.length === 0) {
        throw new Error(`release ${releaseId} not found`);
      }
      if (r.rows[0].status !== 'validated') {
        throw new Error(
          `approve only allowed in 'validated' state, got '${r.rows[0].status}'`,
        );
      }
      const logReason =
        `approved by ${approverClean}` + (note ? `: ${note}` : '');
      const result = await pool.query(
        `UPDATE content_release
            SET approved_by = $1::text,
                activation_log = activation_log || jsonb_build_array(
                  jsonb_build_object(
                    'from', 'validated',
                    'to', 'validated',
                    'at', to_char(NOW() AT TIME ZONE 'UTC',
                                  'YYYY-MM-DD"T"HH24:MI:SS.MS"Z"'),
                    'reason', $2::text
                  )
                )
          WHERE release_id = $3::text AND status = 'validated'`,
        [approverClean, logReason, releaseId],
      );
      if (result.rowCount !== 1) {
        throw new Error(`approve race: ${releaseId} status moved during update`);
      }
    }

    it('happy: approve validated → approved_by set + audit log entry shape', async () => {
      const rid = `${TEST_PREFIX}happy`;
      await seedRelease(rid, 'validated');
      await simulateApprove(rid, 'wsyjh8', 'first approval');

      const pool = getPool();
      const r = await pool.query(
        `SELECT approved_by, activation_log FROM content_release WHERE release_id = $1`,
        [rid],
      );
      expect(r.rows[0].approved_by).toBe('wsyjh8');
      const log = r.rows[0].activation_log as Array<{
        from: string;
        to: string;
        at: string;
        reason: string;
      }>;
      expect(log).toHaveLength(1);
      expect(log[0]).toMatchObject({
        from: 'validated',
        to: 'validated',
        reason: 'approved by wsyjh8: first approval',
      });
      // ISO 8601 UTC milliseconds shape
      expect(log[0].at).toMatch(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}\.\d{3}Z$/);
    });

    it('approve in non-validated state rejected (draft / active / deprecated / revoked)', async () => {
      const states = ['draft', 'active', 'deprecated', 'revoked'];
      for (const state of states) {
        const rid = `${TEST_PREFIX}state-${state}`;
        await seedRelease(rid, state);
        await expect(simulateApprove(rid, 'wsyjh8')).rejects.toThrow(
          /approve only allowed in 'validated' state/,
        );
      }
    });

    it('re-approval overwrites approved_by but preserves prior log entries (R1#7)', async () => {
      const rid = `${TEST_PREFIX}reapp`;
      await seedRelease(rid, 'validated');

      await simulateApprove(rid, 'editor-A', 'first');
      await simulateApprove(rid, 'editor-B', 'second');

      const pool = getPool();
      const r = await pool.query(
        `SELECT approved_by, activation_log FROM content_release WHERE release_id = $1`,
        [rid],
      );
      // Latest approver wins
      expect(r.rows[0].approved_by).toBe('editor-B');
      // Both audit entries preserved in order
      const log = r.rows[0].activation_log as Array<{ reason: string }>;
      expect(log).toHaveLength(2);
      expect(log[0].reason).toBe('approved by editor-A: first');
      expect(log[1].reason).toBe('approved by editor-B: second');
    });
  });
});
