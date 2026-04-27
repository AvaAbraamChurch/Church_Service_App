import 'dart:convert';
import 'package:http/http.dart' as http;

Future<BulkCreateResult> bulkCreateUsers(List<BulkUserInput> users) async {
  final adminApiKey = const String.fromEnvironment('ADMIN_API_KEY', defaultValue: '');
  final response = await http.post(
    Uri.parse('https://pfytemzrsgcptoxqywjs.supabase.co/functions/v1/bulk-create-users'),
    headers: {
      'Content-Type': 'application/json',
      if (adminApiKey.isNotEmpty) 'apikey': adminApiKey,
      if (adminApiKey.isNotEmpty) 'Authorization': 'Bearer $adminApiKey',
    },
    body: jsonEncode({
      'users': users.map((u) => u.toJson()).toList(),
    }),
  );

  if (response.statusCode != 200) {
    final decoded = _tryDecodeJson(response.body);
    final error = decoded is Map<String, dynamic>
        ? (decoded['error']?.toString() ?? decoded['message']?.toString() ?? 'Unknown error')
        : 'Unknown error';
    throw Exception('Bulk creation failed: $error');
  }

  final decoded = _tryDecodeJson(response.body);
  if (decoded is! Map<String, dynamic>) {
    throw Exception('Bulk creation failed: Invalid response format');
  }
  final result = decoded;
  return BulkCreateResult.fromJson(result);
}

dynamic _tryDecodeJson(String body) {
  try {
    return jsonDecode(body);
  } catch (_) {
    return null;
  }
}

// Data models (simplified)
class BulkUserInput {
  final String name;
  final String? userType;
  final String? gender;
  final String? userClass;
  final String? serviceType;
  final String? phoneNumber;
  final String? address;
  final DateTime? birthday;

  BulkUserInput({
    required this.name,
    this.userType,
    this.gender,
    this.userClass,
    this.serviceType,
    this.phoneNumber,
    this.address,
    this.birthday,
  });

  factory BulkUserInput.fromJson(Map<String, dynamic> json) => BulkUserInput(
    name: (json['name'] ?? '').toString().trim(),
    userType: json['userType']?.toString(),
    gender: json['gender']?.toString(),
    userClass: json['userClass']?.toString(),
    serviceType: json['serviceType']?.toString(),
    phoneNumber: json['phoneNumber']?.toString(),
    address: json['address']?.toString(),
    birthday: json['birthday'] == null
        ? null
        : DateTime.tryParse(json['birthday'].toString()),
  );

  Map<String, dynamic> toJson() => {
    'name': name,
    if (userType != null) 'userType': userType,
    if (gender != null) 'gender': gender,
    if (userClass != null) 'userClass': userClass,
    if (serviceType != null) 'serviceType': serviceType,
    if (phoneNumber != null) 'phoneNumber': phoneNumber,
    if (address != null) 'address': address,
    if (birthday != null) 'birthday': birthday!.toIso8601String(),
  };
}

class BulkCreateResult {
  final List<CreatedUser> successful;
  final List<FailedUser> failed;
  final Summary summary;
  BulkCreateResult({required this.successful, required this.failed, required this.summary});
  factory BulkCreateResult.fromJson(Map<String, dynamic> json) => BulkCreateResult(
    successful: ((json['successful'] ?? const []) as List)
        .whereType<Map<String, dynamic>>()
        .map((u) => CreatedUser.fromJson(u))
        .toList(),
    failed: ((json['failed'] ?? const []) as List)
        .whereType<Map<String, dynamic>>()
        .map((f) => FailedUser.fromJson(f))
        .toList(),
    summary: Summary.fromJson((json['summary'] ?? const {}) as Map<String, dynamic>),
  );
}

class CreatedUser {
  final String name, email, password, uid, username;
  CreatedUser({required this.name, required this.email, required this.password, required this.uid, required this.username});
  factory CreatedUser.fromJson(Map<String, dynamic> json) => CreatedUser(
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    password: (json['password'] ?? '').toString(),
    uid: (json['uid'] ?? '').toString(),
    username: (json['username'] ?? '').toString(),
  );
}

class FailedUser {
  final String name, email, error;
  FailedUser({required this.name, required this.email, required this.error});
  factory FailedUser.fromJson(Map<String, dynamic> json) => FailedUser(
    name: (json['name'] ?? '').toString(),
    email: (json['email'] ?? '').toString(),
    error: (json['error'] ?? '').toString(),
  );
}

class Summary {
  final int total, success, failed;
  Summary({required this.total, required this.success, required this.failed});
  factory Summary.fromJson(Map<String, dynamic> json) => Summary(
    total: (json['total'] as num?)?.toInt() ?? 0,
    success: (json['success'] as num?)?.toInt() ?? 0,
    failed: (json['failed'] as num?)?.toInt() ?? 0,
  );
}