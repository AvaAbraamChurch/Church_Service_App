/**
 * Sample Hymns Data Uploader for Church App
 * Uploads sample hymns to Firestore database
 *
 * Setup Instructions:
 * 1. Make sure you have firebase-admin installed: npm install firebase-admin
 * 2. Make sure serviceAccountKey.json is in the same directory (or in parent Bulk_email_generator folder)
 * 3. Run: node upload_hymns.js
 */

const admin = require('firebase-admin');
const path = require('path');
const fs = require('fs');

// Initialize Firebase Admin SDK
try {
  // Try to find serviceAccountKey.json in current directory first
  let serviceAccountPath = path.join(__dirname, 'serviceAccountKey.json');

  // If not found, try parent directory (Bulk_email_generator folder)
  if (!fs.existsSync(serviceAccountPath)) {
    serviceAccountPath = path.join(__dirname, '..', 'Bulk_email_generator', 'serviceAccountKey.json');
  }

  // If still not found, show error
  if (!fs.existsSync(serviceAccountPath)) {
    console.error('❌ Error: serviceAccountKey.json not found!');
    console.error('Please place serviceAccountKey.json in one of these locations:');
    console.error('  1. ' + path.join(__dirname, 'serviceAccountKey.json'));
    console.error('  2. ' + path.join(__dirname, '..', 'Bulk_email_generator', 'serviceAccountKey.json'));
    console.error('\nYou can download it from Firebase Console > Project Settings > Service Accounts');
    process.exit(1);
  }

  const serviceAccount = require(serviceAccountPath);

  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount),
    projectId: 'nenshiri-emporo'
  });

  console.log('✓ Firebase Admin initialized successfully\n');
} catch (error) {
  console.error('❌ Error initializing Firebase Admin:');
  console.error(error.message);
  console.error('\nMake sure you have serviceAccountKey.json in the functions directory');
  console.error('Download it from: Firebase Console > Project Settings > Service Accounts');
  process.exit(1);
}

const db = admin.firestore();

