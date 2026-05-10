/**
 * 需求 23 Phase A2 — Auth flow e2e tests
 *
 * Verifies:
 *   - POST /auth/guest is idempotent by device_id
 *   - POST /auth/register / /auth/login round-trip
 *   - POST /auth/bind upgrades guest → registered, preserves users.id
 *   - GET /auth/me with Bearer token
 *   - AUTH_ENFORCE permissive mode falls back when no token
 *
 * Runs against real PG (meow_dev). Each test inserts a uniquely-named user
 * and cleans up at the end of the suite.
 */

import { Test, TestingModule } from '@nestjs/testing';
import { INestApplication } from '@nestjs/common';
import * as request from 'supertest';
import * as fs from 'fs';
import * as path from 'path';

// Load .env so DATABASE_URL / JWT_SECRET are visible to the AppModule import
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

// Force PG and permissive auth (default Phase A behavior)
process.env.PERSISTENCE_BACKEND = 'pg';
process.env.AUTH_ENFORCE = 'false';

import { AppModule } from '../src/app.module';
import { getPool } from '../src/infrastructure/postgres/client';

const hasPg = !!process.env.DATABASE_URL;
const describeIfPg = hasPg ? describe : describe.skip;

// Phase A4-β.2: PG ops slow down once auth-isolation suite runs first
// (more rows in users / settlements / backup tables). Default 5s test
// timeout is too tight for AppModule init + PG round-trips. Bump to 15s
// per-test (was 5s default).
jest.setTimeout(15000);

