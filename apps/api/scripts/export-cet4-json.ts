/**
 * Export CET-4 vocabulary from docs/db/cet4.csv to
 * apps/mobile/assets/words/book-001.json for offline bundling.
 *
 * Usage:
 *   cd apps/api
 *   npx ts-node scripts/export-cet4-json.ts
 *
 * Output format (one entry):
 *   {
 *     "wordId": "cet4-abandon",
 *     "wordText": "abandon",
 *     "meaning": "放弃",
 *     "phonetic": "/əˈbændən/",
 *     "translation": "vt. 放弃, 抛弃...",
 *     "frequencyRank": 2057,
 *     "sortOrder": 1
 *   }
 */
import * as fs from 'fs';
import * as path from 'path';

// ── CSV parser (RFC 4180, handles quoted fields with embedded commas) ──

function parseCSVLine(line: string): string[] {
  const fields: string[] = [];
  let inQuotes = false;
  let field = '';

  for (let i = 0; i < line.length; i++) {
    const ch = line[i];
    if (ch === '"') {
      if (inQuotes && line[i + 1] === '"') {
        field += '"';
        i++;
      } else {
        inQuotes = !inQuotes;
      }
    } else if (ch === ',' && !inQuotes) {
      fields.push(field);
      field = '';
    } else {
      field += ch;
    }
  }
  fields.push(field);
  return fields;
}

// ── Meaning extraction: take first Chinese phrase from verbose translation ──

function extractMeaning(translation: string): string {
  if (!translation) return '';
  // Split on literal "\n" (the CSV uses \n as escape sequence inside quotes)
  // or on actual newline characters
  const firstLine = translation.split(/\\n|\n/)[0].trim();
  // Remove leading POS prefix: "vt. ", "n. ", "adj. ", "[经] " etc.
  const stripped = firstLine
    .replace(/^\[[^\]]+\]\s*/, '')   // remove [xxx] prefix
    .replace(/^[a-zA-Z]+\.\s+/, ''); // remove "vt. " etc.
  // Take first item before comma (Chinese or English)
  const first = stripped.split(/[，,]/)[0].trim();
  return first || stripped || translation;
}

// ── Main ──

const csvPath  = path.resolve(__dirname, '../../../docs/db/cet4.csv');
const outDir   = path.resolve(__dirname, '../../mobile/assets/words');
const outPath  = path.join(outDir, 'book-001.json');

if (!fs.existsSync(csvPath)) {
  console.error(`❌ CSV not found: ${csvPath}`);
  process.exit(1);
}

// Read + strip BOM
let raw = fs.readFileSync(csvPath, 'utf-8');
if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);

const lines = raw.split('\n').filter(l => l.trim().length > 0);
console.log(`📖 Parsing ${lines.length - 1} rows (excluding header)...`);

const words: object[] = [];

for (let i = 1; i < lines.length; i++) {
  const fields = parseCSVLine(lines[i]);
  if (fields.length < 4) continue;

  const wordText    = fields[0].trim();
  const phonetic    = fields[1].trim();
  // fields[2] = English definition (not used for meaning)
  const translation = fields[3].trim();
  // fields[4] = pos, fields[5] = collins, fields[6] = oxford
  // fields[7] = tag, fields[8] = bnc, fields[9] = frq
  const bnc = parseInt(fields[8] ?? '0', 10) || 0;
  const frq = parseInt(fields[9] ?? '0', 10) || 0;

  if (!wordText) continue;

  // Stable word ID: prefix + lowercase word (spaces → hyphens)
  const wordId = `cet4-${wordText.toLowerCase().replace(/\s+/g, '-')}`;
  const meaning = extractMeaning(translation) || wordText;
  // frequencyRank: prefer BNC (British corpus), fallback to COCA frq
  const frequencyRank = bnc > 0 ? bnc : (frq > 0 ? frq : 99999);

  words.push({
    wordId,
    wordText,
    meaning,
    phonetic: phonetic || null,
    translation: translation || null,
    frequencyRank,
    sortOrder: i, // 1-based, preserving CSV order
  });
}

// Ensure output directory exists
if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

const output = {
  bookId: 'book-001',
  schemaVersion: '1',
  totalWords: words.length,
  generatedAt: new Date().toISOString(),
  words,
};

fs.writeFileSync(outPath, JSON.stringify(output), 'utf-8');
console.log(`✅ Exported ${words.length} words → ${outPath}`);

// Sanity check: print first 3 entries
console.log('\nSample (first 3 words):');
(words as any[]).slice(0, 3).forEach(w =>
  console.log(`  ${w.wordId}: "${w.meaning}" [${w.phonetic ?? ''}]`)
);
