import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/messages/group_chat_model.dart';
import '../models/messages/group_message_model.dart';
import '../utils/userType_enum.dart';

class GroupChatRepository {
  final FirebaseFirestore _firestore;
  static const String _groupChatsCollection = 'groupChats';
  static const String _groupMessagesCollection = 'groupMessages';

  GroupChatRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  // ← Create group with deterministic ID (for auto class-groups)
  Future<String> createGroupChatWithId(GroupChatModel groupChat) async {
    if (groupChat.id == null) {
      throw Exception('ID required for createGroupChatWithId');
    }
    try {
      await _firestore
          .collection(_groupChatsCollection)
          .doc(groupChat.id)
          .set(groupChat.toMap());
      return groupChat.id!;
    } catch (e) {
      throw Exception('Failed to create group chat with ID: $e');
    }
  }



  // ← Auto class-group: create if missing, ensure user is member
  Future<void> ensureUserInClassGroup({
    required String userId,
    required String userClass,
    required String createdBy,
  }) async {
    final groupId = GroupChatModel.generateClassGroupId(userClass);

    // 1. Create group if missing
    final existing = await getGroupChatById(groupId);
    if (existing == null) {
      final newGroup = GroupChatModel(
        id: groupId,
        groupName: 'مجموعة $userClass',
        createdBy: createdBy,
        memberIds: [userId], // Start with creator
        createdAt: DateTime.now(),
        isDefault: true,
        userClass: userClass,
      );
      await createGroupChatWithId(newGroup);

      // ← NEW: Populate with existing users of same class
      await _populateClassGroupMembers(groupId, userClass);
    } else {
      // Ensure current user is member (idempotent)
      if (!existing.memberIds.contains(userId)) {
        await addMembersToGroup(groupId, [userId]);
      }
    }
  }

  /// Fetch all child/servant users with matching userClass & add to group
  Future<void> _populateClassGroupMembers(String groupId, String userClass) async {
    try {
      // Query users by class (requires Firestore index: userClass ASC)
      final snapshot = await _firestore
          .collection('users')
          .where('userClass', isEqualTo: userClass)
          .limit(1000) // Safety limit; adjust if classes exceed this
          .get();

      final eligibleIds = <String>[];
      for (final doc in snapshot.docs) {
        final data = doc.data();
        final typeCode = data['userType'] as String?;
        // Only children & servants belong to auto class groups
        if (typeCode == UserType.child.code || typeCode == UserType.servant.code) {
          eligibleIds.add(doc.id);
        }
      }

      if (eligibleIds.isEmpty) return;

      // arrayUnion is idempotent & handles duplicates safely
      await _firestore.collection('groupChats').doc(groupId).update({
        'memberIds': FieldValue.arrayUnion(eligibleIds),
      });

      debugPrint('✅ Populated $groupId with ${eligibleIds.length} class members');
    } catch (e) {
      debugPrint('⚠️ Failed to populate class group members: $e');
      // Non-fatal: group still works, current user is already member
    }
  }

  // Create a new group chat (original method - keeps auto ID)
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

  // Get user's group chats - OPTIMIZED: default groups first
  Stream<List<GroupChatModel>> getUserGroupChats(String userId) {
    return _firestore
        .collection(_groupChatsCollection)
        .where('memberIds', arrayContains: userId)
        .orderBy('isDefault', descending: true)
        .orderBy('lastMessageAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GroupChatModel.fromDocument(doc))
        .toList())
        .handleError((e) {
      debugPrint('❌ getUserGroupChats error: $e');
      return <GroupChatModel>[];
    });
  }

  // Get groups filtered by userClass
  Stream<List<GroupChatModel>> getGroupsByUserClass(String userClass) {
    return _firestore
        .collection(_groupChatsCollection)
        .where('userClass', isEqualTo: userClass)
        .where('isDefault', isEqualTo: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
        .map((doc) => GroupChatModel.fromDocument(doc))
        .toList());
  }

  // Get a specific group chat by ID
  Future<GroupChatModel?> getGroupChatById(String groupId) async {
    try {
      final doc = await _firestore
          .collection(_groupChatsCollection)
          .doc(groupId)
          .get();
      return doc.exists ? GroupChatModel.fromDocument(doc) : null;
    } catch (e) {
      debugPrint('❌ getGroupChatById error: $e');
      return null;
    }
  }

  // Get group chat by ID as stream
  Stream<GroupChatModel?> getGroupChatByIdStream(String groupId) {
    return _firestore
        .collection(_groupChatsCollection)
        .doc(groupId)
        .snapshots()
        .map((doc) => doc.exists ? GroupChatModel.fromDocument(doc) : null)
        .handleError((_) => null);
  }

  // Update group chat
  Future<void> updateGroupChat(String groupId, Map<String, dynamic> updates) async {
    await _firestore.collection(_groupChatsCollection).doc(groupId).update(updates);
  }

  // Delete group chat - FIXED: manual batch operation counting
  Future<void> deleteGroupChat(String groupId) async {
    await _firestore.collection(_groupChatsCollection).doc(groupId).delete();

    Query query = _firestore
        .collection(_groupMessagesCollection)
        .where('groupId', isEqualTo: groupId);

    while (true) {
      final snapshot = await query.limit(500).get();
      if (snapshot.docs.isEmpty) break;

      var batch = _firestore.batch();
      int batchOps = 0; // ← Manual counter

      for (final doc in snapshot.docs) {
        batch.delete(doc.reference);
        batchOps++;

        // ← Manual check (not operationsCount)
        if (batchOps >= 500) {
          await batch.commit();
          batch = _firestore.batch(); // ← New instance
          batchOps = 0; // ← Reset counter
        }
      }

      if (batchOps > 0) await batch.commit();
    }
  }