describeIfPg('/auth/* e2e (PG)', () => {
  let app: INestApplication;
  // Track ids inserted by tests so we can clean up after.
  const createdUserIds: string[] = [];

  beforeAll(async () => {
    const moduleFixture: TestingModule = await Test.createTestingModule({
      imports: [AppModule],
    }).compile();
    app = moduleFixture.createNestApplication();
    app.setGlobalPrefix('api/v1');
    await app.init();
  }, 30000);

  afterAll(async () => {
    if (createdUserIds.length > 0) {
      await getPool().query(
        'DELETE FROM users WHERE id = ANY($1::text[])',
        [createdUserIds],
      );
    }
    await app.close();
  });

  function api(): request.SuperTest<request.Test> {
    return request(app.getHttpServer());
  }

  it('POST /auth/guest creates a guest and is idempotent by device_id', async () => {
    const deviceId = `dev-${Date.now()}-${Math.random().toString(36).slice(2, 10)}`;

    const r1 = await api().post('/api/v1/auth/guest').send({ device_id: deviceId });
    expect(r1.status).toBe(200);
    expect(r1.body.user.id).toMatch(/^guest-/);
    expect(r1.body.user.account_type).toBe('guest');
    expect(r1.body.user.email).toBeNull();
    expect(typeof r1.body.token).toBe('string');
    expect(r1.body.token.split('.').length).toBe(3); // header.payload.signature
    createdUserIds.push(r1.body.user.id);

    const r2 = await api().post('/api/v1/auth/guest').send({ device_id: deviceId });
    expect(r2.status).toBe(200);
    expect(r2.body.user.id).toBe(r1.body.user.id); // idempotent
  });

  it('POST /auth/register creates a registered user; login round-trips', async () => {
    const email = `reg-${Date.now()}@meow.test`;
    const password = 'verysecret12345';

    const reg = await api()
      .post('/api/v1/auth/register')
      .send({ email, password, nickname: 'Tester' });
    expect(reg.status).toBe(200);
    expect(reg.body.user.id).toMatch(/^user-/);
    expect(reg.body.user.email).toBe(email);
    expect(reg.body.user.nickname).toBe('Tester');
    expect(reg.body.user.account_type).toBe('registered');
    createdUserIds.push(reg.body.user.id);

    const login = await api().post('/api/v1/auth/login').send({ email, password });
    expect(login.status).toBe(200);
    expect(login.body.user.id).toBe(reg.body.user.id);
    expect(typeof login.body.token).toBe('string');

    const wrong = await api()
      .post('/api/v1/auth/login')
      .send({ email, password: 'wrong-password' });
    expect(wrong.status).toBe(401);
    expect(wrong.body.message?.error_code ?? wrong.body.error_code).toBe(
      'INVALID_CREDENTIALS',
    );
  });

  it('register with duplicate email returns 409 EMAIL_TAKEN', async () => {
    const email = `dup-${Date.now()}@meow.test`;
    const password = 'verysecret12345';

    const r1 = await api().post('/api/v1/auth/register').send({ email, password });
    expect(r1.status).toBe(200);
    createdUserIds.push(r1.body.user.id);

    // Same email, mixed case
    const r2 = await api()
      .post('/api/v1/auth/register')
      .send({ email: email.toUpperCase(), password });
    expect(r2.status).toBe(409);
    expect(r2.body.message?.error_code ?? r2.body.error_code).toBe('EMAIL_TAKEN');
  });

  it('GET /auth/me returns current user with Bearer token', async () => {
    const deviceId = `dev-me-${Date.now()}`;
    const guest = await api().post('/api/v1/auth/guest').send({ device_id: deviceId });
    const token = guest.body.token as string;
    createdUserIds.push(guest.body.user.id);

    const me = await api()
      .get('/api/v1/auth/me')
      .set('Authorization', `Bearer ${token}`);
    expect(me.status).toBe(200);
    expect(me.body.id).toBe(guest.body.user.id);
    expect(me.body.account_type).toBe('guest');
  });

  it('POST /auth/bind upgrades guest → registered, preserves users.id', async () => {
    const deviceId = `dev-bind-${Date.now()}`;
    const email = `bind-${Date.now()}@meow.test`;
    const password = 'verysecret12345';

    // 1. Start as guest
    const guest = await api().post('/api/v1/auth/guest').send({ device_id: deviceId });
    expect(guest.status).toBe(200);
    const guestId = guest.body.user.id as string;
    const guestToken = guest.body.token as string;
    createdUserIds.push(guestId);

    // 2. Bind to email/password
    const bind = await api()
      .post('/api/v1/auth/bind')
      .set('Authorization', `Bearer ${guestToken}`)
      .send({ email, password });
    expect(bind.status).toBe(200);

    // Critical: id must NOT change (same-row upgrade per plan v2 §6.2).
    expect(bind.body.user.id).toBe(guestId);
    expect(bind.body.user.account_type).toBe('registered');
    expect(bind.body.user.email).toBe(email);

    // 3. Login with new credentials should also yield same id
    const login = await api().post('/api/v1/auth/login').send({ email, password });
    expect(login.status).toBe(200);
    expect(login.body.user.id).toBe(guestId);

    // 4. Trying to bind again on a registered token must fail
    const newToken = bind.body.token as string;
    const bind2 = await api()
      .post('/api/v1/auth/bind')
      .set('Authorization', `Bearer ${newToken}`)
      .send({ email: `other-${Date.now()}@meow.test`, password });
    expect(bind2.status).toBe(400);
    expect(bind2.body.message?.error_code ?? bind2.body.error_code).toBe(
      'NOT_GUEST',
    );
  });

  it('GET /auth/me without token in permissive mode resolves to dev fallback', async () => {
    // AUTH_ENFORCE=false means missing token falls back to DEV_FALLBACK_USER_ID
    const me = await api().get('/api/v1/auth/me');
    expect(me.status).toBe(200);
    // Default fallback id
    expect(me.body.id).toBe(process.env.DEV_FALLBACK_USER_ID || 'dev-user-001');
  });

  it('Invalid Bearer token in permissive mode falls back instead of 401', async () => {
    const me = await api()
      .get('/api/v1/auth/me')
      .set('Authorization', 'Bearer not-a-real-token');
    expect(me.status).toBe(200);
    expect(me.body.id).toBe(process.env.DEV_FALLBACK_USER_ID || 'dev-user-001');
  });
});
