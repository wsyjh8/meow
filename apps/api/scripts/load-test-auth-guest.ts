/**
 * 需求 23 Phase E1 PR-E0.4 — /auth/guest load test
 *
 * Plan reference: plan-023-E1-v2 §3.4 / Review 2 P2#7.
 *
 * Purpose
 * -------
 * AUTH_ENFORCE=true cutover (Phase E1) will trigger a burst of
 * /auth/guest calls because every app cold start without a valid
 * token issues a new guest. This script measures the endpoint under
 * that burst before we ever flip the production flag.
 *
 * Defaults target the §3.4 acceptance baseline:
 *   - 1000 RPS for 60 seconds
 *   - concurrency 100
 *   - p95 < 500ms
 *   - error rate < 1%
 *
 * The defaults are tuned for the production-shape soak. For local
 * smoke (verify the script runs at all), override with env vars:
 *
 *   TARGET_RPS=10 DURATION_SECONDS=5 CONCURRENCY=4 \
 *     npm run load:auth-guest
 *
 * Or fully:
 *
 *   BASE_URL=http://localhost:3000 \
 *   TARGET_RPS=1000 \
 *   DURATION_SECONDS=60 \
 *   CONCURRENCY=100 \
 *     npm run load:auth-guest
 *
 * Dependencies
 * ------------
 * Built-in Node `http` only — no autocannon / k6 install required.
 * This keeps `apps/api/scripts/` self-contained for the cutover
 * playbook (one less thing for the on-call operator to provision).
 *
 * Output
 * ------
 * Prints a per-10s progress line during the run, then a final
 * summary block including p50 / p95 / p99 / max latency, achieved
 * RPS, error counts, and a verdict against the baseline thresholds.
 * Exit code 0 = baseline met, 1 = baseline broken.
 *
 * What this script does NOT do
 * ---------------------------
 * - It does not exercise the JWT verification path — that's covered
 *   by `auth.e2e-spec.ts`. We're measuring user-insert throughput.
 * - It does not test rate-limit middleware. None is configured yet;
 *   plan §3.4 leaves rate-limit as fallback only if the baseline
 *   fails.
 * - It does not target staging or production from your laptop. Run
 *   it from the same network / VPC as the API so network latency
 *   doesn't dominate the measurement.
 */

import { URL } from 'url';
import * as http from 'http';
import * as https from 'https';

interface Config {
  baseUrl: string;
  targetRps: number;
  durationSeconds: number;
  concurrency: number;
}

interface SampleResult {
  latencyMs: number;
  status: number;
  error: string | null;
}

function readConfig(): Config {
  return {
    baseUrl: process.env.BASE_URL ?? 'http://localhost:3000',
    targetRps: Number(process.env.TARGET_RPS ?? 1000),
    durationSeconds: Number(process.env.DURATION_SECONDS ?? 60),
    concurrency: Number(process.env.CONCURRENCY ?? 100),
  };
}

/** Random device_id that satisfies GuestDto's `/^[A-Za-z0-9_-]+$/` regex. */
function randomDeviceId(workerId: number, seq: number): string {
  const r = Math.floor(Math.random() * 1_000_000_000);
  return `load-w${workerId}-${Date.now()}-${seq}-${r}`;
}

function pickLib(parsed: URL): typeof http | typeof https {
  return parsed.protocol === 'https:' ? https : http;
}

/** One /auth/guest POST. Resolves with timing + status; never throws. */
function postGuest(baseUrl: string, deviceId: string): Promise<SampleResult> {
  return new Promise((resolve) => {
    const start = process.hrtime.bigint();
    let url: URL;
    try {
      url = new URL('/api/v1/auth/guest', baseUrl);
    } catch (e: any) {
      resolve({
        latencyMs: 0,
        status: 0,
        error: `bad-url: ${e?.message ?? e}`,
      });
      return;
    }

    const body = JSON.stringify({ device_id: deviceId });
    const lib = pickLib(url);

    const req = lib.request(
      {
        method: 'POST',
        hostname: url.hostname,
        port: url.port || (url.protocol === 'https:' ? 443 : 80),
        path: url.pathname,
        headers: {
          'Content-Type': 'application/json',
          'Content-Length': Buffer.byteLength(body),
        },
      },
      (res) => {
        // Drain the body — leaving it un-consumed leaks the socket
        // pool when we're issuing thousands of requests.
        res.on('data', () => {});
        res.on('end', () => {
          const latencyMs =
            Number(process.hrtime.bigint() - start) / 1_000_000;
          resolve({ latencyMs, status: res.statusCode ?? 0, error: null });
        });
      },
    );
    req.on('error', (e) => {
      const latencyMs = Number(process.hrtime.bigint() - start) / 1_000_000;
      resolve({ latencyMs, status: 0, error: e.message });
    });
    req.setTimeout(10_000, () => {
      req.destroy(new Error('client-timeout'));
    });
    req.write(body);
    req.end();
  });
}

function percentile(sorted: number[], p: number): number {
  if (sorted.length === 0) return 0;
  const idx = Math.min(sorted.length - 1, Math.floor((sorted.length * p) / 100));
  return sorted[idx];
}

