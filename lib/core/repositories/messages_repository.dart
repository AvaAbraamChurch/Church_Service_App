import 'package:church/core/constants/functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/messages/message_model.dart';

class MessagesRepository {
  final FirebaseFirestore _firestore;

  // Collection reference
  static const String _messagesCollection = 'messages';

  MessagesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Send a new message
  Future<String> sendMessage(MessageModel message) async {
    try {
      final docRef = await _firestore
          .collection(_messagesCollection)
          .add(message.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send message: $e');
    }
  }

  // Get messages between two users (real-time stream)
  Stream<List<MessageModel>> getConversation({
    required String userId1,
    required String userId2,
    int? limit,
  }) {
    try {
      Query query = _firestore
          .collection(_messagesCollection)
          .where('senderId', whereIn: [userId1, userId2])
          .where('receiverId', whereIn: [userId1, userId2])
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromDocument(doc))
            .where((message) =>
                (message.senderId == userId1 && message.receiverId == userId2) ||
                (message.senderId == userId2 && message.receiverId == userId1))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get conversation: $e');
    }
  }

  // Get all messages for a specific user (as sender or receiver)
  Stream<List<MessageModel>> getUserMessages(String userId, {int? limit}) {
    try {
      Query query = _firestore
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromDocument(doc))
            .where((message) =>
                message.senderId == userId || message.receiverId == userId)
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get user messages: $e');
    }
  }

  // Get unread messages for a user
  Stream<List<MessageModel>> getUnreadMessages(String userId) {
    try {
      return _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isSeen', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs.map((doc) => MessageModel.fromDocument(doc)).toList();
      });
    } catch (e) {
      throw Exception('Failed to get unread messages: $e');
    }
  }

  // Get unread message count for a user
  Stream<int> getUnreadMessageCount(String userId) {
    try {
      return _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isSeen', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      throw Exception('Failed to get unread message count: $e');
    }
  }

  // Mark a message as seen
  Future<void> markMessageAsSeen(String messageId) async {
    try {
      await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .update({'isSeen': true});
    } catch (e) {
      throw Exception('Failed to mark message as seen: $e');
    }
  }

  // Mark all messages in a conversation as seen
  Future<void> markConversationAsSeen({
    required String currentUserId,
    required String otherUserId,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: otherUserId)
          .where('receiverId', isEqualTo: currentUserId)
          .where('isSeen', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {'isSeen': true});
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark conversation as seen: $e');
    }
  }

  // Delete a message
  Future<void> deleteMessage(String messageId) async {
    try {
      await _firestore.collection(_messagesCollection).doc(messageId).delete();
    } catch (e) {
      throw Exception('Failed to delete message: $e');
    }
  }

  // Get a single message by ID
  Future<MessageModel?> getMessageById(String messageId) async {
    try {
      final doc = await _firestore
          .collection(_messagesCollection)
          .doc(messageId)
          .get();

      if (doc.exists) {
        return MessageModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get message: $e');
    }
  }

  // Get recent conversations for a user (list of users they've chatted with)
  Future<List<String>> getRecentConversations(String userId, {int limit = 20}) async {
    try {
      final sentMessages = await _firestore
          .collection(_messagesCollection)
          .where('senderId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final receivedMessages = await _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      final Set<String> conversations = {};

      for (var doc in sentMessages.docs) {
        final message = MessageModel.fromDocument(doc);
        conversations.add(message.receiverId);
      }

      for (var doc in receivedMessages.docs) {
        final message = MessageModel.fromDocument(doc);
        conversations.add(message.senderId);
      }

      return conversations.toList();
    } catch (e) {
      throw Exception('Failed to get recent conversations: $e');
    }
  }

  // Get last message in a conversation
  Future<MessageModel?> getLastMessage({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(50)
          .get();

      for (var doc in querySnapshot.docs) {
        final message = MessageModel.fromDocument(doc);
        if ((message.senderId == userId1 && message.receiverId == userId2) ||
            (message.senderId == userId2 && message.receiverId == userId1)) {
          return message;
        }
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get last message: $e');
    }
  }

  // Delete all messages in a conversation
  Future<void> deleteConversation({
    required String userId1,
    required String userId2,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        final message = MessageModel.fromDocument(doc);
        if ((message.senderId == userId1 && message.receiverId == userId2) ||
            (message.senderId == userId2 && message.receiverId == userId1)) {
          batch.delete(doc.reference);
        }
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete conversation: $e');
    }
  }

  // Search messages by text content
  Future<List<MessageModel>> searchMessages({
    required String userId,
    required String searchText,
    int limit = 50,
  }) async {
    try {
      final querySnapshot = await _firestore
          .collection(_messagesCollection)
          .orderBy('timestamp', descending: true)
          .limit(limit * 2)
          .get();

      final messages = querySnapshot.docs
          .map((doc) => MessageModel.fromDocument(doc))
          .where((message) =>
              (message.senderId == userId || message.receiverId == userId) &&
              normalizeArabic(message.text.toLowerCase()).contains(normalizeArabic(searchText.toLowerCase())))
          .take(limit)
          .toList();

      return messages;
    } catch (e) {
      throw Exception('Failed to search messages: $e');
    }
  }

  // Get messages by type
  Stream<List<MessageModel>> getMessagesByType({
    required String userId1,
    required String userId2,
    required MessageType messageType,
  }) {
    try {
      return _firestore
          .collection(_messagesCollection)
          .where('type', isEqualTo: messageType.name)
          .orderBy('timestamp', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => MessageModel.fromDocument(doc))
            .where((message) =>
                (message.senderId == userId1 && message.receiverId == userId2) ||
                (message.senderId == userId2 && message.receiverId == userId1))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get messages by type: $e');
    }
  }
}

