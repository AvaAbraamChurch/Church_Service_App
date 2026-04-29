import 'package:cloud_firestore/cloud_firestore.dart';

class GroupChatModel {
  final String? id;
  final String groupName;
  final String createdBy;
  final List<String> memberIds;
  final DateTime? createdAt;
  final DateTime? lastMessageAt;
  final String? lastMessage;
  final String? lastMessageSenderId;

  // ← NEW: Auto class-group support
  final bool isDefault;        // true = auto-generated class group
  final String? userClass;     // class identifier for default groups

  GroupChatModel({
    this.id,
    required this.groupName,
    required this.createdBy,
    required this.memberIds,
    this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSenderId,
    this.isDefault = false,           // ← Default: false (manual groups)
    this.userClass,                   // ← Optional: only set for default groups
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'lastMessageAt': lastMessageAt != null
          ? Timestamp.fromDate(lastMessageAt!)
          : null,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
      // ← NEW fields
      'isDefault': isDefault,
      'userClass': userClass,
    };
  }

  // Create from Firestore document (with backward compatibility)
  factory GroupChatModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupChatModel(
      id: documentId,
      groupName: map['groupName'] ?? '',
      createdBy: map['createdBy'] ?? '',
      memberIds: List<String>.from(map['memberIds'] ?? []),
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      lastMessageAt: map['lastMessageAt'] != null
          ? (map['lastMessageAt'] as Timestamp).toDate()
          : null,
      lastMessage: map['lastMessage'],
      lastMessageSenderId: map['lastMessageSenderId'],
      // ← Backward-compatible defaults for existing docs
      isDefault: map['isDefault'] ?? false,
      userClass: map['userClass'] as String?,
    );
  }

  factory GroupChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupChatModel.fromMap(data, doc.id);
  }

  // ← Helper: Generate deterministic ID for auto class-groups
  static String generateClassGroupId(String userClass) {
    // Remove Arabic/English non-alphanumeric, lowercase, trim
    final sanitized = userClass
        .replaceAll(RegExp(r'[^a-zA-Z0-9_\u0600-\u06FF]'), '_') // ← Allow Arabic chars if needed
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'_+'), '_'); // Collapse multiple underscores

    return 'class_group_$sanitized';
  }

  GroupChatModel copyWith({
    String? id,
    String? groupName,
    String? createdBy,
    List<String>? memberIds,
    DateTime? createdAt,
    DateTime? lastMessageAt,
    String? lastMessage,
    String? lastMessageSenderId,
    bool? isDefault,
    String? userClass,
  }) {
    return GroupChatModel(
      id: id ?? this.id,
      groupName: groupName ?? this.groupName,
      createdBy: createdBy ?? this.createdBy,
      memberIds: memberIds ?? this.memberIds,
      createdAt: createdAt ?? this.createdAt,
      lastMessageAt: lastMessageAt ?? this.lastMessageAt,
      lastMessage: lastMessage ?? this.lastMessage,
      lastMessageSenderId: lastMessageSenderId ?? this.lastMessageSenderId,
      isDefault: isDefault ?? this.isDefault,
      userClass: userClass ?? this.userClass,
    );
  }

  // ← Helper: Check if this is a default class group
  bool get isClassGroup => isDefault && userClass != null;

  // ← Helper: Equality check (for deduplication)
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is GroupChatModel && id != null && id == other.id;

  @override
  int get hashCode => id?.hashCode ?? Object.hash(groupName, createdBy, createdAt);

  @override
  String toString() {
    return 'GroupChatModel(id: $id, groupName: $groupName, memberCount: ${memberIds.length}, isDefault: $isDefault, userClass: $userClass)';
  }
}