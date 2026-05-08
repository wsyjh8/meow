/**
 * CET-4 CSV Import Script
 *
 * Parses docs/db/cet4.csv and imports ~3849 words into PostgreSQL.
 * Idempotent: uses ON CONFLICT DO UPDATE.
 *
 * Usage:
 *   npx ts-node scripts/import-cet4.ts
 *   npx ts-node scripts/import-cet4.ts --validate  (dry run)
 */

import * as fs from 'fs';
import * as path from 'path';
import { Pool } from 'pg';

const CSV_PATH = path.resolve(__dirname, '..', '..', '..', 'docs', 'db', 'cet4.csv');
const BOOK_ID = 'book-001';
const VALIDATE_ONLY = process.argv.includes('--validate');

// ==================== CSV Parser (RFC 4180 compliant) ====================

function parseCSV(content: string): string[][] {
  const rows: string[][] = [];
  let i = 0;
  const len = content.length;

  while (i < len) {
    const row: string[] = [];
    while (i < len) {
      let field = '';
      if (content[i] === '"') {
        // Quoted field
        i++; // skip opening quote
        while (i < len) {
          if (content[i] === '"') {
            if (i + 1 < len && content[i + 1] === '"') {
              field += '"';
              i += 2;
            } else {
              i++; // skip closing quote
              break;
            }
          } else {
            field += content[i];
            i++;
          }
        }
      } else {
        // Unquoted field
        while (i < len && content[i] !== ',' && content[i] !== '\n' && content[i] !== '\r') {
          field += content[i];
          i++;
        }
      }
      row.push(field);

      if (i < len && content[i] === ',') {
        i++; // skip comma
      } else {
        break; // end of row
      }
    }
    // Skip line endings
    if (i < len && content[i] === '\r') i++;
    if (i < len && content[i] === '\n') i++;

    if (row.length > 1 || (row.length === 1 && row[0].trim() !== '')) {
      rows.push(row);
    }
  }
  return rows;
}

// ==================== Meaning Extraction ====================

/**
 * Extract short Chinese meaning from full translation string.
 * Input: "vt. 放弃, 抛弃, 遗弃\nn. 放任, 无拘束"
 * Output: "放弃"
 */
function extractShortMeaning(translation: string): string {
  if (!translation) return '';
  // Take first line
  const firstLine = translation.split('\\n')[0].split('\n')[0].trim();
  // Strip POS prefix: vt., vi., n., a., ad., prep., conj., int., abbr., pron., etc.
  const stripped = firstLine
    .replace(/^[a-z]+\.\s*/i, '')  // Remove single POS like "vt. "
    .replace(/^\[[^\]]+\]\s*/g, '') // Remove domain markers like "[医] "
    .trim();
  // Take first comma-separated term
  const firstTerm = stripped.split(',')[0].split('，')[0].trim();
  return firstTerm || stripped || firstLine;
}

// ==================== Frequency Rank ====================

function computeFrequency(bnc: string, frq: string): number {
  const b = parseInt(bnc) || 0;
  const f = parseInt(frq) || 0;
  if (b > 0 && f > 0) return Math.min(b, f);
  if (b > 0) return b;
  if (f > 0) return f;
  return 99999;
}

// ==================== Main ====================

