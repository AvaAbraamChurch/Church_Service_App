import 'package:church/core/utils/service_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
/// - userClass
/// - serviceType (enum)
/// - profileImageUrl (optional)
/// - couponPoints
/// - createdAt
/// - updatedAt
/// - firstLogin boolean always true when created
class UserModel {
  final String id;
  final String fullName;
  final String username;
  final String email;
  final String? phoneNumber;
  final String? address;
  final UserType userType;
  final Gender gender;
  final String userClass;
  final ServiceType serviceType;
  final String? profileImageUrl;
  final int couponPoints;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool firstLogin;
  final DateTime? birthday;

  const UserModel({
    required this.id,
    required this.fullName,
    required this.username,
    required this.email,
    required this.userType,
    required this.gender,
    required this.userClass,
    required this.serviceType,
    this.phoneNumber,
    this.address,
    this.profileImageUrl,
    this.couponPoints = 0,
    this.createdAt,
    this.updatedAt,
    this.firstLogin = true,
    this.birthday,
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
    ServiceType? serviceType,
    String? profileImageUrl,
    int? couponPoints,
    bool? firstLogin,
    DateTime? birthday,
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
      serviceType: serviceType ?? this.serviceType,
      profileImageUrl: profileImageUrl ?? this.profileImageUrl,
      couponPoints: couponPoints ?? this.couponPoints,
      firstLogin: firstLogin ?? this.firstLogin,
      birthday: birthday ?? this.birthday,
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
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'couponPoints': couponPoints,
      // Store enums as short codes for compactness and consistency
      'userType': userType.code, // e.g., 'PR','SS','SV','CH'
      'gender': gender.code, // 'M' or 'F'
      'class': userClass,
      'serviceType': serviceType.key, // e.g., 'primary_boys'
      'firstLogin': firstLogin,
      if (birthday != null) 'birthday': Timestamp.fromDate(birthday!),
    };
  }

  factory UserModel.fromMap(Map<String, dynamic>? map, {required String id}) {
    final data = map ?? const <String, dynamic>{};
    DateTime? birthdayValue;
    if (data['birthday'] != null) {
      if (data['birthday'] is Timestamp) {
        birthdayValue = (data['birthday'] as Timestamp).toDate();
      } else if (data['birthday'] is String) {
        birthdayValue = DateTime.tryParse(data['birthday']);
      }
    }
    return UserModel(
      id: id,
      fullName: (data['fullName'] ?? data['name'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? data['phone'])?.toString(),
      address: (data['address'] ?? data['addr'])?.toString(),
      profileImageUrl: (data['profileImageUrl'])?.toString(),
      userType: userTypeFromJson(data['userType']),
      gender: genderFromJson(data['gender']),
      userClass: (data['class'] ?? data['userClass'])!.toString(),
      serviceType: serviceTypeFromJson(data['serviceType']),
      couponPoints: (data['couponPoints'] ?? 0) as int,
      firstLogin: (data['firstLogin'] ?? true) as bool,
      birthday: birthdayValue,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ...toMap()};

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json, id: (json['id'] ?? '').toString());
  }

  @override
  String toString() {
    return 'UserModel(id: $id, fullName: $fullName, username: $username, email: $email, phoneNumber: ${phoneNumber ?? 'null'}, address: ${address ?? 'null'}, userType: ${userType.code}, gender: ${gender.code}, userClass: $userClass, couponPoints: $couponPoints, profileImageUrl: ${profileImageUrl ?? 'null'}, firstLogin: $firstLogin, birthday: ${birthday ?? 'null'})';
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
        other.userClass == userClass &&
        other.profileImageUrl == profileImageUrl &&
        other.couponPoints == couponPoints &&
        other.firstLogin == firstLogin &&
        other.birthday == birthday;
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
    profileImageUrl,
    couponPoints,
    firstLogin,
    birthday,
  );

  static fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return UserModel.fromMap(snapshot.data(), id: snapshot.id);
  }
}
