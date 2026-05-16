import 'package:cloud_firestore/cloud_firestore.dart';

class AttendanceService {
  final String id;
  final String name;
  final String nameAr;
  final int coinsValue;

  const AttendanceService({
    required this.id,
    required this.name,
    required this.nameAr,
    required this.coinsValue,
  });

  factory AttendanceService.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return AttendanceService(
      id: doc.id,
      name: data['name'] ?? '',
      nameAr: data['nameAr'] ?? '',
      coinsValue: (data['coinsValue'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
        'name': name,
        'nameAr': nameAr,
        'coinsValue': coinsValue,
      };

  AttendanceService copyWith({
    String? id,
    String? name,
    String? nameAr,
    int? coinsValue,
  }) =>
      AttendanceService(
        id: id ?? this.id,
        name: name ?? this.name,
        nameAr: nameAr ?? this.nameAr,
        coinsValue: coinsValue ?? this.coinsValue,
      );
}