async function main() {
  console.log('Reading CSV from:', CSV_PATH);
  // Strip BOM if present
  let raw = fs.readFileSync(CSV_PATH, 'utf-8');
  if (raw.charCodeAt(0) === 0xFEFF) raw = raw.slice(1);
  const rows = parseCSV(raw);

  // Header
  const header = rows[0];
  console.log('Header:', header.join(', '));

  // Map header indices
  const idx = {
    word: header.indexOf('word'),
    phonetic: header.indexOf('phonetic'),
    definition: header.indexOf('definition'),
    translation: header.indexOf('translation'),
    collins: header.indexOf('collins'),
    oxford: header.indexOf('oxford'),
    tag: header.indexOf('tag'),
    bnc: header.indexOf('bnc'),
    frq: header.indexOf('frq'),
    exchange: header.indexOf('exchange'),
  };

  const dataRows = rows.slice(1);
  console.log(`Total data rows: ${dataRows.length}`);

  // Build word records
  const words = dataRows.map((row, i) => {
    const word = row[idx.word]?.trim() || '';
    const phonetic = row[idx.phonetic]?.trim() || '';
    const definition = row[idx.definition]?.trim() || '';
    const translation = row[idx.translation]?.trim() || '';
    const collins = parseInt(row[idx.collins]?.trim()) || 0;
    const oxford = row[idx.oxford]?.trim() === '1';
    const tags = row[idx.tag]?.trim() || '';
    const bnc = row[idx.bnc]?.trim() || '';
    const frq = row[idx.frq]?.trim() || '';
    const exchange = row[idx.exchange]?.trim() || '';

    if (!word) return null;

    return {
      // PR-D: id is the canonical lowercase word (no prefix), matching
      // audio_assets.target_id (target_kind='word') for direct JOIN.
      id: word.toLowerCase(),
      book_id: BOOK_ID,
      word_text: word,
      meaning: extractShortMeaning(translation),
      phonetic: phonetic ? `/${phonetic}/` : null,
      translation,
      definition: definition || null,
      difficulty_level: collins,
      is_core: oxford,
      tags: tags || null,
      frequency_rank: computeFrequency(bnc, frq),
      word_forms: exchange || null,
      // word_type / sort_order moved to word_book_memberships (migration 005)
      sort_order: computeFrequency(bnc, frq),
    };
  }).filter(Boolean);

  console.log(`Valid words: ${words.length}`);

  // Stats
  const collinsDistrib: Record<number, number> = {};
  let coreCount = 0;
  words.forEach((w: any) => {
    collinsDistrib[w.difficulty_level] = (collinsDistrib[w.difficulty_level] || 0) + 1;
    if (w.is_core) coreCount++;
  });
  console.log('Collins distribution:', collinsDistrib);
  console.log('Oxford core words:', coreCount);
  console.log('Sample:', JSON.stringify(words[0], null, 2));

  if (VALIDATE_ONLY) {
    console.log('\n--validate mode: no DB writes.');
    return;
  }

  // Connect to PG
  const pool = new Pool({
    connectionString: process.env.DATABASE_URL || 'postgresql://postgres:jason123@localhost:5432/meow_dev',
  });

  console.log('\nImporting to PostgreSQL...');
  let imported = 0;

  for (const w of words as any[]) {
    // 1. Upsert word into `words` table (post-migration-005 schema).
    await pool.query(`
      INSERT INTO words (id, word_text, meaning, phonetic, translation, definition,
                         difficulty_level, is_core, tags, frequency_rank, word_forms)
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11)
      ON CONFLICT (id) DO UPDATE SET
        word_text = EXCLUDED.word_text,
        meaning = EXCLUDED.meaning,
        phonetic = EXCLUDED.phonetic,
        translation = EXCLUDED.translation,
        definition = EXCLUDED.definition,
        difficulty_level = EXCLUDED.difficulty_level,
        is_core = EXCLUDED.is_core,
        tags = EXCLUDED.tags,
        frequency_rank = EXCLUDED.frequency_rank,
        word_forms = EXCLUDED.word_forms,
        updated_at = NOW()
    `, [
      w.id, w.word_text, w.meaning, w.phonetic, w.translation, w.definition,
      w.difficulty_level, w.is_core, w.tags, w.frequency_rank, w.word_forms,
    ]);

    // 2. Upsert membership into `word_book_memberships` (migration 005).
    await pool.query(`
      INSERT INTO word_book_memberships (word_id, book_id, sort_order, source_key)
      VALUES ($1, $2, $3, $4)
      ON CONFLICT (word_id, book_id) DO UPDATE SET
        sort_order = EXCLUDED.sort_order
    `, [w.id, w.book_id, w.sort_order, 'cet4-csv']);

    imported++;
    if (imported % 500 === 0) console.log(`  ...${imported} words imported`);
  }

  // Update word_books count
  await pool.query(`UPDATE word_books SET word_count = $1 WHERE id = $2`, [imported, BOOK_ID]);

  console.log(`\nDone! Imported ${imported} words.`);
  console.log(`Updated word_books count to ${imported}.`);

  await pool.end();
}

main().catch(err => {
  console.error('Import failed:', err);
  process.exit(1);
});