const sampleHymns = [
  {
    title: 'O Kirios (The Lord Reigns)',
    arabicTitle: 'الرب قد ملك',
    copticTitle: 'Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ',
    copticArlyrics: 'The Lord is King, He is clothed with majesty.\nThe Lord is robed, He is girded with strength.\nSurely the world stands secure, it cannot be moved.\nYour throne is established from of old; You are from everlasting.',
    arabicLyrics: 'الرب قد ملك لبس الجلال\nلبس الرب القوة وتمنطق بها\nلأنه ثبت المسكونة فلا تتزعزع\nكرسيك ثابتة منذ القدم، منذ الأزل أنت',
    copticLyrics: 'Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ ⲁϥϯϩⲓⲱⲧϥ ⲙ̀ⲡⲓⲁⲙⲁϩⲓ\nⲀϥϯϩⲓⲱⲧϥ ⲛ̀ϫⲉ Ⲡⲓⲟ̅ⲥ̅ ⲛ̀ⲟⲩϫⲟⲙ ⲟⲩⲟϩ ⲁϥⲙⲟⲣϥ\nⲔⲉ ⲅⲁⲣ ⲁϥⲧⲁϫⲣⲟ ⲛ̀ϯⲟⲓⲕⲟⲩⲙⲉⲛⲏ ⲛ̀ⲛⲉⲥⲕⲓⲙ\nⲠⲉⲕⲑⲣⲟⲛⲟⲥ ⲥⲉⲃⲧⲱⲧ ⲓⲥϫⲉⲛ ϯⲁⲣⲭⲏ',
    audioUrl: null,
    videoUrl: null,
    occasion: 'Sunday',
    userClasses: ['Servant', 'Members'],
    order: 1,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    title: 'Tenen (We Worship You)',
    arabicTitle: 'نسجد لك',
    copticTitle: 'Ⲧⲉⲛⲱϣⲧ ⲙ̀ⲙⲟⲕ',
    copticArlyrics: 'We worship You, O Christ, with Your Good Father\nand the Holy Spirit, for You have come and saved us.',
    arabicLyrics: 'نسجد لك أيها المسيح مع أبيك الصالح والروح القدس\nلأنك أتيت وخلصتنا',
    copticLyrics: 'Ⲧⲉⲛⲱϣⲧ ⲙ̀ⲙⲟⲕ ⲱ̀ Ⲡⲭ̅ⲥ̅ ⲛⲉⲙ Ⲡⲉⲕⲓⲱⲧ ⲛ̀ⲁⲅⲁⲑⲟⲥ\nⲛⲉⲙ Ⲡⲓⲡ̅ⲛ̅ⲁ̅ ⲉ̅ⲑ̅ⲩ̅ ϫⲉ ⲁⲕⲓ̀ ⲁⲕⲥⲱϯ ⲙ̀ⲙⲟⲛ',
    audioUrl: null,
    videoUrl: null,
    occasion: 'General',
    userClasses: ['Servant', 'Members', 'Visitors'],
    order: 2,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    title: 'Aripsalin (Psalm 50)',
    arabicTitle: 'المزمور الخمسون',
    copticTitle: 'Ⲁⲣⲓⲯⲁⲗⲓⲛ',
    copticArlyrics: 'Have mercy upon me, O God, according to Your loving kindness;\nAccording to the multitude of Your tender mercies, blot out my transgressions.\nWash me thoroughly from my iniquity, and cleanse me from my sin.',
    arabicLyrics: 'ارحمني يا الله كعظيم رحمتك\nوككثرة رأفتك امح معاصي\nاغسلني كثيراً من إثمي ومن خطيتي طهرني',
    copticLyrics: 'Ⲛⲁⲓ ⲛⲏⲓ Ⲫϯ ⲕⲁⲧⲁ ⲡⲉⲕⲛⲓϣϯ ⲛ̀ⲛⲁⲓ\nⲔⲁⲧⲁ ⲡ̀ⲁϣⲁⲓ ⲛ̀ⲧⲉ ⲛⲉⲕⲙⲉⲧϣⲉⲛϩⲏⲧ ⲉⲕⲉ̀ⲥⲱⲗϫ ⲛ̀ⲛⲁⲁ̀ⲛⲟⲙⲓⲁ̀\nⲘⲁⲧⲟⲩⲃⲟⲓ ⲛ̀ⲟⲩⲙⲏϣ ⲉ̀ⲃⲟⲗϩⲁ ⲧⲁⲁ̀ⲛⲟⲙⲓⲁ̀ ⲟⲩⲟϩ ⲉ̀ⲃⲟⲗϩⲁ ⲧⲁⲛⲟⲃⲓ ⲙⲁⲧⲟⲩⲃⲟⲓ',
    audioUrl: null,
    videoUrl: null,
    occasion: 'Lent',
    userClasses: ['Servant', 'Members'],
    order: 3,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    title: 'Epouro (The King of Peace)',
    arabicTitle: 'ملك السلام',
    copticTitle: 'Ⲡ̀ⲟⲩⲣⲟ ⲛ̀ⲧⲉ ϯϩⲓⲣⲏⲛⲏ',
    copticArlyrics: 'The King of Peace, grant us Your peace,\nAnd forgive us our sins.\nScatter the enemies of the Church,\nThat they may never prevail against her.',
    arabicLyrics: 'ملك السلام أعطنا سلامك\nواغفر لنا خطايانا\nوبدد أعداء الكنيسة\nلكي لا يقووا عليها',
    copticLyrics: 'Ⲡ̀ⲟⲩⲣⲟ ⲛ̀ⲧⲉ ϯϩⲓⲣⲏⲛⲏ ⲙⲟⲓ ⲛⲁⲛ ⲛ̀ⲧⲉⲕϩⲓⲣⲏⲛⲏ\nⲬⲁ ⲛⲉⲛⲛⲟⲃⲓ ⲛⲁⲛ ⲉ̀ⲃⲟⲗ\nϪⲱⲣ ⲉ̀ⲃⲟⲗ ⲛ̀ⲛⲓϫⲁϫⲓ ⲛ̀ⲧⲉ ϯⲉⲕⲕ̀ⲗⲏⲥⲓⲁ̀\nϨⲓⲛⲁ ⲛ̀ⲛⲟⲩϭⲉⲙϫⲟⲙ ⲉ̀ⲣⲟⲥ',
    audioUrl: null,
    videoUrl: null,
    occasion: 'General',
    userClasses: ['Servant', 'Members', 'Visitors'],
    order: 4,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    title: 'Efnouti Nai Nan (O God Have Mercy)',
    arabicTitle: 'يا الله ارحمنا',
    copticTitle: 'Ⲉϥⲛⲟⲩϯ ⲛⲁⲓ ⲛⲁⲛ',
    copticArlyrics: 'O God, have mercy on us.\nO God, have mercy on us.\nO God, have mercy on us and bless us.\nO God, shine Your face upon us and have mercy on us.',
    arabicLyrics: 'يا الله ارحمنا\nيا الله ارحمنا\nيا الله ارحمنا وباركنا\nيا الله أنر بوجهك علينا وارحمنا',
    copticLyrics: 'Ⲉϥⲛⲟⲩϯ ⲛⲁⲓ ⲛⲁⲛ\nⲈϥⲛⲟⲩϯ ⲛⲁⲓ ⲛⲁⲛ\nⲈϥⲛⲟⲩϯ ⲛⲁⲓ ⲛⲁⲛ ⲟⲩⲟϩ ⲉⲕⲉ̀ⲥ̀ⲙⲟⲩ ⲉ̀ⲣⲟⲛ\nⲈϥⲛⲟⲩϯ ⲙⲁⲣⲉϥⲟⲩⲱⲛϩ ⲙ̀ⲡⲉϥϩⲟ ⲉ̀ϫⲱⲛ ⲟⲩⲟϩ ⲛ̀ⲧⲉϥⲛⲁⲓ ⲛⲁⲛ',
    audioUrl: null,
    videoUrl: null,
    occasion: 'General',
    userClasses: ['Servant'],
    order: 5,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  },
  {
    title: 'Apenchois (Our Lord Jesus Christ)',
    arabicTitle: 'ربنا يسوع المسيح',
    copticTitle: 'Ⲁⲡⲉⲛⲟ̅ⲥ̅ Ⲓ̅ⲏ̅ⲥ̅ Ⲡⲭ̅ⲥ̅',
    copticArlyrics: 'Our Lord Jesus Christ, the Only-Begotten Son,\nWho is of the Father before all ages.\nLight of Light, True God of True God,\nWho came and saved us.',
    arabicLyrics: 'ربنا يسوع المسيح الابن الوحيد\nالذي من الآب قبل كل الدهور\nنور من نور، إله حق من إله حق\nالذي أتى وخلصنا',
    copticLyrics: 'Ⲁⲡⲉⲛⲟ̅ⲥ̅ Ⲓ̅ⲏ̅ⲥ̅ Ⲡⲭ̅ⲥ̅ ⲡⲓϣⲏⲣⲓ ⲙ̀ⲙⲁⲩⲁⲧϥ\nⲪⲏⲉⲧϣⲟⲡ ⲉ̀ⲃⲟⲗϧⲉⲛ Ⲫⲓⲱⲧ ϧⲁϫⲱⲟⲩ ⲛ̀ⲛⲓⲉ̀ⲱⲛ ⲧⲏⲣⲟⲩ\nⲞⲩⲟⲩⲱⲓⲛⲓ ⲉ̀ⲃⲟⲗϧⲉⲛ ⲟⲩⲟⲩⲱⲓⲛⲓ ⲟⲩⲛⲟⲩϯ ⲛ̀ⲧⲁⲫ̀ⲙⲏⲓ ⲉ̀ⲃⲟⲗϧⲉⲛ ⲟⲩⲛⲟⲩϯ ⲛ̀ⲧⲁⲫ̀ⲙⲏⲓ\nⲪⲏⲉ̀ⲧⲁϥⲓ̀ ⲟⲩⲟϩ ⲁϥⲥⲱϯ ⲙ̀ⲙⲟⲛ',
    audioUrl: null,
    videoUrl: null,
    occasion: 'General',
    userClasses: ['Servant', 'Members', 'Visitors'],
    order: 6,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  }
];

