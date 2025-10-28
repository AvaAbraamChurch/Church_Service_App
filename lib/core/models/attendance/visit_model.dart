import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/visit_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Visit model representing a single visit/attendance record.
///
/// Fields:
/// - id: Firestore document id (not stored inside document)
/// - childId: referenced child/user id
/// - servantsId: list of servant user ids
/// - childName: display name of the child (accepts legacy key "chidlName" as well)
/// - servantsNames: list of servant display names
/// - userType: the user type of the child (or related entity)
/// - date: visit date/time
/// - notes: optional notes
/// - visitType: type/category of visit (e.g., home, phone, church, ...)
class VisitModel {
  final String id;
  final String childId;
  final List<String> servantsId;
  final String childName;
  final List<String> servantsNames;
  final UserType userType;
  final DateTime date;
  final String? notes;
  final VisitType visitType;

  const VisitModel({
    required this.id,
    required this.childId,
    required this.servantsId,
    required this.childName,
    required this.servantsNames,
    required this.userType,
    required this.date,
    required this.visitType,
    this.notes,
  });

  VisitModel copyWith({
    String? id,
    String? childId,
    List<String>? servantsId,
    String? childName,
    List<String>? servantsNames,
    UserType? userType,
    DateTime? date,
    String? notes,
    VisitType? visitType,
  }) {
    return VisitModel(
      id: id ?? this.id,
      childId: childId ?? this.childId,
      servantsId: servantsId ?? List<String>.from(this.servantsId),
      childName: childName ?? this.childName,
      servantsNames: servantsNames ?? List<String>.from(this.servantsNames),
      userType: userType ?? this.userType,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      visitType: visitType ?? this.visitType,
    );
  }

  // Firestore-friendly map (no id inside; store enums as short codes; date as Timestamp)
  Map<String, dynamic> toMap() {
    return {
      'childId': childId,
      'servantsId': servantsId,
      'childName': childName,
      'servantsNames': servantsNames,
      'userType': userType.code, // 'PR','SS','SV','CH'
      'date': Timestamp.fromDate(date),
      if (notes != null && notes!.isNotEmpty) 'notes': notes,
      'visitType': visitType.toJson(), // Store as 'H' or 'P'
    };
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        ...toMap(),
        // For JSON (non-Firestore) consumers, serialize date as ISO8601
        'date': date.toIso8601String(),
      };

  factory VisitModel.fromJson(Map<String, dynamic> json) {
    final id = (json['id'] ?? '').toString();
    return VisitModel.fromMap(json, id: id);
  }

  factory VisitModel.fromMap(Map<String, dynamic>? map, {required String id}) {
    final data = map ?? const <String, dynamic>{};

    return VisitModel(
      id: id,
      childId: (data['childId'] ?? '').toString(),
      servantsId: _toStringList(data['servantsId']),
      // Accept both 'childName' and legacy typo 'chidlName'
      childName: (data['childName'] ?? data['chidlName'] ?? '').toString(),
      servantsNames: _toStringList(data['servantsNames']),
      userType: userTypeFromJson(data['userType']),
      date: _parseDate(data['date']) ?? DateTime.now(),
      notes: (data['notes'])?.toString(),
      visitType: VisitTypeExtension.fromJson(data['visitType']?.toString()),
    );
  }

  static VisitModel fromDocumentSnapshot(
    DocumentSnapshot<Map<String, dynamic>> snapshot,
  ) {
    return VisitModel.fromMap(snapshot.data(), id: snapshot.id);
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((e) => e?.toString() ?? '').where((e) => e.isNotEmpty).toList();
    }
    return const <String>[];
  }

  static DateTime? _parseDate(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is int) {
      // Assume milliseconds since epoch
      return DateTime.fromMillisecondsSinceEpoch(value);
    }
    if (value is String) {
      // Try parse ISO8601
      try {
        return DateTime.parse(value);
      } catch (_) {
        return null;
      }
    }
    return null;
  }

  @override
  String toString() {
    return 'VisitModel(id: $id, childId: $childId, servantsId: $servantsId, childName: $childName, servantsNames: $servantsNames, userType: ${userType.code}, date: ${date.toIso8601String()}, notes: ${notes ?? 'null'}, visitType: $visitType)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is VisitModel &&
        other.id == id &&
        other.childId == childId &&
        _listEquals(other.servantsId, servantsId) &&
        other.childName == childName &&
        _listEquals(other.servantsNames, servantsNames) &&
        other.userType == userType &&
        other.date == date &&
        other.notes == notes &&
        other.visitType == visitType;
  }

  @override
  int get hashCode => Object.hash(
        id,
        childId,
        Object.hashAll(servantsId),
        childName,
        Object.hashAll(servantsNames),
        userType,
        date,
        notes,
        visitType,
      );
}

bool _listEquals<T>(List<T> a, List<T> b) {
  if (identical(a, b)) return true;
  if (a.length != b.length) return false;
  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }
  return true;
}
