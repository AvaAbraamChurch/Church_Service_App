/**
 * CSV Hymns Uploader for Church App
 * Uploads hymns from a CSV file to Firestore database
 *
 * CSV Columns (in order):
 *   title, arabicTitle, copticTitle, copticArlyrics, arabicLyrics,
 *   copticLyrics, audioUrl, videoUrl, occasion, userClasses, order
 *
 * Notes:
 *   - userClasses column should be a comma-separated list inside quotes, e.g.: "Servant,Members,Visitors"
 *     OR a JSON array string, e.g.: ["Servant","Members"]
 *   - Multiline text in cells must be wrapped in double quotes in the CSV
 *   - Empty audioUrl / videoUrl values will be stored as null
 *
 * Setup Instructions:
 *   1. npm install firebase-admin csv-parse   (run inside functions/ folder)
 *   2. Place your CSV file in the same directory and name it hymns.csv
 *      (or pass a custom path as the first argument: node upload_hymns_csv.js path/to/file.csv)
 *   3. Place serviceAccountKey.json in this folder or in ../Bulk_email_generator/
 *   4. Run: node upload_hymns_csv.js
 */

const admin = require('firebase-admin');
const path  = require('path');
const fs    = require('fs');
const { parse } = require('csv-parse/sync');

// ─── Firebase Init ────────────────────────────────────────────────────────────
(function initFirebase() {
  let serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

  if (!fs.existsSync(serviceAccountPath)) {
    serviceAccountPath = path.join(
      __dirname, '..', 'Bulk_email_generator', 'serviceAccountKey.json'
    );
  }

  if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ serviceAccountKey.json not found!');
    console.error('Place it in one of:');
    console.error('  • ' + path.join(__dirname, 'serviceAccountKey.json'));
    console.error('  • ' + path.join(__dirname, '..', 'Bulk_email_generator', 'serviceAccountKey.json'));
    console.error('\nDownload from: Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
  }

  const serviceAccount = require(serviceAccountPath);
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: serviceAccount.project_id,
  });

  console.log(`✓ Firebase Admin initialized  (project: ${serviceAccount.project_id})\n`);
})();

const db = admin.firestore();

// ─── Helpers ──────────────────────────────────────────────────────────────────

/**
 * Parse the userClasses cell.
 * Accepted formats:
 *   "Servant,Members,Visitors"          → ['Servant','Members','Visitors']
 *   ["Servant","Members"]               → ['Servant','Members']
 *   Servant                             → ['Servant']
 */
function parseUserClasses(raw) {
  if (!raw || raw.trim() === '') return [];

  const trimmed = raw.trim();

  // JSON array  e.g.  ["Servant","Members"]
  if (trimmed.startsWith('[')) {
    try {
      const parsed = JSON.parse(trimmed);
      if (Array.isArray(parsed)) return parsed.map(s => String(s).trim()).filter(Boolean);
    } catch (_) { /* fall through */ }
  }

  // Comma-separated string  e.g.  Servant,Members,Visitors
  return trimmed.split(',').map(s => s.trim()).filter(Boolean);
}

/** Convert an empty / "null" / "undefined" string to actual null */
function nullIfEmpty(val) {
  if (!val) return null;
  const t = val.trim().toLowerCase();
  if (t === '' || t === 'null' || t === 'undefined' || t === 'n/a') return null;
  return val.trim();
}

/** Parse order as integer, defaulting to 0 */
function parseOrder(val) {
  const n = parseInt(val, 10);
  return isNaN(n) ? 0 : n;
}

// ─── Main ─────────────────────────────────────────────────────────────────────

