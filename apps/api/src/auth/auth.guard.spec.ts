/**
 * 需求 23 Phase E1 PR-E0.3 (plan-023-E1-v2 §3.3, Review 2 P1#3).
 *
 * `assertProductionAuthEnforce` is the production-startup hard guard
 * for the AUTH_ENFORCE flag — defined in `auth.guard.ts:92`, invoked
 * from `main.ts:12` during bootstrap. Pre-E0.3 the function had zero
 * direct test coverage: a typo / inversion / missing call could have
 * shipped to production unnoticed because staging runs with
 * `NODE_ENV != 'production'`, where the assertion is a permanent no-op.
 *
 * The 4 cases below pin the truth table exactly:
 *
 *   NODE_ENV       AUTH_ENFORCE   expected
 *   ─────────────────────────────────────────
 *   production     true           no throw
 *   production     false          throw
 *   development    true           no throw
 *   development    false          no throw   ← permissive dev mode
 *
 * `beforeEach` / `afterEach` snapshot + restore the two env vars so the
 * unit tests don't leak into anything else jest loads in the same
 * process (other spec files, the e2e bootstrapper, etc.).
 */

import { assertProductionAuthEnforce } from './auth.guard';

describe('assertProductionAuthEnforce (Phase E1 PR-E0.3)', () => {
  let originalNodeEnv: string | undefined;
  let originalAuthEnforce: string | undefined;

  beforeEach(() => {
    originalNodeEnv = process.env.NODE_ENV;
    originalAuthEnforce = process.env.AUTH_ENFORCE;
  });

  afterEach(() => {
    // Restore each var to its pre-test value, preserving the
    // "was-unset" distinction (delete vs assign empty string).
    if (originalNodeEnv === undefined) {
      delete process.env.NODE_ENV;
    } else {
      process.env.NODE_ENV = originalNodeEnv;
    }
    if (originalAuthEnforce === undefined) {
      delete process.env.AUTH_ENFORCE;
    } else {
      process.env.AUTH_ENFORCE = originalAuthEnforce;
    }
  });

  it('production + AUTH_ENFORCE=true → no throw', () => {
    process.env.NODE_ENV = 'production';
    process.env.AUTH_ENFORCE = 'true';
    expect(() => assertProductionAuthEnforce()).not.toThrow();
  });

  it('production + AUTH_ENFORCE=false → throw (the only blocking case)', () => {
    process.env.NODE_ENV = 'production';
    process.env.AUTH_ENFORCE = 'false';
    expect(() => assertProductionAuthEnforce()).toThrow(
      /AUTH_ENFORCE/,
    );
  });

  it('development + AUTH_ENFORCE=true → no throw', () => {
    process.env.NODE_ENV = 'development';
    process.env.AUTH_ENFORCE = 'true';
    expect(() => assertProductionAuthEnforce()).not.toThrow();
  });

  it('development + AUTH_ENFORCE=false → no throw (permissive dev)', () => {
    process.env.NODE_ENV = 'development';
    process.env.AUTH_ENFORCE = 'false';
    expect(() => assertProductionAuthEnforce()).not.toThrow();
  });
});
