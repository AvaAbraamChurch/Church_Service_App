import 'package:church/core/constants/strings.dart' as S;

/// Gender enum representing a person's gender with helpers for parsing and serialization.
///
/// Keep UI dependencies out of core/utils. This file provides:
/// - The `Gender` enum.
/// - Extensions for labels and codes.
/// - Parsing helpers from free-text or short codes.
/// - Simple JSON (de)serialization helpers.
///
/// Conventions:
/// - Codes: M, F (Male, Female)
/// - Labels: Arabic defaults for this app.

/// Canonical values for gender.
enum Gender {
  male,
  female,
}

/// Convenience constants.
class GenderLists {
  /// Common selectable options.
  static const List<Gender> selectable = [Gender.male, Gender.female];

  /// All values.
  static const List<Gender> all = Gender.values;
}

extension GenderX on Gender {
  /// Short code used for compact storage or APIs.
  /// M, F
  String get code => switch (this) {
        Gender.male => 'M',
        Gender.female => 'F',
      };

  /// Human-readable Arabic label.
  String get label => switch (this) {
        Gender.male => S.male,   // 'ذكر'
        Gender.female => S.female, // 'أنثى'
      };

  /// A very short label (1-char) suitable for chips/avatars, etc.
  String get shortLabel => switch (this) {
        Gender.male => 'M',
        Gender.female => 'F',
      };
}

/// Parse from various user inputs like 'male', 'M', 'Female', or Arabic 'ذكر', 'أنثى'.
/// When input is not recognized, returns [fallback] (default is [Gender.male]).
Gender parseGender(String? input, {Gender fallback = Gender.male}) {
  final value = input?.trim();
  if (value == null || value.isEmpty) return fallback;
  final lower = value.toLowerCase();

  switch (lower) {
    // English variants
    case 'm':
    case 'male':
      return Gender.male;
    case 'f':
    case 'female':
      return Gender.female;

    // Arabic variants
    case S.male:
      return Gender.male;
    case S.female:
      return Gender.female;

    default:
      return fallback;
  }
}

/// Try parse from input; returns null when not recognized or empty.
Gender? tryParseGender(String? input) {
  final value = input?.trim();
  if (value == null || value.isEmpty) return null;
  final lower = value.toLowerCase();
  switch (lower) {
    // English
    case 'm':
    case 'male':
      return Gender.male;
    case 'f':
    case 'female':
      return Gender.female;
    // Arabic
    case S.male:
      return Gender.male;
    case S.female:
      return Gender.female;
    default:
      return null;
  }
}

/// Parse from compact code 'M' or 'F'.
Gender genderFromCode(String? code, {Gender fallback = Gender.male}) {
  final c = code?.trim().toUpperCase();
  return switch (c) {
    'M' => Gender.male,
    'F' => Gender.female,
    _ => fallback,
  };
}

/// Try parse from code; returns null when not recognized or empty.
Gender? tryGenderFromCode(String? code) {
  final c = code?.trim();
  if (c == null || c.isEmpty) return null;
  switch (c.toUpperCase()) {
    case 'M':
      return Gender.male;
    case 'F':
      return Gender.female;
    default:
      return null;
  }
}

/// Serialize to JSON-friendly value (a short code string).
String genderToJson(Gender gender) => gender.code;

/// Deserialize from JSON value (expects string code or label).
Gender genderFromJson(dynamic json, {Gender fallback = Gender.male}) {
  if (json is String) {
    // Prefer short code if it matches; otherwise parse by label/text.
    final byCode = tryGenderFromCode(json);
    if (byCode != null) return byCode;
    return parseGender(json, fallback: fallback);
  }
  return fallback;
}
