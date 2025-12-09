/// Dynamic Class Mapping Model
/// Allows admins to map class codes to specific church class names
library;

import 'package:cloud_firestore/cloud_firestore.dart';

class ClassMapping {
  final String id;
  final String classCode; // e.g., "1&2", "3&4", etc.
  final String className; // e.g., "اسرة القديس استفانوس"
  final String description; // Optional description
  final bool isActive;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const ClassMapping({
    required this.id,
    required this.classCode,
    required this.className,
    this.description = '',
    this.isActive = true,
    this.createdAt,
    this.updatedAt,
  });

  ClassMapping copyWith({
    String? id,
    String? classCode,
    String? className,
    String? description,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return ClassMapping(
      id: id ?? this.id,
      classCode: classCode ?? this.classCode,
      className: className ?? this.className,
      description: description ?? this.description,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'classCode': classCode,
      'className': className,
      'description': description,
      'isActive': isActive,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : FieldValue.serverTimestamp(),
    };
  }

  factory ClassMapping.fromMap(Map<String, dynamic> map, {required String id}) {
    return ClassMapping(
      id: id,
      classCode: map['classCode']?.toString() ?? '',
      className: map['className']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      isActive: map['isActive'] as bool? ?? true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: map['updatedAt'] is Timestamp
          ? (map['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ...toMap()};

  factory ClassMapping.fromJson(Map<String, dynamic> json) {
    return ClassMapping.fromMap(json, id: json['id']?.toString() ?? '');
  }

  @override
  String toString() {
    return 'ClassMapping(id: $id, classCode: $classCode, className: $className, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ClassMapping &&
        other.id == id &&
        other.classCode == classCode &&
        other.className == className &&
        other.isActive == isActive;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        classCode.hashCode ^
        className.hashCode ^
        isActive.hashCode;
  }
}

/// Service to manage class mappings
class ClassMappingService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static const String _collection = 'class_mappings';

  /// Get all class mappings
  static Stream<List<ClassMapping>> getClassMappings() {
    return _firestore
        .collection(_collection)
        .orderBy('classCode')
        .orderBy('className')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassMapping.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  /// Get class mappings for a specific class code
  static Stream<List<ClassMapping>> getClassMappingsByCode(String classCode) {
    return _firestore
        .collection(_collection)
        .where('classCode', isEqualTo: classCode)
        .where('isActive', isEqualTo: true)
        .orderBy('className')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassMapping.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  /// Get active class mappings only
  static Stream<List<ClassMapping>> getActiveClassMappings() {
    return _firestore
        .collection(_collection)
        .where('isActive', isEqualTo: true)
        .orderBy('classCode')
        .orderBy('className')
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => ClassMapping.fromMap(doc.data(), id: doc.id))
          .toList();
    });
  }

  /// Create a new class mapping
  static Future<String> createClassMapping(ClassMapping mapping) async {
    final docRef = await _firestore.collection(_collection).add(mapping.toMap());
    return docRef.id;
  }

  /// Update an existing class mapping
  static Future<void> updateClassMapping(String id, ClassMapping mapping) async {
    await _firestore.collection(_collection).doc(id).update({
      ...mapping.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Delete a class mapping
  static Future<void> deleteClassMapping(String id) async {
    await _firestore.collection(_collection).doc(id).delete();
  }

  /// Toggle class mapping active status
  static Future<void> toggleClassMappingStatus(String id, bool isActive) async {
    await _firestore.collection(_collection).doc(id).update({
      'isActive': isActive,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Get unique class codes
  static Future<List<String>> getUniqueClassCodes() async {
    final snapshot = await _firestore.collection(_collection).get();
    final codes = snapshot.docs
        .map((doc) => doc.data()['classCode']?.toString() ?? '')
        .where((code) => code.isNotEmpty)
        .toSet()
        .toList();
    codes.sort();
    return codes;
  }

  /// Get class mapping by ID
  static Future<ClassMapping?> getClassMappingById(String id) async {
    final doc = await _firestore.collection(_collection).doc(id).get();
    if (!doc.exists) return null;
    return ClassMapping.fromMap(doc.data()!, id: doc.id);
  }
}

