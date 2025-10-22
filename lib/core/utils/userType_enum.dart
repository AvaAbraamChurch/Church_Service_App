import 'package:church/core/constants/strings.dart' as S;

/// UserType enum representing application user roles with helpers for parsing
/// and serialization. Arabic labels are returned via app string constants.
///
/// Values:
/// - priest (كاهن)
/// - superServant (امين/ة خدمة)
/// - servant (خادم/ة)
/// - child (مخدوم)
///
/// Codes (for storage/APIs): PR, SS, SV, CH

enum UserType {
  priest,
  superServant,
  servant,
  child,
}

/// Convenience lists for UI.
class UserTypeLists {
  static const List<UserType> selectable = [
    UserType.priest,
    UserType.superServant,
    UserType.servant,
    UserType.child,
  ];

  static const List<UserType> all = UserType.values;
}

extension UserTypeX on UserType {
  /// Short code for storage/APIs.
  String get code => switch (this) {
        UserType.priest => 'PR',
        UserType.superServant => 'SS',
        UserType.servant => 'SV',
        UserType.child => 'CH',
      };

  /// Arabic label using app-localized constants.
  String get label => switch (this) {
        UserType.priest => S.priest,
        UserType.superServant => S.superServant,
        UserType.servant => S.servant,
        UserType.child => S.child,
      };
}

/// Normalize Arabic text for resilient comparisons.
String _normalizeArabic(String s) {
  // Remove spaces and common diacritics
  const diacritics = [
    '\u064B', // FATHATAN
    '\u064C', // DAMMATAN
    '\u064D', // KASRATAN
    '\u064E', // FATHA
    '\u064F', // DAMMA
    '\u0650', // KASRA
    '\u0651', // SHADDA
    '\u0652', // SUKUN
    '\u0670', // SUPERSCRIPT ALEF
  ];
  final pattern = RegExp('[${diacritics.join()}]');
  return s.replaceAll(' ', '').replaceAll(pattern, '');
}

/// Parse from free text (English or Arabic). Falls back to [fallback] when not recognized.
UserType parseUserType(String? input, {UserType fallback = UserType.child}) {
  final value = input?.trim();
  if (value == null || value.isEmpty) return fallback;
  final lower = value.toLowerCase();

  switch (lower) {
    // English variants
    case 'priest':
      return UserType.priest;
    case 'superservant':
    case 'super servant':
    case 'super_servant':
    case 'super-servant':
      return UserType.superServant;
    case 'servant':
      return UserType.servant;
    case 'child':
      return UserType.child;
  }

  // Arabic normalization and matching
  final norm = _normalizeArabic(value);
  if (norm == _normalizeArabic('كاهن')) return UserType.priest;
  if (norm == _normalizeArabic('امين/ة خدمة') ||
      norm == _normalizeArabic('أمين/ة خدمة') ||
      norm == _normalizeArabic('امين خدمة') ||
      norm == _normalizeArabic('أمين خدمة')) {
    return UserType.superServant;
  }
  if (norm == _normalizeArabic('خادم') ||
      norm == _normalizeArabic('خادمة') ||
      norm == _normalizeArabic('خادم/ة') ||
      norm.contains(_normalizeArabic('خادم'))) {
    return UserType.servant;
  }
  if (norm == _normalizeArabic('مخدوم')) return UserType.child;

  return fallback;
}

/// Try parse from input; returns null when not recognized or empty.
UserType? tryParseUserType(String? input) {
  final value = input?.trim();
  if (value == null || value.isEmpty) return null;
  final parsed = parseUserType(value, fallback: UserType.child);
  // If parse returned fallback but input doesn't match fallback Arabic/English, consider it unknown
  final norm = _normalizeArabic(value);
  final matchesChild = norm == _normalizeArabic('child') || norm == _normalizeArabic('مخدوم');
  if (parsed == UserType.child && !matchesChild) return null;
  return parsed;
}

/// Parse from short code: PR, SS, SV, CH (case-insensitive).
UserType userTypeFromCode(String? code, {UserType fallback = UserType.child}) {
  final c = code?.trim().toUpperCase();
  return switch (c) {
    'PR' => UserType.priest,
    'SS' => UserType.superServant,
    'SV' => UserType.servant,
    'CH' => UserType.child,
    _ => fallback,
  };
}

/// Try parse from code; returns null when not recognized or empty.
UserType? tryUserTypeFromCode(String? code) {
  final c = code?.trim();
  if (c == null || c.isEmpty) return null;
  return switch (c.toUpperCase()) {
    'PR' => UserType.priest,
    'SS' => UserType.superServant,
    'SV' => UserType.servant,
    'CH' => UserType.child,
    _ => null,
  };
}

/// Serialize to JSON-friendly value (short code string).
String userTypeToJson(UserType type) => type.code;

/// Deserialize from JSON (accepts code or label/free text).
UserType userTypeFromJson(dynamic json, {UserType fallback = UserType.child}) {
  if (json is String) {
    final byCode = tryUserTypeFromCode(json);
    if (byCode != null) return byCode;
    return parseUserType(json, fallback: fallback);
  }
  return fallback;
}
