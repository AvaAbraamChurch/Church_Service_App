import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../models/messages/message_model.dart';
import '../utils/userType_enum.dart';

class MessagesRepository {
  final FirebaseFirestore _firestore;
  static const String _messagesCollection = 'messages';

  MessagesRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ← Helper: Deterministic conversation ID
  String _generateConversationId(String uid1, String uid2) {
    final ids = [uid1, uid2]..sort();
    return '${ids[0]}_${ids[1]}';
  }

  /// Send message with permission guard + conversationId
  Future<String> sendMessage(MessageModel message) async {
    if (message.senderId != message.receiverId) {
      final senderDoc = await _firestore.collection('users').doc(message.senderId).get();
      final receiverDoc = await _firestore.collection('users').doc(message.receiverId).get();

      if (!senderDoc.exists || !receiverDoc.exists) throw Exception('Invalid user ID');

      final senderData = senderDoc.data()!;
      final receiverData = receiverDoc.data()!;

      final senderType = UserType.values.firstWhere((e) => e.code == senderData['userType']);
      final receiverType = UserType.values.firstWhere((e) => e.code == receiverData['userType']);

      // ← CRITICAL: Check SENDER type, not receiver
      if (senderType == UserType.child) {
        final senderClass = senderData['userClass']?.toString() ?? '';
        final receiverClass = receiverData['userClass']?.toString() ?? '';

        final canMessage = receiverType == UserType.priest ||
            (receiverType == UserType.servant && receiverClass == senderClass);

        if (!canMessage) {
          throw Exception('Permission denied: Child users can only message priests or same-class servants');
        }
      }
      // ← Non-child senders have no restrictions (adjust per your business logic)
    }

    final conversationId = _generateConversationId(message.senderId, message.receiverId);
    final docRef = await _firestore.collection(_messagesCollection).add({
      ...message.toMap(),
      'conversationId': conversationId,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  /// Get conversation messages - OPTIMIZED with conversationId index
  Stream<List<MessageModel>> getConversation({
    required String userId1,
    required String userId2,
    int limit = 50,
    DocumentSnapshot? lastDoc,
    bool includeMetadata = false,
  }) {
    final conversationId = _generateConversationId(userId1, userId2);
    Query query = _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (lastDoc != null) query = query.startAfterDocument(lastDoc);

    return query.snapshots().map((snapshot) {
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;
      final messages = docs.map((doc) => MessageModel.fromDocument(doc)).toList();
      // Dedupe
      final seen = <String>{};
      return messages.where((msg) => seen.add(msg.id ?? '')).toList();
    }).handleError((error) {
      debugPrint('❌ getConversation error: $error');
      return <MessageModel>[];
    });
  }

  /// Get user's conversations list - OPTIMIZED: query by senderId/receiverId compound
  Stream<List<MessageModel>> getUserMessages(String userId, {int limit = 100}) {
    return _firestore
        .collection(_messagesCollection)
        .where('participants', arrayContains: userId) // ← Single efficient query
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => MessageModel.fromDocument(doc))
        .toList())
        .handleError((_) => <MessageModel>[]);
  }

  /// Get last message in conversation - OPTIMIZED: single query by conversationId
  Future<MessageModel?> getLastMessage({required String userId1, required String userId2}) async {
    final conversationId = _generateConversationId(userId1, userId2);
    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .orderBy('timestamp', descending: true)
        .limit(1)
        .get();

    return snapshot.docs.isNotEmpty ? MessageModel.fromDocument(snapshot.docs.first) : null;
  }

  /// Delete conversation - OPTIMIZED: batched deletes by conversationId
  Future<void> deleteConversation({required String userId1, required String userId2}) async {
    final conversationId = _generateConversationId(userId1, userId2);
    Query query = _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId);

    while (true) {
      final snapshot = await query.limit(500).get(); // Firestore batch limit
      if (snapshot.docs.isEmpty) break;

      final batch = _firestore.batch();
      for (final doc in snapshot.docs) batch.delete(doc.reference);
      await batch.commit();
    }
  }

  /// Mark conversation as seen - OPTIMIZED: query by conversationId + receiver
  Future<void> markConversationAsSeen({required String currentUserId, required String otherUserId}) async {
    final conversationId = _generateConversationId(currentUserId, otherUserId);
    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('conversationId', isEqualTo: conversationId)
        .where('receiverId', isEqualTo: currentUserId)
        .where('isSeen', isEqualTo: false)
        .get();

    if (snapshot.docs.isEmpty) return;
    final batch = _firestore.batch();
    for (final doc in snapshot.docs) batch.update(doc.reference, {'isSeen': true});
    await batch.commit();
  }

  /// Get unread message count for a user (1:1 conversations only)
  Stream<int> getUnreadMessageCount(String userId) {
    try {
      return _firestore
          .collection(_messagesCollection)
          .where('receiverId', isEqualTo: userId)
          .where('isSeen', isEqualTo: false)
          .snapshots()
          .map((snapshot) => snapshot.docs.length);
    } catch (e) {
      debugPrint('❌ getUnreadMessageCount error: $e');
      return Stream.value(0); // Fallback to avoid UI crash
    }
  }



  Future<int> backfillParticipants() async {
    int count = 0;
    var batch = _firestore.batch();

    final snapshot = await _firestore
        .collection(_messagesCollection)
        .where('participants', isEqualTo: null)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final senderId = data['senderId'] as String?;
      final receiverId = data['receiverId'] as String?;

      if (senderId != null && receiverId != null) {
        final participants = [senderId, receiverId]..sort();
        batch.update(doc.reference, {'participants': participants});
        count++;
        if (count % 500 == 0) {
          await batch.commit();
          batch = _firestore.batch();
        }
      }
    }
    if (count % 500 != 0) await batch.commit();

    debugPrint('✅ Backfilled $count messages with participants array');
    return count;
  }






// ← Keep other methods (getUnreadMessages, searchMessages, etc.) but add conversationId filter where applicable
// Note: searchMessages requires external search service (Algolia) for production-scale text search
}