  // Send a message to a group
  Future<String> sendGroupMessage(GroupMessageModel message) async {
    try {
      final docRef = await _firestore
          .collection(_groupMessagesCollection)
          .add(message.toMap());

      // Update group last message (non-critical if fails)
      await _firestore.collection(_groupChatsCollection).doc(message.groupId).update({
        'lastMessage': message.text,
        'lastMessageAt': FieldValue.serverTimestamp(),
        'lastMessageSenderId': message.senderId,
      }).catchError((e) => debugPrint('⚠️ Group metadata update failed: $e'));

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to send group message: $e');
    }
  }

  // Get messages for a group - with pagination
  Stream<List<GroupMessageModel>> getGroupMessages(
      String groupId, {
        int limit = 50,
        DocumentSnapshot? lastDoc,
      }) {
    Query query = _firestore
        .collection(_groupMessagesCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(limit + 1);

    if (lastDoc != null) query = query.startAfterDocument(lastDoc);

    return query.snapshots().map((snapshot) {
      final hasMore = snapshot.docs.length > limit;
      final docs = hasMore ? snapshot.docs.sublist(0, limit) : snapshot.docs;
      return docs.map((doc) => GroupMessageModel.fromDocument(doc)).toList();
    }).handleError((_) => <GroupMessageModel>[]);
  }

  // Mark group message as seen by user
  Future<void> markGroupMessageAsSeen(String messageId, String userId) async {
    await _firestore
        .collection(_groupMessagesCollection)
        .doc(messageId)
        .update({'seenBy.$userId': true});
  }

  // Mark ALL group messages as seen - client-side filter (Firestore limitation)
  Future<void> markGroupMessagesAsSeen(String groupId, String userId) async {
    final snapshot = await _firestore
        .collection(_groupMessagesCollection)
        .where('groupId', isEqualTo: groupId)
        .orderBy('timestamp', descending: true)
        .limit(100)
        .get();

    var batch = _firestore.batch();
    int batchOps = 0; // ← Manual counter

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final seenBy = Map<String, dynamic>.from(data['seenBy'] ?? {});
      if (seenBy[userId] != true) {
        batch.update(doc.reference, {'seenBy.$userId': true});
        batchOps++;

        if (batchOps >= 500) {
          await batch.commit();
          batch = _firestore.batch();
          batchOps = 0;
        }
      }
    }
    if (batchOps > 0) await batch.commit();
  }

  // Add members to group (idempotent)
  Future<void> addMembersToGroup(String groupId, List<String> memberIds) async {
    await _firestore.collection(_groupChatsCollection).doc(groupId).update({
      'memberIds': FieldValue.arrayUnion(memberIds),
    });
  }

  // Remove member from group
  Future<void> removeMemberFromGroup(String groupId, String memberId) async {
    await _firestore.collection(_groupChatsCollection).doc(groupId).update({
      'memberIds': FieldValue.arrayRemove([memberId]),
    });
  }

  // Search groups by name for a user - client-side filter
  Stream<List<GroupChatModel>> searchUserGroupChats(String userId, String searchQuery) {
    return _firestore
        .collection(_groupChatsCollection)
        .where('memberIds', arrayContains: userId)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs
          .map((doc) => GroupChatModel.fromDocument(doc))
          .where((group) =>
          group.groupName.toLowerCase().contains(searchQuery.toLowerCase()))
          .toList()
        ..sort((a, b) {
          if (a.lastMessageAt == null && b.lastMessageAt == null) return 0;
          if (a.lastMessageAt == null) return 1;
          if (b.lastMessageAt == null) return -1;
          return b.lastMessageAt!.compareTo(a.lastMessageAt!);
        });
    });
  }

  // ← Migration helper: backfill isDefault/userClass fields
  Future<int> backfillGroupChatFields() async {
    int count = 0;
    var batch = _firestore.batch();
    int batchOps = 0; // ← Manual counter

    final snapshot = await _firestore
        .collection('groupChats')
        .where('isDefault', isEqualTo: null)
        .get();

    for (final doc in snapshot.docs) {
      final data = doc.data();
      final groupName = data['groupName'] as String?;

      if (groupName?.startsWith('مجموعة ') == true) {
        final userClass = groupName!.substring('مجموعة '.length);
        batch.update(doc.reference, {
          'isDefault': true,
          'userClass': userClass,
        });
      } else {
        batch.update(doc.reference, {'isDefault': false});
      }

      count++;
      batchOps++;

      if (batchOps >= 500) {
        await batch.commit();
        batch = _firestore.batch();
        batchOps = 0;
        await Future.delayed(const Duration(milliseconds: 100)); // Rate limit
      }
    }

    if (batchOps > 0) await batch.commit();
    debugPrint('✅ Backfilled $count group chats with isDefault/userClass');
    return count;
  }

  Future<int> backfillExistingClassGroups() async {
    int updatedCount = 0;

    // Find all default class groups
    final groupsSnapshot = await _firestore
        .collection('groupChats')
        .where('isDefault', isEqualTo: true)
        .get();

    for (final groupDoc in groupsSnapshot.docs) {
      final data = groupDoc.data();
      final userClass = data['userClass'] as String?;
      if (userClass == null) continue;

      final groupId = groupDoc.id;
      await _populateClassGroupMembers(groupId, userClass);
      updatedCount++;
    }

    debugPrint('✅ Backfilled $updatedCount existing class groups');
    return updatedCount;
  }
}