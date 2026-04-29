/**
 * Export ZK (中考) and GK (高考) vocabulary from docs/get_examples/
 * to apps/mobile/assets/words/{slug}.json for offline bundling.
 *
 * Usage:
 *   cd apps/api
 *   npx ts-node scripts/export-wordbook-json.ts
 *
 * Inputs (per book):
 *   docs/get_examples/{slug}.csv             -- word list (CSV, same fields as cet4.csv)
 *   docs/get_examples/generated_examples_{slug}.json  -- AI-generated example sentences
 *
 * Output (per book):
 *   apps/mobile/assets/words/{slug}.json
 *
 * Word ID = wordText.toLowerCase().trim()  (canonical across all books,
 * so "ability" shared between ZK and GK resolves to the same row in word_entries).
 *
 * CSV fields: word, phonetic, definition, translation, pos, collins, oxford,
 *             tag, bnc, frq, exchange
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

// ── Meaning extraction: first Chinese phrase from verbose translation ──

function extractMeaning(translation: string): string {
  if (!translation) return '';
  // Split on literal \n escape sequence (CSV encodes newlines as \n text)
  // or on actual newline characters.
  const firstLine = translation.split(/\\n|\n/)[0].trim();
  const stripped = firstLine
    .replace(/\\r/g, '')        // strip literal \r escape sequences
    .replace(/^\[[^\]]+\]\s*/, '')
    .replace(/^[a-zA-Z]+\.\s+/, '');
  const first = stripped.split(/[，,]/)[0].trim();
  return first || stripped || translation;
}

// ── Process one book ──

/// Increment this when the content schema or generation logic changes.
/// WordbookLoader compares this against the stored value in preset_wordbooks
/// and re-imports if they differ.
const CONTENT_VERSION = '2';

interface WordEntry {
  wordId: string;
  wordText: string;
  meaning: string;
  phonetic: string | null;
  translation: string | null;
  definition: string | null;
  frequencyRank: number;
  wordForms: string | null;
  sortOrder: number;
  sourceKey: string;  // traceable: "{bookSlug}-{csvRowIndex}"
  examples: ExampleEntry[];
}

interface ExampleEntry {
  sense: string;
  en: string;
  cn: string;
  sortOrder: number;
}

interface BookConfig {
  slug: string;
  displayName: string;
  csvFile: string;
  examplesFile: string;
}

const BOOKS: BookConfig[] = [
  {
    slug: 'zk',
    displayName: '中考',
    csvFile: 'zk.csv',
    examplesFile: 'generated_examples_zk.json',
  },
  {
    slug: 'gk',
    displayName: '高考',
    csvFile: 'gk.csv',
    examplesFile: 'generated_examples_gk.json',
  },
];

const docsDir = path.resolve(__dirname, '../../../docs/get_examples');
const outDir  = path.resolve(__dirname, '../../mobile/assets/words');

if (!fs.existsSync(outDir)) {
  fs.mkdirSync(outDir, { recursive: true });
}

for (const book of BOOKS) {
  console.log(`\n📚 Processing ${book.displayName} (${book.slug})...`);

  // ── Load examples JSON ──
  const examplesPath = path.join(docsDir, book.examplesFile);
  const examplesMap = new Map<string, ExampleEntry[]>();

  if (fs.existsSync(examplesPath)) {
    let exRaw = fs.readFileSync(examplesPath, 'utf-8');
    if (exRaw.charCodeAt(0) === 0xfeff) exRaw = exRaw.slice(1);
    const exData = JSON.parse(exRaw) as { items: any[] };
    const items = exData.items ?? [];
    for (const item of items) {
      const wordKey = (item.word as string).toLowerCase().trim();
      const examples: ExampleEntry[] = (item.examples ?? []).map((ex: any, idx: number) => ({
        sense: (ex.sense as string) ?? '',
        // Prefer en_plain (no brackets) if present, else keep bracketed form
        en: (ex.en as string) ?? '',
        cn: (ex.cn as string) ?? '',
        sortOrder: idx,
      }));
      examplesMap.set(wordKey, examples);
    }
    console.log(`  ✓ Loaded examples for ${examplesMap.size} words`);
  } else {
    console.warn(`  ⚠ Examples file not found: ${examplesPath}`);
  }

  // ── Parse CSV ──
  const csvPath = path.join(docsDir, book.csvFile);
  if (!fs.existsSync(csvPath)) {
    console.error(`  ❌ CSV not found: ${csvPath}`);
    continue;
  }

  let raw = fs.readFileSync(csvPath, 'utf-8');
  if (raw.charCodeAt(0) === 0xfeff) raw = raw.slice(1);

  // Normalise CRLF → LF before splitting
  raw = raw.replace(/\r\n/g, '\n').replace(/\r/g, '\n');
  const lines = raw.split('\n').filter(l => l.trim().length > 0);
  console.log(`  ✓ Parsing ${lines.length - 1} CSV rows...`);

  const words: WordEntry[] = [];

  for (let i = 1; i < lines.length; i++) {
    const fields = parseCSVLine(lines[i]);
    if (fields.length < 4) continue;

    const wordText   = fields[0].trim();
    const phonetic   = fields[1].trim();
    const definition = fields[2].trim();   // English definition
    const translation= fields[3].trim();   // Chinese translation (multi-POS)
    // fields[4] = pos, fields[5] = collins, fields[6] = oxford
    // fields[7] = tag, fields[8] = bnc, fields[9] = frq, fields[10] = exchange
    const bnc        = parseInt(fields[8] ?? '0', 10) || 0;
    const frq        = parseInt(fields[9] ?? '0', 10) || 0;
    const exchange   = (fields[10] ?? '').trim();

    if (!wordText) continue;

    // Canonical word ID: lowercase, spaces → hyphens
    const wordId = wordText.toLowerCase().replace(/\s+/g, '-').trim();
    const meaning = extractMeaning(translation) || wordText;
    const frequencyRank = bnc > 0 ? bnc : (frq > 0 ? frq : 99999);
    // Traceable source key: "{bookSlug}-{csvRowIndex}" (1-based)
    const sourceKey = `${book.slug}-${i}`;

    const examples = examplesMap.get(wordId) ?? examplesMap.get(wordText.toLowerCase()) ?? [];

    words.push({
      wordId,
      wordText,
      meaning,
      phonetic: phonetic || null,
      translation: translation || null,
      definition: definition || null,
      frequencyRank,
      wordForms: exchange || null,
      sortOrder: i, // 1-based CSV row order
      sourceKey,
      examples,
    });
  }

  // ── Write output ──
  const output = {
    bookSlug: book.slug,
    displayName: book.displayName,
    schemaVersion: '4',
    contentVersion: CONTENT_VERSION,
    totalWords: words.length,
    generatedAt: new Date().toISOString(),
    words,
  };

  const outPath = path.join(outDir, `${book.slug}.json`);
  fs.writeFileSync(outPath, JSON.stringify(output), 'utf-8');

  const withExamples = words.filter(w => w.examples.length > 0).length;
  console.log(`  ✅ Exported ${words.length} words → ${outPath}`);
  console.log(`     (${withExamples} words have examples)`);

  // Sanity check: first 2 entries
  console.log('  Sample (first 2 words):');
  words.slice(0, 2).forEach(w =>
    console.log(`    ${w.wordId}: "${w.meaning}" [${w.phonetic ?? ''}] — ${w.examples.length} examples`)
  );
}

console.log('\n✅ Done.');
