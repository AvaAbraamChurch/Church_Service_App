import '../constants/strings.dart';

enum ServiceType {
  primaryBoys,
  primaryGirls,
  preparatoryBoys,
  preparatoryGirls,
  secondaryBoys,
  secondaryGirls,
  youthBoys,
  youthGirls,
}

extension ServiceTypeExtension on ServiceType {
  /// Returns the Arabic display name for the service type
  String get displayName {
    switch (this) {
      case ServiceType.primaryBoys:
        return 'خدمة ابتدائي - بنين';
      case ServiceType.primaryGirls:
        return 'خدمة ابتدائي - بنات';
      case ServiceType.preparatoryBoys:
        return 'خدمة إعدادي - بنين';
      case ServiceType.preparatoryGirls:
        return 'خدمة إعدادي - بنات';
      case ServiceType.secondaryBoys:
        return 'خدمة ثانوي - بنين';
      case ServiceType.secondaryGirls:
        return 'خدمة ثانوي - بنات';
      case ServiceType.youthBoys:
        return 'خدمة شباب - شباب';
      case ServiceType.youthGirls:
        return 'خدمة شباب - فتيات';
    }
  }

  /// Returns the Firebase/Database key for the service type
  String get key {
    switch (this) {
      case ServiceType.primaryBoys:
        return 'primary_boys';
      case ServiceType.primaryGirls:
        return 'primary_girls';
      case ServiceType.preparatoryBoys:
        return 'preparatory_boys';
      case ServiceType.preparatoryGirls:
        return 'preparatory_girls';
      case ServiceType.secondaryBoys:
        return 'secondary_boys';
      case ServiceType.secondaryGirls:
        return 'secondary_girls';
      case ServiceType.youthBoys:
        return 'youth_boys';
      case ServiceType.youthGirls:
        return 'youth_girls';
    }
  }

  /// Returns the service level (primary, preparatory, secondary, youth)
  String get level {
    switch (this) {
      case ServiceType.primaryBoys:
      case ServiceType.primaryGirls:
        return primary;
      case ServiceType.preparatoryBoys:
      case ServiceType.preparatoryGirls:
        return preparatory;
      case ServiceType.secondaryBoys:
      case ServiceType.secondaryGirls:
        return secondary;
      case ServiceType.youthBoys:
      case ServiceType.youthGirls:
        return youth;
    }
  }

  /// Returns whether this service is for boys
  bool get isBoys {
    return this == ServiceType.primaryBoys ||
        this == ServiceType.preparatoryBoys ||
        this == ServiceType.secondaryBoys ||
        this == ServiceType.youthBoys;
  }

  /// Returns whether this service is for girls
  bool get isGirls {
    return this == ServiceType.primaryGirls ||
        this == ServiceType.preparatoryGirls ||
        this == ServiceType.secondaryGirls ||
        this == ServiceType.youthGirls;
  }

  /// Converts a string key to ServiceType
  static ServiceType? fromKey(String key) {
    switch (key.toLowerCase()) {
      case 'primary_boys':
        return ServiceType.primaryBoys;
      case 'primary_girls':
        return ServiceType.primaryGirls;
      case 'preparatory_boys':
        return ServiceType.preparatoryBoys;
      case 'preparatory_girls':
        return ServiceType.preparatoryGirls;
      case 'secondary_boys':
        return ServiceType.secondaryBoys;
      case 'secondary_girls':
        return ServiceType.secondaryGirls;
      case 'youth_boys':
        return ServiceType.youthBoys;
      case 'youth_girls':
        return ServiceType.youthGirls;
      default:
        return null;
    }
  }

  /// Converts a display name to ServiceType
  static ServiceType? fromDisplayName(String displayName) {
    for (var type in ServiceType.values) {
      if (type.displayName == displayName) {
        return type;
      }
    }
    return null;
  }
}

/// Helper function to parse ServiceType from JSON/Map data
/// Returns the fallback value if parsing fails
ServiceType serviceTypeFromJson(dynamic json, {ServiceType fallback = ServiceType.primaryBoys}) {
  if (json is String) {
    final byKey = ServiceTypeExtension.fromKey(json);
    if (byKey != null) return byKey;

    final byDisplayName = ServiceTypeExtension.fromDisplayName(json);
    if (byDisplayName != null) return byDisplayName;
  }
  return fallback;
}

