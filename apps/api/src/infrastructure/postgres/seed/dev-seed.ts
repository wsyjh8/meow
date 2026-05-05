/**
 * Dev seed script (Option A A2).
 *
 * Seeds the database with minimal dev data matching current DevStore static data.
 * Idempotent: uses ON CONFLICT DO NOTHING for all inserts.
 *
 * v0.3.0 P1: words now use canonical ids (lowercase normalized form, no
 * 'cet4-' prefix). Book membership lives in the new word_book_memberships
 * table. The "review seed" concept moves out of fake word_ids ('word-r-*')
 * and into DevStore.REVIEW_SEED_WORD_IDS (a static set of canonical ids).
 */

import * as fs from 'fs';
import * as path from 'path';
import { getPool, closePool } from '../client';
import { normalizeWord } from '../../../lib/stable-id';

const DEV_USER_ID = 'dev-user-001';
const DEV_BOOK_ID = 'book-001';
const DEV_BOOK_NAME = 'CET-4';

/**
 * 30 dev fixture words. v0.3.0 dedupes — 'abandon' was previously listed
 * twice (once as new, once as review). Now appears once; review-eligible
 * status is tracked separately via DevStore.REVIEW_SEED_WORD_IDS, not by
 * synthesizing fake 'word-r-*' ids.
 */
const DEV_WORDS: Array<{ text: string; meaning: string; phonetic: string }> = [
  // Originally "new" 20
  { text: 'abandon', meaning: '放弃', phonetic: '/əˈbændən/' },
  { text: 'ability', meaning: '能力', phonetic: '/əˈbɪləti/' },
  { text: 'abnormal', meaning: '异常的', phonetic: '/æbˈnɔːrml/' },
  { text: 'aboard', meaning: '在船上', phonetic: '/əˈbɔːrd/' },
  { text: 'abrupt', meaning: '突然的', phonetic: '/əˈbrʌpt/' },
  { text: 'absence', meaning: '缺席', phonetic: '/ˈæbsəns/' },
  { text: 'absolute', meaning: '绝对的', phonetic: '/ˈæbsəluːt/' },
  { text: 'absorb', meaning: '吸收', phonetic: '/əbˈzɔːrb/' },
  { text: 'abstract', meaning: '抽象的', phonetic: '/ˈæbstrækt/' },
  { text: 'abundant', meaning: '丰富的', phonetic: '/əˈbʌndənt/' },
  { text: 'academic', meaning: '学术的', phonetic: '/ˌækəˈdemɪk/' },
  { text: 'accelerate', meaning: '加速', phonetic: '/əkˈseləreɪt/' },
  { text: 'access', meaning: '进入', phonetic: '/ˈækses/' },
  { text: 'accommodate', meaning: '容纳', phonetic: '/əˈkɒmədeɪt/' },
  { text: 'accompany', meaning: '陪伴', phonetic: '/əˈkʌmpəni/' },
  { text: 'accomplish', meaning: '完成', phonetic: '/əˈkʌmplɪʃ/' },
  { text: 'account', meaning: '账户', phonetic: '/əˈkaʊnt/' },
  { text: 'accumulate', meaning: '积累', phonetic: '/əˈkjuːmjəleɪt/' },
  { text: 'accurate', meaning: '准确的', phonetic: '/ˈækjərət/' },
  { text: 'achieve', meaning: '实现', phonetic: '/əˈtʃiːv/' },
  // Originally "review" — these are canonical too. The fact that they're
  // review-seed words is encoded in DevStore.REVIEW_SEED_WORD_IDS.
  { text: 'background', meaning: '背景', phonetic: '/ˈbækɡraʊnd/' },
  { text: 'bacteria', meaning: '细菌', phonetic: '/bækˈtɪriə/' },
  { text: 'balance', meaning: '平衡', phonetic: '/ˈbæləns/' },
  { text: 'banner', meaning: '横幅', phonetic: '/ˈbænər/' },
  { text: 'barrier', meaning: '障碍', phonetic: '/ˈbæriər/' },
  { text: 'behavior', meaning: '行为', phonetic: '/bɪˈheɪvjər/' },
  { text: 'benefit', meaning: '利益', phonetic: '/ˈbenɪfɪt/' },
  { text: 'biology', meaning: '生物学', phonetic: '/baɪˈɒlədʒi/' },
  { text: 'boundary', meaning: '边界', phonetic: '/ˈbaʊndri/' },
];

