# Quick Start - Test Hymns Feature

## Step-by-Step Instructions

### 1. Upload Sample Data (One-Time Setup)

Open PowerShell and run:

```powershell
cd C:\Users\Andrew\Desktop\Church_Apps\Github\church\functions
node upload_hymns.js
```

**Expected Result:** You should see confirmation that 6 hymns were added to Firestore.

### 2. Run Your Flutter App

```powershell
cd C:\Users\Andrew\Desktop\Church_Apps\Github\church
flutter run
```

### 3. Test the Feature

1. Open the app on your device/emulator
2. Navigate to **Hymns** screen
3. You should see a **dropdown menu** at the top
4. Tap the dropdown - you'll see 6 hymns listed in Arabic:
   - الرب قد ملك
   - نسجد لك
   - المزمور الخمسون
   - ملك السلام
   - يا الله ارحمنا
   - ربنا يسوع المسيح

5. **Select any hymn** - you'll see:
   - Titles in Arabic, Coptic, and English
   - Occasion tag
   - Full lyrics in all three languages
   - Audio/Video buttons (placeholders for future)

### 4. Verify Everything Works

✅ Dropdown shows all hymns  
✅ Selecting a hymn displays its details  
✅ All text is readable and properly formatted  
✅ Scrolling works smoothly for long lyrics  
✅ Occasion tags display with colors  

---

## Troubleshooting

**Problem:** Script fails with "Cannot find module 'firebase-admin'"  
**Solution:** Run `npm install` in the functions directory

**Problem:** No hymns appear in dropdown  
**Solution:** 
- Check Firebase Console → Firestore → verify `hymns` collection exists
- Verify you're logged in to Firebase: `firebase login`
- Check app is connected to correct Firebase project

**Problem:** Dropdown shows but is empty  
**Solution:**
- Verify user is authenticated (required by security rules)
- Check Firestore security rules allow read access

---

## That's It!

You now have a fully functional hymns feature with sample data ready to test!

For more details, see:
- `COMPLETE_SETUP_GUIDE.md` - Full documentation
- `README_HYMNS_UPLOAD.md` - Upload script details
- `HYMNS_SETUP_GUIDE.md` - Feature architecture

**Enjoy! 🎉**

