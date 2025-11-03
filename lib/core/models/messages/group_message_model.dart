import 'package:cloud_firestore/cloud_firestore.dart';

enum GroupMessageType {
  text,
  image,
  voice,
  system, // For system messages like "User joined" etc.
}

class GroupMessageModel {
  final String? id;
  final String groupId;
  final String senderId;
  final String text;
  final GroupMessageType type;
  final DateTime? timestamp;
  final Map<String, bool> seenBy; // userId -> seen status

  GroupMessageModel({
    this.id,
    required this.groupId,
    required this.senderId,
    required this.text,
    required this.type,
    this.timestamp,
    this.seenBy = const {},
  });

  // Convert to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'groupId': groupId,
      'senderId': senderId,
      'text': text,
      'type': type.name,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'seenBy': seenBy,
    };
  }

  // Create from Firestore document
  factory GroupMessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return GroupMessageModel(
      id: documentId,
      groupId: map['groupId'] ?? '',
      senderId: map['senderId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      seenBy: Map<String, bool>.from(map['seenBy'] ?? {}),
    );
  }

  factory GroupMessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return GroupMessageModel.fromMap(data, doc.id);
  }

  static GroupMessageType _parseMessageType(dynamic type) {
    if (type == null) return GroupMessageType.text;

    if (type is String) {
      switch (type.toLowerCase()) {
        case 'text':
          return GroupMessageType.text;
        case 'image':
          return GroupMessageType.image;
        case 'voice':
          return GroupMessageType.voice;
        case 'system':
          return GroupMessageType.system;
        default:
          return GroupMessageType.text;
      }
    }
    return GroupMessageType.text;
  }

  GroupMessageModel copyWith({
    String? id,
    String? groupId,
    String? senderId,
    String? text,
    GroupMessageType? type,
    DateTime? timestamp,
    Map<String, bool>? seenBy,
  }) {
    return GroupMessageModel(
      id: id ?? this.id,
      groupId: groupId ?? this.groupId,
      senderId: senderId ?? this.senderId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      seenBy: seenBy ?? this.seenBy,
    );
  }
}