async function seed() {
  const pool = getPool();

  console.log('[seed] Starting dev seed (v0.3.0 P1, canonical word_ids)...');

  // 1. Dev user
  await pool.query(`
    INSERT INTO users (id, nickname, timezone, locale)
    VALUES ($1, 'Learner', 'UTC', 'zh-CN')
    ON CONFLICT (id) DO NOTHING
  `, [DEV_USER_ID]);
  console.log('[seed] User seeded.');

  // 2. Word book
  await pool.query(`
    INSERT INTO word_books (id, name, description, word_count, is_active)
    VALUES ($1, $2, 'CET-4 word book for development', $3, TRUE)
    ON CONFLICT (id) DO NOTHING
  `, [DEV_BOOK_ID, DEV_BOOK_NAME, DEV_WORDS.length]);
  console.log('[seed] Word book seeded.');

  // 3. User book settings
  await pool.query(`
    INSERT INTO user_book_settings (user_id, book_id, daily_new_target, is_active)
    VALUES ($1, $2, 20, TRUE)
    ON CONFLICT (user_id, book_id) DO NOTHING
  `, [DEV_USER_ID, DEV_BOOK_ID]);
  console.log('[seed] User book settings seeded.');

  // 4. Words (canonical id = normalize_word(text)) + word_book_memberships
  for (let i = 0; i < DEV_WORDS.length; i++) {
    const w = DEV_WORDS[i];
    const wordId = normalizeWord(w.text);
    await pool.query(`
      INSERT INTO words (id, word_text, meaning, phonetic)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (id) DO NOTHING
    `, [wordId, w.text, w.meaning, w.phonetic]);
    await pool.query(`
      INSERT INTO word_book_memberships (word_id, book_id, sort_order, source_key)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (word_id, book_id) DO NOTHING
    `, [wordId, DEV_BOOK_ID, i + 1, `dev-${i + 1}`]);
  }
  console.log(`[seed] ${DEV_WORDS.length} words + memberships seeded.`);

  // 5. Shop catalog items (matching DevStore catalog exactly)
  const catalogItems = [
    // Original 5
    { id: 'cat_hat_red', type: 'outfit', slot: 'head', name: '红色小帽子', price: 60, level: 1 },
    { id: 'cat_bow_blue', type: 'outfit', slot: 'neck', name: '蓝色蝴蝶结', price: 80, level: 2 },
    { id: 'cat_scarf_pink', type: 'outfit', slot: 'neck', name: '粉色围巾', price: 100, level: 3 },
    { id: 'room_lamp_warm', type: 'room_item', slot: 'decor', name: '暖光小台灯', price: 120, level: 3 },
    { id: 'room_rug_soft', type: 'room_item', slot: 'floor', name: '柔软小地毯', price: 150, level: 4 },
    // B2-2A: New 5
    { id: 'cat_hat_straw', type: 'outfit', slot: 'head', name: '草编小草帽', price: 90, level: 2 },
    { id: 'cat_bow_yellow', type: 'outfit', slot: 'neck', name: '向日葵领结', price: 110, level: 3 },
    { id: 'cat_scarf_stripe', type: 'outfit', slot: 'neck', name: '条纹暖围巾', price: 130, level: 4 },
    { id: 'room_plant_small', type: 'room_item', slot: 'decor', name: '小盆栽绿植', price: 100, level: 2 },
    { id: 'room_cushion_cloud', type: 'room_item', slot: 'floor', name: '云朵小靠垫', price: 140, level: 3 },
  ];

  for (const item of catalogItems) {
    await pool.query(`
      INSERT INTO shop_catalog_items (id, item_type, slot, name, coin_price, required_level, is_active)
      VALUES ($1, $2, $3, $4, $5, $6, TRUE)
      ON CONFLICT (id) DO NOTHING
    `, [item.id, item.type, item.slot, item.name, item.price, item.level]);
  }
  console.log(`[seed] ${catalogItems.length} catalog items seeded.`);

  // 6. Pet profile for dev user
  await pool.query(`
    INSERT INTO pet_profiles (user_id, nickname, base_mood, base_bond)
    VALUES ($1, 'Mimi', 60, 0)
    ON CONFLICT (user_id) DO NOTHING
  `, [DEV_USER_ID]);
  console.log('[seed] Pet profile seeded.');

  // 7. Secondary wallet for dev user
  await pool.query(`
    INSERT INTO secondary_wallets (user_id, coins_spent, feed_mood_accumulated, feed_exp_accumulated, feed_bond_accumulated)
    VALUES ($1, 0, 0, 0, 0)
    ON CONFLICT (user_id) DO NOTHING
  `, [DEV_USER_ID]);
  console.log('[seed] Secondary wallet seeded.');

  // 8. Streak record for dev user
  await pool.query(`
    INSERT INTO streak_records (user_id, current_streak, streak_basis_type)
    VALUES ($1, 0, 'check_in')
    ON CONFLICT (user_id) DO NOTHING
  `, [DEV_USER_ID]);
  console.log('[seed] Streak record seeded.');

  console.log('[seed] Dev seed complete.');
}

// CLI entry point
if (require.main === module) {
  const envPath = path.resolve(__dirname, '..', '..', '..', '..', '.env');
  if (fs.existsSync(envPath)) {
    const envContent = fs.readFileSync(envPath, 'utf-8');
    for (const line of envContent.split('\n')) {
      const trimmed = line.trim();
      if (trimmed && !trimmed.startsWith('#')) {
        const eqIdx = trimmed.indexOf('=');
        if (eqIdx > 0) {
          const key = trimmed.substring(0, eqIdx);
          const value = trimmed.substring(eqIdx + 1);
          if (!process.env[key]) {
            process.env[key] = value;
          }
        }
      }
    }
  }

  seed()
    .then(() => process.exit(0))
    .catch(err => {
      console.error('[seed] Failed:', err);
      process.exit(1);
    })
    .finally(() => closePool());
}

export { seed };
