import 'package:cloud_firestore/cloud_firestore.dart';

enum MessageType { text, image, voice }

class MessageModel {
  final String? id; // ← Firestore document ID for deduplication
  final String senderId;
  final String receiverId;
  final String text;
  final MessageType type;
  final DateTime? timestamp;
  final bool isSeen;
  final String conversationId; // ← Critical: deterministic conversation ID

  MessageModel({
    this.id,
    required this.senderId,
    required this.receiverId,
    required this.text,
    required this.type,
    this.timestamp,
    this.isSeen = false,
    required this.conversationId, // ← Required param
  });

  Map<String, dynamic> toMap() {
    final participants = [senderId, receiverId]..sort(); // Deterministic order
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'text': text,
      'type': type.name,
      'timestamp': timestamp != null
          ? Timestamp.fromDate(timestamp!)
          : FieldValue.serverTimestamp(),
      'isSeen': isSeen,
      'conversationId': conversationId,
      'participants': participants, // ← NEW: array for array-contains query
    };
  }

  factory MessageModel.fromMap(Map<String, dynamic> map, String documentId) {
    return MessageModel(
      id: documentId,
      senderId: map['senderId'] ?? '',
      receiverId: map['receiverId'] ?? '',
      text: map['text'] ?? '',
      type: _parseMessageType(map['type']),
      timestamp: map['timestamp'] != null
          ? (map['timestamp'] as Timestamp).toDate()
          : null,
      isSeen: map['isSeen'] ?? false,
      conversationId: map['conversationId'] ?? _generateFallbackConversationId(
          map['senderId'] ?? '',
          map['receiverId'] ?? ''
      ), // ← Backward compat
    );
  }

  factory MessageModel.fromDocument(DocumentSnapshot doc) {
    return MessageModel.fromMap(doc.data() as Map<String, dynamic>, doc.id);
  }

  static MessageType _parseMessageType(dynamic type) {
    if (type is String) {
      return MessageType.values.firstWhere(
            (e) => e.name == type.toLowerCase(),
        orElse: () => MessageType.text,
      );
    }
    return MessageType.text;
  }

  // ← Helper: Generate deterministic conversationId (same for both directions)
  static String _generateFallbackConversationId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  MessageModel copyWith({
    String? id,
    String? senderId,
    String? receiverId,
    String? text,
    MessageType? type,
    DateTime? timestamp,
    bool? isSeen,
    String? conversationId,
  }) {
    return MessageModel(
      id: id ?? this.id,
      senderId: senderId ?? this.senderId,
      receiverId: receiverId ?? this.receiverId,
      text: text ?? this.text,
      type: type ?? this.type,
      timestamp: timestamp ?? this.timestamp,
      isSeen: isSeen ?? this.isSeen,
      conversationId: conversationId ?? this.conversationId,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
          other is MessageModel && id != null && other.id != null && id == other.id;

  @override
  int get hashCode => id?.hashCode ?? Object.hash(senderId, receiverId, timestamp);
}