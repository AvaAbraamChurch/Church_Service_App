import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType {
  text,
  image,
  voice,
}

class MessageModel {
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final DateTime? timestamp;
  final bool isSeen;

  MessageModel({
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    this.timestamp,
    this.isSeen = false,
  });

  // Convert MessageModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': timestamp != null ? Timestamp.fromDate(timestamp!) : FieldValue.serverTimestamp(),
      'isSeen': isSeen,
    };
  }

  // Create MessageModel from Firestore document
  factory MessageModel.fromMap(Map<String, dynamic> map) {
    return MessageModel(
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      isSeen: map['isSeen'] ?? false,
    );
  }

  // Create MessageModel from Firestore DocumentSnapshot
  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return MessageModel.fromMap(data);
  }

  // Helper method to parse MessageType from string
  static MessageType _parseMessageType(dynamic type) {
    if (type == null) return MessageType.text;

    if (type is String) {
      switch (type.toLowerCase()) {
        case 'text':
          return MessageType.text;
        case 'image':
          return MessageType.image;
        case 'voice':
          return MessageType.voice;
        default:
          return MessageType.text;
      }
    }
    return MessageType.text;
  }

  // Create a copy of MessageModel with updated fields
  MessageModel copyWith({
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    bool? isSeen,
  }) {
    return MessageModel(
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
    );
  }

  @override
  String toString() {
    return 'MessageModel(senderId: $senderId, receiverId: $receiverId, text: $text, type: ${type.name}, timestamp: $timestamp, isSeen: $isSeen)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is MessageModel &&
      other.senderId == senderId &&
      other.receiverId == receiverId &&
      other.text == text &&
      other.type == type &&
      other.timestamp == timestamp &&
      other.isSeen == isSeen;
  }

  @override
  int get hashCode {
    return senderId.hashCode ^
      receiverId.hashCode ^
      text.hashCode ^
      type.hashCode ^
      timestamp.hashCode ^
      isSeen.hashCode;
  }
}
