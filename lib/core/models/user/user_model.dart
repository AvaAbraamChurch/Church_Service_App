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
/// - fcmToken (optional)
/// - couponPoints
/// - createdAt
/// - updatedAt
/// - firstLogin boolean always true when created
/// - isAdmin boolean for admin privileges
/// - storeAdmin boolean for store management privileges
/// - isActive boolean for account enabled/disabled status
class UserModel {
  final String id;
  final String shortId;
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
  final String? avatar; // SVG string of the avatar
  final String? fcmToken;
  final int couponPoints;
  final int clubCoins; // New field for club coins
  final String cardStatus; // New field for card status
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final bool firstLogin;
  final DateTime? birthday;
  final bool isAdmin;
  final bool storeAdmin;
  final bool isActive;

  const UserModel({
    required this.id,
    required this.shortId,
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
    this.avatar,
    this.fcmToken,
    this.couponPoints = 0,
    this.clubCoins = 0,
    this.cardStatus = 'active', // Default to 'active' for new users
    this.createdAt,
    this.updatedAt,
    this.firstLogin = true,
    this.birthday,
    this.isAdmin = false,
    this.storeAdmin = false,
    this.isActive = true,
  });

  UserModel copyWith({
    String? id,
    String? shortId,
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
    String? avatar,
    String? fcmToken,
    int? couponPoints,
    int? clubCoins,
    String? cardStatus,
    bool? firstLogin,
    DateTime? birthday,
    bool? isAdmin,
    bool? storeAdmin,
    bool? isActive,
  }) {
    return UserModel(
      id: id ?? this.id,
      shortId: shortId ?? this.shortId,
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
      avatar: avatar ?? this.avatar,
      fcmToken: fcmToken ?? this.fcmToken,
      couponPoints: couponPoints ?? this.couponPoints,
      clubCoins: clubCoins ?? this.clubCoins,
      cardStatus: cardStatus ?? this.cardStatus,
      firstLogin: firstLogin ?? this.firstLogin,
      birthday: birthday ?? this.birthday,
      isAdmin: isAdmin ?? this.isAdmin,
      storeAdmin: storeAdmin ?? this.storeAdmin,
      isActive: isActive ?? this.isActive,
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
      if (avatar != null) 'avatar': avatar,
      if (fcmToken != null) 'fcm_token': fcmToken,
      'couponPoints': couponPoints,
      'clubCoins': clubCoins,
      'cardStatus': cardStatus,
      // Store enums as short codes for compactness and consistency
      'userType': userType.code, // e.g., 'PR','SS','SV','CH'
      'gender': gender.code, // 'M' or 'F'
      // Persist using 'userClass' key going forward. fromMap still supports legacy 'class'.
      'userClass': userClass,
      'serviceType': serviceType.key, // e.g., 'primary_boys'
      'firstLogin': firstLogin,
      'isAdmin': isAdmin,
      'storeAdmin': storeAdmin,
      'isActive': isActive,
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
      shortId: id.length > 6 ? id.substring(0, 6) : id,
      fullName: (data['fullName'] ?? data['name'] ?? '').toString(),
      username: (data['username'] ?? '').toString(),
      email: (data['email'] ?? '').toString(),
      phoneNumber: (data['phoneNumber'] ?? data['phone'])?.toString(),
      address: (data['address'] ?? data['addr'])?.toString(),
      profileImageUrl: (data['profileImageUrl'])?.toString(),
      avatar: (data['avatar'])?.toString(),
      fcmToken: (data['fcm_token'] ?? data['fcmToken'])?.toString(),
      userType: userTypeFromJson(data['userType']),
      gender: genderFromJson(data['gender']),
      userClass: (data['userClass'] ?? data['class'] ?? '').toString(),
      serviceType: serviceTypeFromJson(data['serviceType']),
      couponPoints: (data['couponPoints'] ?? 0) as int,
      clubCoins: (data['clubCoins'] ?? 0) as int,
      cardStatus: (data['cardStatus'] ?? 'active').toString(),
      firstLogin: (data['firstLogin'] ?? true) as bool,
      birthday: birthdayValue,
      isAdmin: (data['isAdmin'] ?? false) as bool,
      storeAdmin: (data['storeAdmin'] ?? false) as bool,
      isActive: (data['isActive'] ?? true) as bool,
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ...toMap()};

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel.fromMap(json, id: (json['id'] ?? '').toString());
  }

  @override
  String toString() {
    return 'UserModel(id: $id, shortId: $shortId, fullName: $fullName, username: $username, email: $email, phoneNumber: ${phoneNumber ?? 'null'}, address: ${address ?? 'null'}, userType: ${userType.code}, gender: ${gender.code}, userClass: $userClass, couponPoints: $couponPoints, clubCoins: $clubCoins, cardStatus: $cardStatus, profileImageUrl: ${profileImageUrl ?? 'null'}, fcmToken: ${fcmToken ?? 'null'}, firstLogin: $firstLogin, birthday: ${birthday ?? 'null'})';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserModel &&
        other.id == id &&
        other.shortId == shortId &&
        other.fullName == fullName &&
        other.username == username &&
        other.email == email &&
        other.phoneNumber == phoneNumber &&
        other.address == address &&
        other.userType == userType &&
        other.gender == gender &&
        other.userClass == userClass &&
        other.profileImageUrl == profileImageUrl &&
        other.avatar == avatar &&
        other.fcmToken == fcmToken &&
        other.couponPoints == couponPoints &&
        other.clubCoins == clubCoins &&
        other.cardStatus == cardStatus &&
        other.firstLogin == firstLogin &&
        other.birthday == birthday &&
        other.isAdmin == isAdmin &&
        other.storeAdmin == storeAdmin &&
        other.isActive == isActive;
  }

  @override
  int get hashCode => Object.hash(
    id,
    shortId,
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
    clubCoins,
    cardStatus,
    fcmToken,
    firstLogin,
    birthday,
    isAdmin,
    storeAdmin,
  );

  static fromDocumentSnapshot(DocumentSnapshot<Map<String, dynamic>> snapshot) {
    return UserModel.fromMap(snapshot.data(), id: snapshot.id);
  }
}
