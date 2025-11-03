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

  GroupChatModel({
    this.id,
    required this.groupName,
    required this.createdBy,
    required this.memberIds,
    this.createdAt,
    this.lastMessageAt,
    this.lastMessage,
    this.lastMessageSenderId,
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupName': groupName,
      'createdBy': createdBy,
      'memberIds': memberIds,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : FieldValue.serverTimestamp(),
      'lastMessageAt': lastMessageAt != null ? Timestamp.fromDate(lastMessageAt!) : null,
      'lastMessage': lastMessage,
      'lastMessageSenderId': lastMessageSenderId,
    };
  }

  // Create from Firestore document
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
    );
  }

  factory GroupChatModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupChatModel.fromMap(data, doc.id);
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
    );
  }
}

