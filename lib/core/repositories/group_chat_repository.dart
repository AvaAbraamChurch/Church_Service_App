import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/messages/group_chat_model.dart';
import '../models/messages/group_message_model.dart';

class GroupChatRepository {
  final FirebaseFirestore _firestore;

  static const String _groupChatsCollection = 'groupChats';
  static const String _groupMessagesCollection = 'groupMessages';

  GroupChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // Create a new group chat
  Future<String> createGroupChat(GroupChatModel groupChat) async {
    try {
      final docRef = await _firestore
          .collection(_groupChatsCollection)
          .add(groupChat.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create group chat: $e');
    }
  }

  // Get all group chats for a user
  Stream<List<GroupChatModel>> getUserGroupChats(String userId) {
    try {
      return _firestore
          .collection(_groupChatsCollection)
          .where('memberIds', arrayContains: userId)
          .orderBy('lastMessageAt', descending: true)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupChatModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get user group chats: $e');
    }
  }

  // Get a specific group chat by ID
  Future<GroupChatModel?> getGroupChatById(String groupId) async {
    try {
      final doc = await _firestore
          .collection(_groupChatsCollection)
          .doc(groupId)
          .get();

      if (doc.exists) {
        return GroupChatModel.fromDocument(doc);
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get group chat: $e');
    }
  }

  // Get group chat by ID as stream
  Stream<GroupChatModel?> getGroupChatByIdStream(String groupId) {
    try {
      return _firestore
          .collection(_groupChatsCollection)
          .doc(groupId)
          .snapshots()
          .map((doc) {
        if (doc.exists) {
          return GroupChatModel.fromDocument(doc);
        }
        return null;
      });
    } catch (e) {
      throw Exception('Failed to get group chat stream: $e');
    }
  }

  // Update group chat
  Future<void> updateGroupChat(String groupId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(_groupChatsCollection)
          .doc(groupId)
          .update(updates);
    } catch (e) {
      throw Exception('Failed to update group chat: $e');
    }
  }

  // Delete group chat
  Future<void> deleteGroupChat(String groupId) async {
    try {
      // Delete the group chat document
      await _firestore.collection(_groupChatsCollection).doc(groupId).delete();

      // Delete all messages in the group
      final messagesSnapshot = await _firestore
          .collection(_groupMessagesCollection)
          .where('groupId', isEqualTo: groupId)
          .get();

      final batch = _firestore.batch();
      for (var doc in messagesSnapshot.docs) {
        batch.delete(doc.reference);
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete group chat: $e');
    }
  }

  // Send a message to a group
  Future<String> sendGroupMessage(GroupMessageModel message) async {
    try {
      // Add the message
      final docRef = await _firestore
          .collection(_groupMessagesCollection)
          .add(message.toMap());

      // Update group's last message info
      await _firestore.collection(_groupChatsCollection).doc(message.groupId).update({
        'lastMessage': message.text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': message.senderId,
      });

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  // Get messages for a group
  Stream<List<GroupMessageModel>> getGroupMessages(String groupId, {int? limit}) {
    try {
      Query query = _firestore
          .collection(_groupMessagesCollection)
          .where('groupId', isEqualTo: groupId)
          .orderBy('timestamp', descending: true);

      if (limit != null) {
        query = query.limit(limit);
      }

      return query.snapshots().map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupMessageModel.fromDocument(doc))
            .toList();
      });
    } catch (e) {
      throw Exception('Failed to get group messages: $e');
    }
  }

  // Mark group message as seen by user
  Future<void> markGroupMessageAsSeen(String messageId, String userId) async {
    try {
      await _firestore
          .collection(_groupMessagesCollection)
          .doc(messageId)
          .update({
        'seenBy.$userId': true,
      });
    } catch (e) {
      throw Exception('Failed to mark group message as seen: $e');
    }
  }

  // Mark all group messages as seen by user
  Future<void> markGroupMessagesAsSeen(String groupId, String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_groupMessagesCollection)
          .where('groupId', isEqualTo: groupId)
          .where('seenBy.$userId', isEqualTo: false)
          .get();

      final batch = _firestore.batch();
      for (var doc in querySnapshot.docs) {
        batch.update(doc.reference, {
          'seenBy.$userId': true,
        });
      }
      await batch.commit();
    } catch (e) {
      throw Exception('Failed to mark group messages as seen: $e');
    }
  }

  // Get unread group message count for user
  Stream<int> getUnreadGroupMessageCount(String userId) {
    try {
      return getUserGroupChats(userId).asyncMap((groups) async {
        int totalUnread = 0;
        for (var group in groups) {
          if (group.id != null) {
            final unreadCount = await _getUnreadCountForGroup(group.id!, userId);
            totalUnread += unreadCount;
          }
        }
        return totalUnread;
      });
    } catch (e) {
      throw Exception('Failed to get unread group message count: $e');
    }
  }

  Future<int> _getUnreadCountForGroup(String groupId, String userId) async {
    try {
      final snapshot = await _firestore
          .collection(_groupMessagesCollection)
          .where('groupId', isEqualTo: groupId)
          .where('senderId', isNotEqualTo: userId)
          .get();

      int count = 0;
      for (var doc in snapshot.docs) {
        final message = GroupMessageModel.fromDocument(doc);
        if (message.seenBy[userId] != true) {
          count++;
        }
      }
      return count;
    } catch (e) {
      return 0;
    }
  }

  // Add members to group
  Future<void> addMembersToGroup(String groupId, List<String> memberIds) async {
    try {
      await _firestore.collection(_groupChatsCollection).doc(groupId).update({
        'memberIds': FieldValue.arrayUnion(memberIds),
      });
    } catch (e) {
      throw Exception('Failed to add members to group: $e');
    }
  }

  // Remove member from group
  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    try {
      await _firestore.collection(_groupChatsCollection).doc(groupId).update({
        'memberIds': FieldValue.arrayRemove([memberId]),
      });
    } catch (e) {
      throw Exception('Failed to remove member from group: $e');
    }
  }

  // Search groups by name for a user
  Stream<List<GroupChatModel>> searchUserGroupChats(String userId, String searchQuery) {
    try {
      return _firestore
          .collection(_groupChatsCollection)
          .where('memberIds', arrayContains: userId)
          .snapshots()
          .map((snapshot) {
        return snapshot.docs
            .map((doc) => GroupChatModel.fromDocument(doc))
            .where((group) => group.groupName.toLowerCase().contains(searchQuery.toLowerCase()))
            .toList()
          ..sort((a, b) {
            if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
            if (a.lastMessageAt == null) return 1;
            if (b.lastMessageAt == null) return -1;
            return b.lastMessageAt!.compareTo(a.lastMessageAt!);
          });
      });
    } catch (e) {
      throw Exception('Failed to search group chats: $e');
    }
  }
}