async function uploadHymnsFromCSV() {
  console.log('=== CSV Hymns Uploader ===\n');

  // Resolve CSV file path
  const csvArg = process.argv[2];
  const csvPath = csvArg
    ? path.resolve(csvArg)
    : path.join(__dirname, 'hymns.csv');

  if (!fs.existsSync(csvPath)) {
    console.error(`❌ CSV file not found: ${csvPath}`);
    console.error('Usage:  node upload_hymns_csv.js [path/to/hymns.csv]');
    console.error('Default location: ' + path.join(__dirname, 'hymns.csv'));
    process.exit(1);
  }

  console.log(`📄 Reading CSV: ${csvPath}\n`);

  // Read & parse CSV
  const fileContent = fs.readFileSync(csvPath, 'utf8');

  let records;
  try {
    records = parse(fileContent, {
      columns: true,          // first row = headers
      skip_empty_lines: true,
      trim: true,
      relax_quotes: true,
      relax_column_count: true,
      bom: true,              // handle UTF-8 BOM from Excel exports
    });
  } catch (err) {
    console.error('❌ Failed to parse CSV:', err.message);
    process.exit(1);
  }

  if (!records || records.length === 0) {
    console.error('❌ No records found in the CSV file.');
    process.exit(1);
  }

  console.log(`Found ${records.length} hymn(s) in the CSV.\n`);

  // Validate that required columns exist
  const firstRow = records[0];
  const requiredColumns = ['title', 'arabicTitle'];
  for (const col of requiredColumns) {
    if (!(col in firstRow)) {
      console.error(`❌ Missing required column: "${col}"`);
      console.error('Make sure your CSV has a header row with at least: title, arabicTitle');
      process.exit(1);
    }
  }

  // Build Firestore batch(es) — Firestore limit is 500 writes per batch
  const BATCH_SIZE = 400;
  let uploaded = 0;
  let skipped  = 0;

  for (let i = 0; i < records.length; i += BATCH_SIZE) {
    const chunk = records.slice(i, i + BATCH_SIZE);
    const batch = db.batch();
    const hymnsRef = db.collection('hymns');

    chunk.forEach((row, idx) => {
      const globalIdx = i + idx + 1;

      const title = nullIfEmpty(row.title);
      if (!title) {
        console.warn(`[${globalIdx}] ⚠️  Skipping row — missing title`);
        skipped++;
        return;
      }

      const hymnData = {
        title:           title,
        arabicTitle:     nullIfEmpty(row.arabicTitle)     || '',
        copticTitle:     nullIfEmpty(row.copticTitle)     || '',
        copticArlyrics:  nullIfEmpty(row.copticArlyrics)  || '',
        arabicLyrics:    nullIfEmpty(row.arabicLyrics)    || '',
        copticLyrics:    nullIfEmpty(row.copticLyrics)    || '',
        audioUrl:        nullIfEmpty(row.audioUrl),
        videoUrl:        nullIfEmpty(row.videoUrl),
        occasion:        nullIfEmpty(row.occasion)        || '',
        userClasses:     parseUserClasses(row.userClasses),
        order:           parseOrder(row.order),
        createdAt:       admin.firestore.FieldValue.serverTimestamp(),
        updatedAt:       admin.firestore.FieldValue.serverTimestamp(),
      };

      const docRef = hymnsRef.doc();
      batch.set(docRef, hymnData);
      uploaded++;

      console.log(`[${globalIdx}] ✓ Queued: ${hymnData.arabicTitle || hymnData.title}`);
      if (hymnData.userClasses.length) {
        console.log(`         Classes: ${hymnData.userClasses.join(', ')}`);
      }
    });

    console.log(`\n⏳ Committing batch (${i + 1}–${Math.min(i + BATCH_SIZE, records.length)})…`);
    await batch.commit();
    console.log('✅ Batch committed.\n');
  }

  // Summary
  console.log('══════════════════════════════');
  console.log('✅ Upload complete!');
  console.log(`   Uploaded : ${uploaded}`);
  if (skipped) console.log(`   Skipped  : ${skipped}`);
  console.log('══════════════════════════════\n');
  console.log('Next steps:');
  console.log('  1. Run your Flutter app: flutter run');
  console.log('  2. Navigate to the Hymns screen');
  console.log('  3. Hymns are filtered by userClass automatically');
}

uploadHymnsFromCSV()
  .catch(err => {
    console.error('\n❌ Unexpected error:', err);
    process.exit(1);
  })
  .finally(async () => {
    try { await admin.app().delete(); } catch (_) {}
    process.exit(0);
  });

