import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/service_enum.dart';

/// Model representing a user registration request pending admin approval
class RegistrationRequest {
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
  final DateTime requestedAt;
  final RegistrationStatus status;
  final String? rejectionReason;
  final String? reviewedBy; // Admin ID who reviewed the request
  final DateTime? reviewedAt;

  const RegistrationRequest({
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
    required this.requestedAt,
    this.status = RegistrationStatus.pending,
    this.rejectionReason,
    this.reviewedBy,
    this.reviewedAt,
  });

  RegistrationRequest copyWith({
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
    DateTime? requestedAt,
    RegistrationStatus? status,
    String? rejectionReason,
    String? reviewedBy,
    DateTime? reviewedAt,
  }) {
    return RegistrationRequest(
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
      requestedAt: requestedAt ?? this.requestedAt,
      status: status ?? this.status,
      rejectionReason: rejectionReason ?? this.rejectionReason,
      reviewedBy: reviewedBy ?? this.reviewedBy,
      reviewedAt: reviewedAt ?? this.reviewedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'fullName': fullName,
      'username': username,
      'email': email,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (address != null) 'address': address,
      if (profileImageUrl != null) 'profileImageUrl': profileImageUrl,
      'userType': userType.code,
      'gender': gender.code,
      // Use 'userClass' key instead of legacy 'class'
      'userClass': userClass,
      'serviceType': serviceType.key,
      'requestedAt': Timestamp.fromDate(requestedAt),
      'status': status.name,
      if (rejectionReason != null) 'rejectionReason': rejectionReason,
      if (reviewedBy != null) 'reviewedBy': reviewedBy,
      if (reviewedAt != null) 'reviewedAt': Timestamp.fromDate(reviewedAt!),
    };
  }

  factory RegistrationRequest.fromMap(Map<String, dynamic> map, {required String id}) {
    return RegistrationRequest(
      id: id,
      fullName: map['fullName']?.toString() ?? '',
      username: map['username']?.toString() ?? '',
      email: map['email']?.toString() ?? '',
      phoneNumber: map['phoneNumber']?.toString(),
      address: map['address']?.toString(),
      profileImageUrl: map['profileImageUrl']?.toString(),
      userType: userTypeFromJson(map['userType']),
      gender: genderFromJson(map['gender']),
      // Support legacy 'class' key while preferring 'userClass'
      userClass: (map['userClass'] ?? map['class'])?.toString() ?? '',
      serviceType: serviceTypeFromJson(map['serviceType']),
      requestedAt: (map['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      status: RegistrationStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => RegistrationStatus.pending,
      ),
      rejectionReason: map['rejectionReason']?.toString(),
      reviewedBy: map['reviewedBy']?.toString(),
      reviewedAt: (map['reviewedAt'] as Timestamp?)?.toDate(),
    );
  }

  Map<String, dynamic> toJson() => {'id': id, ...toMap()};

  factory RegistrationRequest.fromJson(Map<String, dynamic> json) {
    return RegistrationRequest.fromMap(json, id: json['id'] ?? '');
  }
}

enum RegistrationStatus {
  pending,
  approved,
  rejected,
}