async function runWorker(
  workerId: number,
  cfg: Config,
  stopAt: number,
  budgetPerSecond: number,
  samples: SampleResult[],
): Promise<void> {
  let seq = 0;
  let nextTickAt = Date.now();
  while (Date.now() < stopAt) {
    nextTickAt += 1000;
    const batchStart = Date.now();
    const batch: Promise<SampleResult>[] = [];
    for (let i = 0; i < budgetPerSecond && Date.now() < stopAt; i++) {
      batch.push(postGuest(cfg.baseUrl, randomDeviceId(workerId, seq++)));
    }
    const results = await Promise.all(batch);
    samples.push(...results);
    const elapsed = Date.now() - batchStart;
    const sleep = nextTickAt - Date.now();
    if (sleep > 0 && Date.now() < stopAt) {
      await new Promise((r) => setTimeout(r, sleep));
    } else if (elapsed > 1500) {
      // Loop is slipping — log so the operator knows we're not
      // actually hitting target RPS.
      console.warn(
        `[load-test] worker ${workerId} slipped: batch=${elapsed}ms ` +
          `(target=1000ms)`,
      );
    }
  }
}

async function main(): Promise<number> {
  const cfg = readConfig();
  console.log('[load-test] /auth/guest config:', cfg);

  // Sanity check: a tiny prime call so we fail fast if BASE_URL is wrong.
  const probe = await postGuest(cfg.baseUrl, `probe-${Date.now()}`);
  if (probe.status === 0) {
    console.error(
      `[load-test] probe failed (${probe.error}). Is the API running at ${cfg.baseUrl}? Aborting.`,
    );
    return 2;
  }
  if (probe.status !== 200) {
    console.error(
      `[load-test] probe returned status ${probe.status}; expected 200. Aborting.`,
    );
    return 2;
  }
  console.log(`[load-test] probe ok (status=200, latency=${probe.latencyMs.toFixed(1)}ms). starting workload…`);

  const samples: SampleResult[] = [];
  const stopAt = Date.now() + cfg.durationSeconds * 1000;
  const perWorkerRps = Math.max(
    1,
    Math.floor(cfg.targetRps / cfg.concurrency),
  );

  // Periodic progress log: prints achieved RPS every 10s.
  const tickEvery = 10;
  let lastSampleCount = 0;
  let lastTickAt = Date.now();
  const tickInterval = setInterval(() => {
    const now = Date.now();
    const delta = samples.length - lastSampleCount;
    const seconds = (now - lastTickAt) / 1000;
    const rps = seconds > 0 ? delta / seconds : 0;
    const elapsedTotal = ((now - (stopAt - cfg.durationSeconds * 1000)) / 1000)
      .toFixed(0);
    console.log(
      `[load-test] t=${elapsedTotal}s: ${delta} samples / last ${seconds.toFixed(1)}s = ${rps.toFixed(0)} RPS (total samples=${samples.length})`,
    );
    lastSampleCount = samples.length;
    lastTickAt = now;
  }, tickEvery * 1000);

  await Promise.all(
    Array.from({ length: cfg.concurrency }, (_, i) =>
      runWorker(i, cfg, stopAt, perWorkerRps, samples),
    ),
  );

  clearInterval(tickInterval);

  // Summarise.
  const latencies = samples
    .filter((s) => s.status === 200)
    .map((s) => s.latencyMs)
    .sort((a, b) => a - b);
  const errorCount = samples.length - latencies.length;
  const totalElapsedSec = cfg.durationSeconds;
  const achievedRps = samples.length / totalElapsedSec;
  const p50 = percentile(latencies, 50);
  const p95 = percentile(latencies, 95);
  const p99 = percentile(latencies, 99);
  const max = latencies.length ? latencies[latencies.length - 1] : 0;
  const errorRate = samples.length ? errorCount / samples.length : 0;

  const baselineP95Ms = 500;
  const baselineErrorRate = 0.01;

  const passed =
    p95 < baselineP95Ms &&
    errorRate < baselineErrorRate &&
    achievedRps >= cfg.targetRps * 0.9;

  console.log('\n========== /auth/guest load test summary ==========');
  console.log(`samples       : ${samples.length}`);
  console.log(`200 responses : ${latencies.length}`);
  console.log(`errors        : ${errorCount} (${(errorRate * 100).toFixed(2)}%)`);
  console.log(`achieved RPS  : ${achievedRps.toFixed(0)} (target ${cfg.targetRps})`);
  console.log(`latency p50   : ${p50.toFixed(1)} ms`);
  console.log(`latency p95   : ${p95.toFixed(1)} ms  (baseline < ${baselineP95Ms} ms)`);
  console.log(`latency p99   : ${p99.toFixed(1)} ms`);
  console.log(`latency max   : ${max.toFixed(1)} ms`);
  console.log(`verdict       : ${passed ? '✓ baseline met' : '✗ BASELINE BROKEN'}`);
  console.log('====================================================\n');

  if (!passed) {
    console.error(
      '[load-test] Plan §3.4 fallback: consider rate-limit middleware ' +
        '(e.g. same-IP 100 req/min) or PG vertical scale before flipping ' +
        'AUTH_ENFORCE=true.',
    );
  }

  return passed ? 0 : 1;
}

// Run.
main()
  .then((code) => process.exit(code))
  .catch((err) => {
    console.error('[load-test] fatal:', err);
    process.exit(2);
  });
