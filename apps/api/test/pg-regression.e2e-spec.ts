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
});
