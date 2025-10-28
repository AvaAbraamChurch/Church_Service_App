import 'package:church/core/constants/strings.dart' as S;

/// Visit type enumeration
enum VisitType {
  phone,
  home,
}

/// Extension for VisitType JSON serialization and labels
extension VisitTypeExtension on VisitType {
  String toJson() {
    switch (this) {
      case VisitType.phone:
        return 'P';
      case VisitType.home:
        return 'H';
    }
  }

  /// Human-readable (Arabic) label for UI
  String get label {
    switch (this) {
      case VisitType.phone:
        return S.phoneVisit;
      case VisitType.home:
        return S.homeVisit;
    }
  }

  /// Create enum from stored json/code or label text
  static VisitType fromJson(String? value) {
    switch (value?.toUpperCase()) {
      case 'P':
        return VisitType.phone;
      case 'H':
        return VisitType.home;
      default:
        // Try from localized label (Arabic) or english words
        final v = (value ?? '').trim().toLowerCase();
        if (v.isEmpty) return VisitType.home;
        if (v == S.phoneVisit.toLowerCase() || v == 'phone' || v == 'phone visit') {
          return VisitType.phone;
        }
        if (v == S.homeVisit.toLowerCase() || v == 'home' || v == 'home visit') {
          return VisitType.home;
        }
        return VisitType.home;
    }
  }
}