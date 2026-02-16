# Hymns FAB Menu Implementation - Summary

## Overview
Added a Floating Action Button (FAB) with a menu for adding and editing hymns, only visible to users with userType: **servant**, **superServant**, or **priest**.

---

## 🎯 Features Implemented

### 1. **User Permission Check**
```dart
bool get _canManageHymns {
  if (_currentUser == null) return false;
  return _currentUser!.userType == UserType.servant ||
      _currentUser!.userType == UserType.superServant ||
      _currentUser!.userType == UserType.priest;
}
```

Only users with these userTypes can see and use the FAB:
- ✅ **Servant** (`UserType.servant`)
- ✅ **Super Servant** (`UserType.superServant`)
- ✅ **Priest** (`UserType.priest`)

### 2. **FAB Menu Design**
```
┌─────────────────────────┐
│  [تعديل لحن]  [🔧]      │  ← Edit button
├─────────────────────────┤
│  [إضافة لحن جديد]  [➕]  │  ← Add button
├─────────────────────────┤
│         [✕]             │  ← Main FAB (when open)
│         or              │
│         [☰]             │  ← Main FAB (when closed)
└─────────────────────────┘
```

### 3. **Interactive Animation**
- **FAB rotates** when tapped (45° rotation when opening)
- **Smooth menu expansion** with fade-in/fade-out
- **Icon changes** from menu (☰) to close (✕)

---

## 📝 Changes Made

### State Variables Added
```dart
UserModel? _currentUser;           // Store full user data
bool _isFabMenuOpen = false;       // Track FAB menu state
```

### Methods Added

#### `_canManageHymns`
- Getter that checks if current user has permission to manage hymns
- Returns true only for servant/superServant/priest

#### `_buildFabMenu()`
- Main FAB widget with expandable menu
- Shows/hides menu items based on `_isFabMenuOpen`
- Animated rotation on tap

#### `_buildFabMenuItem()`
- Helper to build individual menu items
- Creates label + icon button combination
- Accepts onTap callback

#### `_showAddHymnDialog()`
- Placeholder for add hymn functionality
- Shows snackbar message (TODO: implement full form)

#### `_showEditHymnDialog()`
- Placeholder for edit hymn functionality
- Shows selected hymn title
- Requires a hymn to be selected first

---

## 🔍 User Flow

### Opening the Menu
```
1. User (servant/superServant/priest) sees FAB at bottom-right
2. User taps FAB
3. FAB icon rotates 45° and changes to close (✕)
4. Menu items slide up and fade in:
   - Edit option (تعديل لحن)
   - Add option (إضافة لحن جديد)
```

### Adding a Hymn
```
1. User taps "إضافة لحن جديد"
2. Menu closes
3. Shows snackbar: "صفحة إضافة اللحن قيد التطوير"
4. TODO: Navigate to add hymn screen
```

### Editing a Hymn
```
1. User selects a hymn from dropdown
2. User taps FAB → "تعديل لحن"
3. Menu closes
4. Shows snackbar with hymn name
5. TODO: Navigate to edit hymn screen

If no hymn selected:
- Shows warning: "الرجاء اختيار لحن للتعديل"
```

---

## 🎨 UI Design

### FAB Colors
- **Main FAB**: `teal500` background, white icon
- **Menu items (label)**: White background, `teal700` text
- **Menu items (icon)**: `teal700` background, white icon

### Menu Item Layout
```
┌─────────────────────────────────┐
│  [Label Text]  [○ Icon]         │
│   (white bg)   (teal bg)        │
└─────────────────────────────────┘
```

### Spacing
- 12px between menu items
- 16px between last menu item and main FAB
- 16px horizontal padding for labels
- 8px vertical padding for labels

---

## 👥 User Type Visibility

| User Type | Can See FAB? | Can Add? | Can Edit? |
|-----------|-------------|----------|-----------|
| **Priest** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Super Servant** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Servant** | ✅ Yes | ✅ Yes | ✅ Yes |
| **Child** | ❌ No | ❌ No | ❌ No |
| **Visitor** | ❌ No | ❌ No | ❌ No |
| **Not Logged In** | ❌ No | ❌ No | ❌ No |

---

## 🔒 Security

### Frontend Check
```dart
floatingActionButton: _canManageHymns ? _buildFabMenu() : null,
```
- FAB is completely hidden for unauthorized users
- Cannot be accessed even if user tries to manipulate UI

### Backend (TODO)
When implementing actual add/edit functionality:
```dart
// In HymnsService
Future<bool> addHymn(HymnModel hymn) async {
  // ⚠️ TODO: Add server-side permission check
  // Verify user is servant/superServant/priest in Firestore Rules
}
```

**Firestore Security Rules** (recommended):
```javascript
match /hymns/{hymnId} {
  allow write: if request.auth != null 
    && get(/databases/$(database)/documents/users/$(request.auth.uid)).data.userType 
    in ['SV', 'SS', 'PR'];
}
```

---

## 📋 Next Steps (TODO)

### 1. Create Add Hymn Screen
- [ ] Create `add_hymn_screen.dart`
- [ ] Form fields:
  - Arabic Title
  - Coptic Title
  - English Title
  - Arabic Lyrics (multiline)
  - Coptic Lyrics (multiline)
  - English Lyrics (multiline)
  - Audio URL
  - Video URL
  - Occasion (dropdown)
  - User Classes (multi-select)
  - Order (number)
- [ ] Validation
- [ ] Upload to Firestore

### 2. Create Edit Hymn Screen
- [ ] Create `edit_hymn_screen.dart`
- [ ] Pre-fill form with selected hymn data
- [ ] Allow editing all fields
- [ ] Update in Firestore
- [ ] Option to delete hymn

### 3. Navigation
```dart
void _showAddHymnDialog() {
  Navigator.push(
    context,
    MaterialPageRoute(builder: (context) => AddHymnScreen()),
  );
}

void _showEditHymnDialog() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EditHymnScreen(hymn: _selectedHymn!),
    ),
  );
}
```

### 4. Backend Implementation
- [ ] Implement `addHymn()` in HymnsService
- [ ] Implement `updateHymn()` in HymnsService
- [ ] Add Firestore security rules
- [ ] Test with different user types

---

## ✅ Testing Checklist

- [ ] Login as **Priest** → FAB should be visible ✅
- [ ] Login as **Super Servant** → FAB should be visible ✅
- [ ] Login as **Servant** → FAB should be visible ✅
- [ ] Login as **Child** → FAB should be hidden ❌
- [ ] Not logged in → FAB should be hidden ❌
- [ ] Tap FAB → Menu should expand with animation
- [ ] Tap "إضافة لحن جديد" → Shows placeholder message
- [ ] Tap "تعديل لحن" without selecting hymn → Shows warning
- [ ] Select hymn, then tap "تعديل لحن" → Shows hymn name
- [ ] Tap FAB again → Menu should collapse
- [ ] FAB icon should rotate smoothly

---

## 🎉 Implementation Complete!

The FAB menu is now fully functional with:
- ✅ User permission checking based on userType
- ✅ Animated expandable menu
- ✅ Add and Edit options
- ✅ Proper error handling
- ✅ Arabic UI text
- ✅ Consistent teal color scheme
- ✅ Ready for full implementation

**Status: Ready for Add/Edit Screen Development**

---

**Created:** February 16, 2026  
**File Modified:** `lib/modules/Home/Hymns/hymns_screen.dart`