async function uploadSampleHymns() {
  console.log('=== Sample Hymns Data Uploader ===\n');
  console.log('🎵 Starting to upload sample hymns...\n');

  try {
    const batch = db.batch();
    const hymnsRef = db.collection('hymns');

    console.log(`Found ${sampleHymns.length} sample hymn(s) to upload\n`);

    sampleHymns.forEach((hymn, index) => {
      const docRef = hymnsRef.doc();
      batch.set(docRef, hymn);
      console.log(`[${index + 1}/${sampleHymns.length}] ✓ Preparing: ${hymn.arabicTitle}`);
      console.log(`    ${hymn.title}`);
      console.log(`    Occasion: ${hymn.occasion}`);
      console.log('');
    });

    console.log('Committing batch write to Firestore...\n');
    await batch.commit();

    console.log('=== UPLOAD RESULTS ===\n');
    console.log('✅ Successfully added all sample hymns to Firestore!');
    console.log(`📊 Total hymns added: ${sampleHymns.length}`);
    console.log('\n🎉 You can now test the Hymns screen in your app!');
    console.log('\nNext steps:');
    console.log('  1. Run your Flutter app: flutter run');
    console.log('  2. Navigate to the Hymns screen');
    console.log('  3. Select a hymn from the dropdown to view details');

  } catch (error) {
    console.error('\n=== UPLOAD FAILED ===\n');
    console.error('❌ Error uploading hymns:', error.message);
    console.error('\nFull error details:');
    console.error(error);
    process.exit(1);
  } finally {
    await admin.app().delete();
    console.log('\n✅ Done! Firebase connection closed.\n');
    process.exit(0);
  }
}

uploadSampleHymns();

