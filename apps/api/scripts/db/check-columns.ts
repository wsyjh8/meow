import { Pool } from 'pg';
import * as fs from 'fs';
import * as path from 'path';

const envPath = path.resolve(__dirname, '..', '..', '.env');
if (fs.existsSync(envPath)) {
  for (const line of fs.readFileSync(envPath, 'utf-8').split('\n')) {
    const t = line.trim();
    if (t && !t.startsWith('#')) {
      const eq = t.indexOf('=');
      if (eq > 0) { if (!process.env[t.substring(0, eq)]) process.env[t.substring(0, eq)] = t.substring(eq + 1); }
    }
  }
}

const pool = new Pool({ connectionString: process.env.DATABASE_URL });

(async () => {
  const r = await pool.query(
    "SELECT column_name FROM information_schema.columns WHERE table_name = 'secondary_wallets' ORDER BY ordinal_position",
  );
  console.log('secondary_wallets columns:', r.rows.map((x: any) => x.column_name));

  // Try the delete
  try {
    await pool.query("DELETE FROM secondary_wallets WHERE user_id = 'dev-user-001'");
    console.log('DELETE from secondary_wallets: OK');
  } catch (e: any) {
    console.log('DELETE from secondary_wallets FAILED:', e.message);
  }

  await pool.end();
})();
