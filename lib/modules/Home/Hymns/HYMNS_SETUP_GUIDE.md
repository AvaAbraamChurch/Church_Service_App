# Hymns Feature - Setup Guide

## Overview
The Hymns feature has been implemented with:
1. **HymnModel** - Data model for hymns
2. **HymnsService** - Service layer for Firestore operations
3. **HymnsScreen** - UI with dropdown selection and hymn display

## Features
- ✅ Dropdown menu to select hymns
- ✅ Display hymn titles in Arabic, Coptic, and English
- ✅ Show lyrics in all three languages
- ✅ Display occasion tags
- ✅ Audio and video player buttons (ready for implementation)
- ✅ Responsive card-based layout

## Firestore Structure

### Collection Name: `hymns`

### Document Structure:
```json
{
  "title": "O Kirios",
  "arabicTitle": "الرب",
  "copticTitle": "Ⲡⲓⲟ̅ⲥ̅",
  "lyrics": "The Lord is King, He is clothed with majesty...",
  "arabicLyrics": "الرب قد ملك لبس الجلال...",
  "copticLyrics": "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ ⲁϥϯϩⲓⲱⲧϥ...",
  "audioUrl": "https://example.com/audio/o-kirios.mp3",
  "videoUrl": "https://example.com/video/o-kirios.mp4",
  "occasion": "Sunday",
  "order": 1,
  "createdAt": "2026-02-15T00:00:00Z",
  "updatedAt": "2026-02-15T00:00:00Z"
}
```

## Adding Sample Hymns

### Option 1: Using Firebase Console
1. Go to Firebase Console → Firestore Database
2. Create a new collection named `hymns`
3. Add documents with the structure above

### Option 2: Using Cloud Functions (Recommended for bulk import)
Create a Cloud Function to populate initial data:

```javascript
const admin = require('firebase-admin');

async function addSampleHymns() {
  const hymns = [
    {
      title: "O Kirios",
      arabicTitle: "الرب قد ملك",
      copticTitle: "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ",
      lyrics: "The Lord is King, He is clothed with majesty...",
      arabicLyrics: "الرب قد ملك لبس الجلال...",
      copticLyrics: "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ ⲁϥϯϩⲓⲱⲧϥ...",
      audioUrl: null,
      videoUrl: null,
      occasion: "Sunday",
      order: 1,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      title: "Tenen",
      arabicTitle: "نسجد لك",
      copticTitle: "Ⲧⲉⲛⲱϣⲧ ⲙ̀ⲙⲟⲕ",
      lyrics: "We worship You, O Christ, with Your Good Father...",
      arabicLyrics: "نسجد لك أيها المسيح مع أبيك الصالح...",
      copticLyrics: "Ⲧⲉⲛⲱϣⲧ ⲙ̀ⲙⲟⲕ ⲱ̀ Ⲡⲭ̅ⲥ̅ ⲛⲉⲙ Ⲡⲉⲕⲓⲱⲧ ⲛ̀ⲁⲅⲁⲑⲟⲥ...",
      audioUrl: null,
      videoUrl: null,
      occasion: "General",
      order: 2,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    },
    {
      title: "Aripsalin",
      arabicTitle: "المزمور الخمسون",
      copticTitle: "Ⲁⲣⲓⲯⲁⲗⲓⲛ",
      lyrics: "Psalm 50: Have mercy upon me, O God...",
      arabicLyrics: "ارحمنى يا الله كعظيم رحمتك...",
      copticLyrics: "Ⲛⲁⲓ ⲛⲏⲓ Ⲫϯ ⲕⲁⲧⲁ ⲡⲉⲕⲛⲓϣϯ ⲛ̀ⲛⲁⲓ...",
      audioUrl: null,
      videoUrl: null,
      occasion: "Lent",
      order: 3,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }
  ];

  const batch = admin.firestore().batch();
  const hymnsRef = admin.firestore().collection('hymns');

  hymns.forEach((hymn) => {
    const docRef = hymnsRef.doc();
    batch.set(docRef, hymn);
  });

  await batch.commit();
  console.log('Sample hymns added successfully!');
}
```

## Field Descriptions

- **id**: Auto-generated document ID
- **title**: English title of the hymn
- **arabicTitle**: Arabic title (displayed in dropdown)
- **copticTitle**: Coptic title
- **lyrics**: English lyrics (optional)
- **arabicLyrics**: Arabic lyrics (optional)
- **copticLyrics**: Coptic lyrics (optional)
- **audioUrl**: URL to audio file (optional)
- **videoUrl**: URL to video file (optional)
- **occasion**: Category/occasion (e.g., "Sunday", "Feast", "Lent", "General")
- **order**: Display order (integer, for sorting)
- **createdAt**: Creation timestamp
- **updatedAt**: Last update timestamp

## Usage

1. Users open the Hymns screen from the app
2. A dropdown menu displays all available hymns (by Arabic title)
3. When a hymn is selected, the screen displays:
   - All titles (Arabic, Coptic, English)
   - Occasion tag
   - Lyrics in all available languages
   - Audio/Video player buttons (if URLs provided)

## Future Enhancements

- [ ] Implement audio player functionality
- [ ] Implement video player functionality
- [ ] Add search functionality
- [ ] Add filter by occasion
- [ ] Add favorite hymns feature
- [ ] Add offline caching
- [ ] Add sharing functionality

## Testing

To test the feature:
1. Add at least one hymn to the Firestore `hymns` collection
2. Run the app and navigate to the Hymns screen
3. Select a hymn from the dropdown
4. Verify that all data displays correctly

## Firestore Security Rules

Don't forget to add security rules for the hymns collection:

```
match /hymns/{hymnId} {
  // Allow all authenticated users to read hymns
  allow read: if request.auth != null;
  
  // Only admins can create, update, or delete hymns
  allow write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

