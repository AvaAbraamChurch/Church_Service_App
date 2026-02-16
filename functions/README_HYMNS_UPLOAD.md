# 🎵 Sample Hymns Data Uploader

This script uploads 6 sample hymns to your Firestore database for testing the Hymns feature.

## Sample Hymns Included:

1. **O Kirios** (الرب قد ملك) - Sunday hymn
2. **Tenen** (نسجد لك) - General hymn
3. **Aripsalin** (المزمور الخمسون) - Lent hymn
4. **Epouro** (ملك السلام) - General hymn
5. **Efnouti Nai Nan** (يا الله ارحمنا) - General hymn
6. **Apenchois** (ربنا يسوع المسيح) - General hymn

Each hymn includes:
- Titles in Arabic, Coptic, and English
- Lyrics in all three languages
- Occasion/category
- Proper ordering

## How to Run:

### Option 1: Using Firebase Emulator (Recommended for Testing)

1. Make sure you're in the functions directory:
   ```powershell
   cd C:\Users\Andrew\Desktop\Church_Apps\Github\church\functions
   ```

2. Start the Firebase emulator (in a separate terminal):
   ```powershell
   firebase emulators:start
   ```

3. Set the environment variable to use the emulator:
   ```powershell
   $env:FIRESTORE_EMULATOR_HOST="localhost:8080"
   ```

4. Run the script:
   ```powershell
   node add_sample_hymns.js
   ```

### Option 2: Upload to Production Database

⚠️ **Warning**: This will add data to your LIVE Firebase database!

1. Make sure you're in the functions directory:
   ```powershell
   cd C:\Users\Andrew\Desktop\Church_Apps\Github\church\functions
   ```

2. Ensure you're logged in to Firebase:
   ```powershell
   firebase login
   ```

3. Run the script:
   ```powershell
   node add_sample_hymns.js
   ```

## Expected Output:

```
🎵 Starting to upload sample hymns...

✓ Preparing: الرب قد ملك (O Kirios (The Lord Reigns))
✓ Preparing: نسجد لك (Tenen (We Worship You))
✓ Preparing: المزمور الخمسون (Aripsalin (Psalm 50))
✓ Preparing: ملك السلام (Epouro (The King of Peace))
✓ Preparing: يا الله ارحمنا (Efnouti Nai Nan (O God Have Mercy))
✓ Preparing: ربنا يسوع المسيح (Apenchois (Our Lord Jesus Christ))

✅ Successfully added all sample hymns to Firestore!
📊 Total hymns added: 6

🎉 You can now test the Hymns screen in your app!

✅ Done!
```

## After Running:

1. Open your Flutter app
2. Navigate to the Hymns screen
3. You should see a dropdown with all 6 hymns
4. Select any hymn to see its full details

## Troubleshooting:

### Error: "Cannot find module 'firebase-admin'"
Run: `npm install` in the functions directory

### Error: "Permission denied"
Make sure you're logged in: `firebase login`

### Error: "ENOENT: no such file or directory"
Make sure you're running the command from the functions directory

### Emulator Connection Issues
- Check if the emulator is running on port 8080
- Verify the environment variable is set: `$env:FIRESTORE_EMULATOR_HOST`

## Note:

This script uses Firebase Admin SDK which requires proper authentication:
- For emulator: No authentication needed
- For production: Must be logged in via Firebase CLI or have service account credentials

## Firestore Structure Created:

```
hymns/
  {auto-generated-id}/
    title: "O Kirios (The Lord Reigns)"
    arabicTitle: "الرب قد ملك"
    copticTitle: "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ"
    lyrics: "..."
    arabicLyrics: "..."
    copticLyrics: "..."
    audioUrl: null
    videoUrl: null
    occasion: "Sunday"
    order: 1
    createdAt: [timestamp]
    updatedAt: [timestamp]
```

## Need More Hymns?

You can easily add more hymns by:
1. Editing this script and adding more objects to the `sampleHymns` array
2. Running the script again
3. Or manually adding them through Firebase Console

---

**Happy Testing! 🎉**

