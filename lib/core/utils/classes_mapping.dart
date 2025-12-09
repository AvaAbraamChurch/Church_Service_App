/// Competition Classes Mapping
/// Maps class codes to display names for competitions
library;

class CompetitionClassMapping {
  // Class mapping data
  static const Map<String, String> classMapping = {
    'all': 'الكل',
    '1&2': 'الصف الأول و الثاني',
    '3&4': 'الصف الثالث و الرابع',
    '5&6': 'الصف الخامس و السادس',
    '1': 'الصف الأول',
    '2': 'الصف الثاني',
    '3': 'الصف الثالث',
    '4': 'الصف الرابع',
    '5': 'الصف الخامس',
    '6': 'الصف السادس',
    'prep1': 'الصف الأول الإعدادي',
    'prep2': 'الصف الثاني الإعدادي',
    'prep3': 'الصف الثالث الإعدادي',
    'sec1': 'الصف الأول الثانوي',
    'sec2': 'الصف الثاني الثانوي',
    'sec3': 'الصف الثالث الثانوي',
    'prep': 'المرحلة الإعدادية',
    'sec': 'المرحلة الثانوية',
    'primary': 'المرحلة الابتدائية',
    'children': 'الأطفال',
    'servants': 'الخدام',
    'youth': 'الشباب',
    'university': 'الجامعة',
    'graduates': 'الخريجين',
  };

  // Category groupings
  static const Map<String, List<String>> categoryGroups = {
    'primary': ['1', '2', '3', '4', '5', '6', '1&2', '3&4', '5&6'],
    'prep': ['prep1', 'prep2', 'prep3'],
    'sec': ['sec1', 'sec2', 'sec3'],
    'children': ['1', '2', '3', '4', '5', '6', '1&2', '3&4', '5&6', 'prep1', 'prep2', 'prep3'],
    'youth': ['sec1', 'sec2', 'sec3', 'university'],
    'servants': ['servants'],
    'graduates': ['graduates'],
  };

  /// Get display name for a class code
  static String getClassName(String code) {
    return classMapping[code] ?? code;
  }

  /// Get all class codes
  static List<String> getAllClassCodes() {
    return classMapping.keys.toList();
  }

  /// Get class codes for a specific category
  static List<String> getClassCodesForCategory(String category) {
    return categoryGroups[category] ?? [];
  }

  /// Get class code and name pairs for dropdown
  static List<MapEntry<String, String>> getClassOptions() {
    return classMapping.entries.toList();
  }

  /// Get grouped class options (by category)
  static Map<String, List<MapEntry<String, String>>> getGroupedClassOptions() {
    return {
      'عام': [
        const MapEntry('all', 'الكل'),
      ],
      'صفوف مجمعة': [
        const MapEntry('1&2', 'الصف الأول و الثاني'),
        const MapEntry('3&4', 'الصف الثالث و الرابع'),
        const MapEntry('5&6', 'الصف الخامس و السادس'),
      ],
      'الصفوف الابتدائية': [
        const MapEntry('1', 'الصف الأول'),
        const MapEntry('2', 'الصف الثاني'),
        const MapEntry('3', 'الصف الثالث'),
        const MapEntry('4', 'الصف الرابع'),
        const MapEntry('5', 'الصف الخامس'),
        const MapEntry('6', 'الصف السادس'),
      ],
      'المرحلة الإعدادية': [
        const MapEntry('prep1', 'الصف الأول الإعدادي'),
        const MapEntry('prep2', 'الصف الثاني الإعدادي'),
        const MapEntry('prep3', 'الصف الثالث الإعدادي'),
      ],
      'المرحلة الثانوية': [
        const MapEntry('sec1', 'الصف الأول الثانوي'),
        const MapEntry('sec2', 'الصف الثاني الثانوي'),
        const MapEntry('sec3', 'الصف الثالث الثانوي'),
      ],
      'فئات أخرى': [
        const MapEntry('children', 'الأطفال'),
        const MapEntry('servants', 'الخدام'),
        const MapEntry('youth', 'الشباب'),
        const MapEntry('university', 'الجامعة'),
        const MapEntry('graduates', 'الخريجين'),
      ],
    };
  }

  /// Check if a class code is valid
  static bool isValidClassCode(String code) {
    return classMapping.containsKey(code);
  }

  /// Get all primary class codes (individual classes)
  static List<String> getPrimaryClassCodes() {
    return ['1', '2', '3', '4', '5', '6'];
  }

  /// Get all preparatory class codes
  static List<String> getPrepClassCodes() {
    return ['prep1', 'prep2', 'prep3'];
  }

  /// Get all secondary class codes
  static List<String> getSecondaryClassCodes() {
    return ['sec1', 'sec2', 'sec3'];
  }

  /// Get combined class codes
  static List<String> getCombinedClassCodes() {
    return ['1&2', '3&4', '5&6'];
  }

  /// Check if a user's class matches the competition's target audience
  /// Returns true if the user can access the competition based on their class
  static bool canAccessCompetition(String userClass, String competitionTargetAudience) {
    // If competition is for all, everyone can access
    if (competitionTargetAudience == 'all') {
      return true;
    }

    // If user class matches exactly
    if (userClass == competitionTargetAudience) {
      return true;
    }

    // Handle combined classes (e.g., '1&2' should match '1' or '2')
    if (competitionTargetAudience.contains('&')) {
      final classParts = competitionTargetAudience.split('&');
      if (classParts.contains(userClass)) {
        return true;
      }
    }

    // Handle if user is in a combined class and competition targets individual class
    // e.g., user class is '1&2' and competition is for '1'
    if (userClass.contains('&')) {
      final userClassParts = userClass.split('&');
      if (userClassParts.contains(competitionTargetAudience)) {
        return true;
      }
    }

    // Check category-based access
    // If competition targets a category (like 'primary', 'children', etc.)
    // check if user's class is in that category
    if (categoryGroups.containsKey(competitionTargetAudience)) {
      final categoryClasses = categoryGroups[competitionTargetAudience]!;

      // Check if user class is in the category
      if (categoryClasses.contains(userClass)) {
        return true;
      }

      // If user class is combined (like '1&2'), check if any part is in category
      if (userClass.contains('&')) {
        final userClassParts = userClass.split('&');
        for (final part in userClassParts) {
          if (categoryClasses.contains(part)) {
            return true;
          }
        }
      }
    }

    // Check reverse: if user is in a category and competition targets a class within that category
    for (final entry in categoryGroups.entries) {
      if (entry.key == userClass && entry.value.contains(competitionTargetAudience)) {
        return true;
      }
    }

    return false;
  }
}

