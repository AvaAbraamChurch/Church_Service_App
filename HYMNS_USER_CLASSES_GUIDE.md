# Hymns User Classes Feature Guide

## Overview
The hymns system now supports filtering by user classes, allowing you to control which hymns are visible to different user groups (Servants, Members, Visitors, etc.).

## What Changed

### 1. **HymnModel** (`lib/core/models/hymn_model.dart`)
Added a new field `userClasses` to the HymnModel:

```dart
final List<String> userClasses; // User classes that can access this hymn
```

**Features:**
- Stores an array of user class strings (e.g., `['Servant', 'Members', 'Visitors']`)
- Defaults to an empty list if not specified
- Fully integrated with Firestore serialization/deserialization
- Included in the `copyWith` method for easy updates

### 2. **HymnsService** (`lib/core/services/hymns_service.dart`)
Added two new methods to filter hymns by user class:

#### **getHymnsByUserClass(String userClass)**
Fetches hymns that are accessible to a specific user class:

```dart
Stream<List<HymnModel>> hymns = hymnsService.getHymnsByUserClass('Servant');
```

#### **getHymnsByUserClassAndOccasion(String userClass, String occasion)**
Fetches hymns filtered by both user class AND occasion:

```dart
Stream<List<HymnModel>> hymns = hymnsService.getHymnsByUserClassAndOccasion('Members', 'Sunday');
```

### 3. **Upload Script** (`functions/upload_hymns.js`)
Updated all sample hymns to include `userClasses` field:

```javascript
{
  title: 'O Kirios (The Lord Reigns)',
  // ...other fields...
  userClasses: ['Servant', 'Members'],  // ✨ NEW
  // ...
}
```

## Usage Examples

### Example 1: Filter Hymns by User Class
```dart
// In your widget
final hymnsService = HymnsService();

// Get hymns for Servants only
StreamBuilder<List<HymnModel>>(
  stream: hymnsService.getHymnsByUserClass('Servant'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final hymns = snapshot.data!;
      // Display hymns...
    }
    return CircularProgressIndicator();
  },
);
```

### Example 2: Filter by User Class and Occasion
```dart
// Get Sunday hymns for Members
StreamBuilder<List<HymnModel>>(
  stream: hymnsService.getHymnsByUserClassAndOccasion('Members', 'Sunday'),
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      final hymns = snapshot.data!;
      // Display hymns...
    }
    return CircularProgressIndicator();
  },
);
```

### Example 3: Adding a Hymn with User Classes
```dart
final newHymn = HymnModel(
  id: '',
  title: 'New Hymn',
  arabicTitle: 'ترنيمة جديدة',
  copticTitle: 'Ⲧⲉⲛⲱϣⲧ',
  userClasses: ['Servant', 'Members', 'Visitors'],  // ✨ Specify who can see it
  occasion: 'General',
  order: 1,
  // ...other fields...
);

await hymnsService.addHymn(newHymn);
```

## Sample Data Structure

The sample hymns now include various user class combinations:

| Hymn | User Classes | Occasion |
|------|-------------|----------|
| O Kirios | `['Servant', 'Members']` | Sunday |
| Tenen | `['Servant', 'Members', 'Visitors']` | General |
| Aripsalin | `['Servant', 'Members']` | Lent |
| Epouro | `['Servant', 'Members', 'Visitors']` | General |
| Efnouti Nai Nan | `['Servant']` | General |
| Apenchois | `['Servant', 'Members', 'Visitors']` | General |

## Common User Classes

Here are some suggested user class values you might use:

- **`Servant`** - Church servants/deacons
- **`Members`** - Regular church members
- **`Visitors`** - Visitors or guests
- **`Youth`** - Youth group members
- **`Children`** - Sunday school children
- **`Choir`** - Choir members
- **`Deacons`** - Ordained deacons
- **`Admin`** - Administrators

## Firestore Structure

In Firestore, a hymn document now looks like:

```json
{
  "title": "O Kirios (The Lord Reigns)",
  "arabicTitle": "الرب قد ملك",
  "copticTitle": "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ",
  "copticArlyrics": "The Lord is King...",
  "arabicLyrics": "الرب قد ملك...",
  "copticLyrics": "Ⲡⲓⲟ̅ⲥ̅ ⲁϥⲉⲣⲟⲩⲣⲟ...",
  "audioUrl": null,
  "videoUrl": null,
  "occasion": "Sunday",
  "userClasses": ["Servant", "Members"],  // ✨ NEW
  "order": 1,
  "createdAt": "2026-02-16T12:00:00Z",
  "updatedAt": "2026-02-16T12:00:00Z"
}
```

## Firestore Query Note

The service uses Firestore's `arrayContains` query to filter hymns:

```javascript
.where('userClasses', arrayContains: userClass)
```

This means a hymn will appear if the user's class is included in the `userClasses` array.

## Testing

To test the user classes feature:

1. **Upload the sample data:**
   ```bash
   cd functions
   node upload_hymns.js
   ```

2. **In your app, test filtering:**
   ```dart
   // This should return 5 hymns
   hymnsService.getHymnsByUserClass('Servant');
   
   // This should return 4 hymns
   hymnsService.getHymnsByUserClass('Members');
   
   // This should return 3 hymns
   hymnsService.getHymnsByUserClass('Visitors');
   ```

3. **Test combined filters:**
   ```dart
   // Servants can see 1 hymn on Sunday
   hymnsService.getHymnsByUserClassAndOccasion('Servant', 'Sunday');
   ```

## Integration with User Authentication

To integrate with your user system:

1. **Get the current user's class:**
   ```dart
   String userClass = getCurrentUser().userClass; // e.g., 'Servant', 'Members'
   ```

2. **Filter hymns automatically:**
   ```dart
   Stream<List<HymnModel>> userHymns = hymnsService.getHymnsByUserClass(userClass);
   ```

3. **Optionally combine with occasion:**
   ```dart
   String occasion = 'Sunday'; // or dynamically based on date
   Stream<List<HymnModel>> userHymns = 
     hymnsService.getHymnsByUserClassAndOccasion(userClass, occasion);
   ```

## Notes

- **Empty userClasses array:** If `userClasses` is empty, the hymn won't appear in any user-class-filtered queries, but will appear in `getAllHymns()`
- **Multiple classes:** Users with multiple classes might need special handling (query for each class and combine results)
- **Backwards compatibility:** Existing hymns without `userClasses` field will have an empty array by default

## Next Steps

1. ✅ Model updated with `userClasses` field
2. ✅ Service methods added for filtering
3. ✅ Sample data includes user classes
4. 🔲 Update UI to filter based on current user's class
5. 🔲 Add admin interface to manage hymn access
6. 🔲 Create user class dropdown in hymn editor

---

**Created:** February 16, 2026  
**Last Updated:** February 16, 2026

