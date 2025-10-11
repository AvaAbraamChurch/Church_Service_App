import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';

/// Immutable user model representing an application user.
///
/// Fields:
/// - id (document id)
/// - fullName
/// - username
/// - email
/// - phoneNumber (optional)
/// - address (optional)
/// - userType (enum)
/// - gender (enum)
/// - userClass (named `userClass` to avoid Dart reserved word `class`)
class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? address;
  final UserType userType;
  final Gender gender;
  final String? userClass;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.userType,
    required this.gender,
    this.phoneNumber,
    this.address,
    this.userClass,
  });

  UserModel copyWith({
    String? id,
    String? fullName,
    String? username,
    String? email,
    String? phoneNumber,
    String? address,
    UserType? userType,
    Gender? gender,
    String? userClass,
  }) {
    return UserModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      username: username ?? this.username,
      email: email ?? this.email,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      address: address ?? this.address,
      userType: userType ?? this.userType,
      gender: gender ?? this.gender,
      userClass: userClass ?? this.userClass,
    );
  }

  // JSON/Map helpers (Firestore-friendly)
  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      // Store enums as short codes for compactness and consistency
      'userType': userTypeToJson(userType), // e.g., 'PR','SS','SV','CH'
      'gender': genderToJson(gender), // 'M' or 'F'
      if (userClass != null) 'class': userClass,
    };
  }

  factory UserModel.fromMap(Map<String, dynamic>? map, {required String id}) {
    final data = map ?? const <String, dynamic>{};
    return UserModel(
      id: id,
      fullName: (data['fullName'] ?? data['name'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? data['phone'])?.toString(),
      address: (data['address'] ?? data['addr'])?.toString(),
      userType: userTypeFromJson(data['userType']),
      gender: genderFromJson(data['gender'] ?? data['gender']),
      userClass: (data['class'] ?? data['userClass'])?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        ...toMap(),
      };

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json, id: (json['id'] ?? '').toString());
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, username: $username, email: $email, phoneNumber: ${phoneNumber ?? 'null'}, address: ${address ?? 'null'}, userType: ${userType.code}, gender: ${gender.code}, userClass: ${userClass ?? 'null'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.fullName == fullName &&
        other.username == username &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.userType == userType &&
        other.gender == gender &&
        other.userClass == userClass;
  }

  @override
  int get hashCode => Object.hash(
        id,
        fullName,
        username,
        email,
        phoneNumber,
        address,
        userType,
        gender,
        userClass,
      );
}
