# Adding Sample Hymns Data

## Quick Start

To add sample hymns to your Firestore database, follow these steps:

### Option 1: Using Firebase Console (Easiest)

1. Go to your Firebase Console
2. Navigate to Firestore Database
3. Create a new collection called `hymns`
4. Add documents with the following structure:

#### Sample Document 1:
```
Document ID: (auto-generated)

Fields:
- title: "O Kirios (The Lord Reigns)" (string)
- arabicTitle: "الرب قد ملك" (string)
- copticTitle: "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ" (string)
- lyrics: "The Lord is King, He is clothed with majesty..." (string)
- arabicLyrics: "الرب قد ملك لبس الجلال..." (string)
- copticLyrics: "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ ⲁϥϯϩⲓⲱⲧϥ..." (string)
- audioUrl: null
- videoUrl: null
- occasion: "Sunday" (string)
- order: 1 (number)
- createdAt: (timestamp - auto)
- updatedAt: (timestamp - auto)
```

#### Sample Document 2:
```
Document ID: (auto-generated)

Fields:
- title: "Tenen (We Worship You)" (string)
- arabicTitle: "نسجد لك" (string)
- copticTitle: "Ⲧⲉⲛⲱϣⲧ ⲙ̀ⲙⲟⲕ" (string)
- lyrics: "We worship You, O Christ, with Your Good Father..." (string)
- arabicLyrics: "نسجد لك أيها المسيح مع أبيك الصالح..." (string)
- copticLyrics: "Ⲧⲉⲛⲱϣⲧ ⲙ̀ⲙⲟⲕ ⲱ̀ Ⲡⲭ̅ⲥ̅..." (string)
- audioUrl: null
- videoUrl: null
- occasion: "General" (string)
- order: 2 (number)
- createdAt: (timestamp - auto)
- updatedAt: (timestamp - auto)
```

### Option 2: Using Firestore REST API or Admin SDK

If you have a Node.js script with Firebase Admin SDK set up, you can batch upload hymns. The script should be in your functions directory.

### Required Fields:
- **title** (string): English title
- **arabicTitle** (string): Arabic title - shown in dropdown
- **copticTitle** (string): Coptic title
- **lyrics** (string, optional): English lyrics
- **arabicLyrics** (string, optional): Arabic lyrics
- **copticLyrics** (string, optional): Coptic lyrics
- **audioUrl** (string, optional): URL to audio file
- **videoUrl** (string, optional): URL to video file
- **occasion** (string, optional): e.g., "Sunday", "General", "Lent", "Feast"
- **order** (number): For sorting, start from 1
- **createdAt** (timestamp): Auto-generated
- **updatedAt** (timestamp): Auto-generated

## Firestore Security Rules

Add these security rules to protect the hymns collection:

```javascript
match /hymns/{hymnId} {
  // Allow all authenticated users to read hymns
  allow read: if request.auth != null;
  
  // Only admins can create, update, or delete hymns
  allow write: if request.auth != null && 
    get(/databases/$(database)/documents/users/$(request.auth.uid)).data.isAdmin == true;
}
```

## Testing

After adding at least one hymn:
1. Run your Flutter app
2. Navigate to the Hymns screen
3. You should see the dropdown populated with hymns
4. Select a hymn to view its details

## More Sample Hymns

### Sample 3: Aripsalin (Psalm 50)
- title: "Aripsalin (Psalm 50)"
- arabicTitle: "المزمور الخمسون"
- copticTitle: "Ⲁⲣⲓⲯⲁⲗⲓⲛ"
- occasion: "Lent"
- order: 3

### Sample 4: Epouro (The King of Peace)
- title: "Epouro (The King of Peace)"
- arabicTitle: "ملك السلام"
- copticTitle: "Ⲡ̀ⲟⲩⲣⲟ ⲛ̀ⲧⲉ ϯϩⲓⲣⲏⲛⲏ"
- occasion: "General"
- order: 4

### Sample 5: Efnouti Nai Nan
- title: "Efnouti Nai Nan (O God Have Mercy)"
- arabicTitle: "يا الله ارحمنا"
- copticTitle: "Ⲉϥⲛⲟⲩϯ ⲛⲁⲓ ⲛⲁⲛ"
- occasion: "General"
- order: 5

### Sample 6: Apenchois
- title: "Apenchois (Our Lord Jesus Christ)"
- arabicTitle: "ربنا يسوع المسيح"
- copticTitle: "Ⲁⲡⲉⲛⲟ̅ⲥ̅ Ⲓ̅ⲏ̅ⲥ̅ Ⲡⲭ̅ⲥ̅"
- occasion: "General"
- order: 6

## Need Help?

If you need help adding sample data or setting up the hymns feature, please refer to the HYMNS_SETUP_GUIDE.md file in the same directory.

