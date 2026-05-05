/**
 * Degraded-State Gating Tests (Option A.1 H1).
 *
 * Proves that maintenance / read_only / temporarily_unavailable
 * actually block writes, return structured errors, and don't
 * push state, issue rewards, or write ledger entries.
 */

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication, ValidationPipe } from '@nestjs/common';
import * as request from 'supertest';
import { AppModule } from './../src/app.module';
import { devStore } from './../src/domain';

// PERSISTENCE_BACKEND=json set via jest-env-setup.ts (setupFiles)

describe('Degraded-State Write Gating (H1)', () => {
  let app: INestApplication;

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();

    app = moduleFixture.createNestApplication();
    app.useGlobalPipes(new ValidationPipe());
    app.setGlobalPrefix('api/v1');
    await app.init();
  });

  afterAll(async () => {
    await app.close();
  });

  beforeEach(() => {
    devStore.reset();
    delete process.env.MAINTENANCE_MODE;
    delete process.env.READ_ONLY_MODE;
    delete process.env.TEMPORARILY_UNAVAILABLE;
  });

  afterEach(() => {
    delete process.env.MAINTENANCE_MODE;
    delete process.env.READ_ONLY_MODE;
    delete process.env.TEMPORARILY_UNAVAILABLE;
  });

  // ========== Helper ==========

  function expectDegradedResponse(res: any, expectedCode: string) {
    expect(res.status).toBe(503);
    expect(res.body.ok).toBe(false);
    expect(res.body.error).toBeDefined();
    expect(res.body.error.code).toBe(expectedCode);
    expect(res.body.error.retryable).toBe(true);
    expect(res.body.error.details).toBeDefined();
    // Must NOT be a generic error
    expect(res.body.error.code).not.toBe('INTERNAL_SERVER_ERROR');
    expect(res.body.error.code).not.toBe('UNKNOWN_ERROR');
  }

  // ========== MAINTENANCE_MODE ==========

  describe('MAINTENANCE_MODE=true', () => {
    beforeEach(() => { process.env.MAINTENANCE_MODE = 'true'; });

    it('blocks study attempt submission', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/new-words')
        .send({ word_id: 'abandon', book_id: 'book-001', study_type: 'new', action_result: 'know' })
        .set('X-Idempotency-Key', 'maint-study-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks review attempt submission', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/review-attempts')
        .send({ review_group_id: 'rg-fake', word_id: 'background', action_result: 'correct' })
        .set('X-Idempotency-Key', 'maint-review-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks session start', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/sessions')
        .send({ session_minutes_target: 15 })
        .set('X-Idempotency-Key', 'maint-session-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks check-in', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/check-ins')
        .set('X-Idempotency-Key', 'maint-checkin-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks settlement', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/settlements/learning-rounds')
        .send({ source_event_type: 'effective_new_word', source_ref_id: 'maint-ref-001' })
        .set('X-Idempotency-Key', 'maint-settle-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks feed', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/feed')
        .send({ feed_item_type: 'fish_treat' })
        .set('X-Idempotency-Key', 'maint-feed-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks purchase', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'maint-purchase-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks equip', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/equipment/equip')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'maint-equip-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('blocks unequip', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/equipment/unequip')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'maint-unequip-001');
      expectDegradedResponse(res, 'MAINTENANCE_MODE_ACTIVE');
    });

    it('does NOT advance state after blocked write', async () => {
      // Get initial state
      const beforeToday = await request(app.getHttpServer()).get('/api/v1/me/today').expect(200);

      // Attempt blocked study
      await request(app.getHttpServer())
        .post('/api/v1/me/new-words')
        .send({ word_id: 'abandon', book_id: 'book-001', study_type: 'new', action_result: 'know' })
        .set('X-Idempotency-Key', 'maint-noadvance-001')
        .expect(503);

      // State must NOT have advanced
      const afterToday = await request(app.getHttpServer()).get('/api/v1/me/today').expect(200);
      expect(afterToday.body.today_new_completed).toBe(beforeToday.body.today_new_completed);
    });

    it('does NOT generate rewards after blocked settlement', async () => {
      const beforeSummary = await request(app.getHttpServer()).get('/api/v1/me/secondary-summary').expect(200);

      await request(app.getHttpServer())
        .post('/api/v1/settlements/learning-rounds')
        .send({ source_event_type: 'effective_new_word', source_ref_id: 'maint-noreward-001' })
        .set('X-Idempotency-Key', 'maint-noreward-001')
        .expect(503);

      const afterSummary = await request(app.getHttpServer()).get('/api/v1/me/secondary-summary').expect(200);
      expect(afterSummary.body.coins).toBe(beforeSummary.body.coins);
    });

    it('allows GET reads during maintenance', async () => {
      await request(app.getHttpServer()).get('/api/v1/me/today').expect(200);
      await request(app.getHttpServer()).get('/api/v1/me/secondary-summary').expect(200);
      await request(app.getHttpServer()).get('/api/v1/me/inventory').expect(200);
      await request(app.getHttpServer()).get('/api/v1/me/equipment').expect(200);
      await request(app.getHttpServer()).get('/api/v1/shop/catalog').expect(200);
    });

    it('health shows maintenance status', async () => {
      const res = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
      expect(res.body.status).toBe('maintenance');
      expect(res.body.write_blocked).toBe(true);
      expect(res.body.degraded_state.maintenance).toBe(true);
    });
  });

  // ========== READ_ONLY_MODE ==========

  describe('READ_ONLY_MODE=true', () => {
    beforeEach(() => { process.env.READ_ONLY_MODE = 'true'; });

    it('blocks study attempt with READ_ONLY_MODE_ACTIVE', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/new-words')
        .send({ word_id: 'abandon', book_id: 'book-001', study_type: 'new', action_result: 'know' })
        .set('X-Idempotency-Key', 'ro-study-001');
      expectDegradedResponse(res, 'READ_ONLY_MODE_ACTIVE');
      expect(res.body.error.details.read_only).toBe(true);
    });

    it('blocks purchase', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/shop/purchases')
        .send({ item_id: 'cat_hat_red' })
        .set('X-Idempotency-Key', 'ro-purchase-001');
      expectDegradedResponse(res, 'READ_ONLY_MODE_ACTIVE');
    });

    it('health shows read_only status', async () => {
      const res = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
      expect(res.body.status).toBe('read_only');
      expect(res.body.write_blocked).toBe(true);
      expect(res.body.degraded_state.read_only).toBe(true);
    });
  });

  // ========== TEMPORARILY_UNAVAILABLE ==========

  describe('TEMPORARILY_UNAVAILABLE=true', () => {
    beforeEach(() => { process.env.TEMPORARILY_UNAVAILABLE = 'true'; });

    it('blocks feed with TEMPORARILY_UNAVAILABLE', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/me/feed')
        .send({ feed_item_type: 'fish_treat' })
        .set('X-Idempotency-Key', 'tu-feed-001');
      expectDegradedResponse(res, 'TEMPORARILY_UNAVAILABLE');
      expect(res.body.error.details.temporarily_unavailable).toBe(true);
    });

    it('blocks session finish', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/sessions/fake-session/finish')
        .set('X-Idempotency-Key', 'tu-session-001');
      expectDegradedResponse(res, 'TEMPORARILY_UNAVAILABLE');
    });

    it('blocks check-in', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/check-ins')
        .set('X-Idempotency-Key', 'tu-checkin-001');
      expectDegradedResponse(res, 'TEMPORARILY_UNAVAILABLE');
    });

    it('health shows temporarily_unavailable status', async () => {
      const res = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
      expect(res.body.status).toBe('temporarily_unavailable');
      expect(res.body.write_blocked).toBe(true);
      expect(res.body.degraded_state.temporarily_unavailable).toBe(true);
    });
  });

  // ========== Normal mode (no degraded state) ==========

  describe('Normal mode (no flags set)', () => {
    it('writes are allowed normally', async () => {
      const res = await request(app.getHttpServer())
        .post('/api/v1/check-ins')
        .set('X-Idempotency-Key', 'normal-checkin-001')
        .expect(200);

      expect(res.body.check_in.check_in_status).toBe('succeeded');
    });

    it('health shows ok status', async () => {
      const res = await request(app.getHttpServer()).get('/api/v1/health').expect(200);
      expect(res.body.status).toBe('ok');
      expect(res.body.write_blocked).toBe(false);
    });
  });
});
