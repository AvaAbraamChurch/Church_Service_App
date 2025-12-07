import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/messages/message_model.dart';
import '../../core/models/messages/group_chat_model.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/messages_repository.dart';
import '../../core/repositories/group_chat_repository.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/styles/colors.dart';
import '../../core/styles/themeScaffold.dart';
import 'chat_screen.dart';
import 'group_chat_screen.dart';
import 'user_selection_screen.dart';
import '../../shared/avatar_display_widget.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final MessagesRepository _messagesRepository = MessagesRepository();
  final GroupChatRepository _groupChatRepository = GroupChatRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final TextEditingController _searchController = TextEditingController();
  String? _currentUserId;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    if (_currentUserId == null) {
      return ThemedScaffold(
        appBar: _buildAppBar(),
        body: const Center(
          child: Text(
            'يجب تسجيل الدخول أولاً',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    return ThemedScaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Conversations List - Flexible for better keyboard handling
          Flexible(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesRepository.getUserMessages(_currentUserId!),
              builder: (context, messagesSnapshot) {
                return StreamBuilder<List<GroupChatModel>>(
                  stream: _searchQuery.isEmpty
                      ? _groupChatRepository.getUserGroupChats(_currentUserId!)
                      : _groupChatRepository.searchUserGroupChats(_currentUserId!, _searchQuery),
                  builder: (context, groupsSnapshot) {
                    if (messagesSnapshot.connectionState == ConnectionState.waiting ||
                        groupsSnapshot.connectionState == ConnectionState.waiting) {
                      return const Center(
                        child: CircularProgressIndicator(color: teal300),
                      );
                    }

                    if (messagesSnapshot.hasError || groupsSnapshot.hasError) {
                      return Center(
                        child: Text(
                          'حدث خطأ في تحميل المحادثات',
                          style: TextStyle(color: red300, fontSize: 16),
                        ),
                      );
                    }

                    final messages = messagesSnapshot.data ?? [];
                    final groupChats = groupsSnapshot.data ?? [];

                    // Group messages by conversation
                    final Map<String, MessageModel> conversations = {};
                    for (var message in messages) {
                      final otherUserId = message.senderId == _currentUserId
                          ? message.receiverId
                          : message.senderId;

                      if (!conversations.containsKey(otherUserId) ||
                          (message.timestamp != null &&
                              conversations[otherUserId]!.timestamp != null &&
                              message.timestamp!.isAfter(conversations[otherUserId]!.timestamp!))) {
                        conversations[otherUserId] = message;
                      }
                    }

                    // Apply search filter for individual conversations
                    List<MapEntry<String, MessageModel>> filteredConversations = conversations.entries.toList();
                    if (_searchQuery.isNotEmpty) {
                      filteredConversations = filteredConversations.where((entry) {
                        // This will be filtered by user name in the tile builder
                        return true; // We'll filter in the FutureBuilder
                      }).toList();
                    }

                    if (conversations.isEmpty && groupChats.isEmpty) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              _searchQuery.isNotEmpty ? Icons.search_off : Icons.chat_bubble_outline_rounded,
                              size: 100,
                              color: teal300.withValues(alpha: 0.3),
                            ),
                            const SizedBox(height: 20),
                            Text(
                              _searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا توجد محادثات',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.8),
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              _searchQuery.isNotEmpty ? 'جرب البحث بكلمات أخرى' : 'ابدأ محادثة جديدة الآن',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.5),
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    // Combine and sort all conversations
                    final List<Widget> allConversations = [];

                    // Add group chats
                    for (var group in groupChats) {
                      allConversations.add(_buildGroupConversationTile(context, group));
                    }

                    // Add individual conversations
                    final conversationsList = filteredConversations
                      ..sort((a, b) {
                        if (a.value.timestamp == null) return 1;
                        if (b.value.timestamp == null) return -1;
                        return b.value.timestamp!.compareTo(a.value.timestamp!);
                      });

                    for (var entry in conversationsList) {
                      final otherUserId = entry.key;
                      final lastMessage = entry.value;
                      final isUnread = lastMessage.receiverId == _currentUserId && !lastMessage.isSeen;

                      allConversations.add(_buildConversationTile(
                        context,
                        otherUserId,
                        lastMessage,
                        isUnread,
                      ));
                    }

                    return ListView(
                      padding: const EdgeInsets.symmetric(vertical: 8),
                      children: allConversations,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.startFloat,
      floatingActionButton: keyboardVisible ? null : Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [teal300, teal700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: teal500.withValues(alpha: 0.5),
              blurRadius: 15,
              offset: const Offset(0, 5),
              spreadRadius: 1,
            ),
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          shape: const CircleBorder(),
          child: InkWell(
            onTap: () async {
              if (_currentUserId == null) return;

              try {
                // Fetch current user data
                final currentUser = await _usersRepository.getUserById(_currentUserId!);

                if (!mounted) return;

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => UserSelectionScreen(
                      currentUser: currentUser,
                    ),
                  ),
                );
              } catch (e) {
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('حدث خطأ: ${e.toString()}'),
                    backgroundColor: red500,
                  ),
                );
              }
            },
            borderRadius: BorderRadius.circular(28),
            child: Container(
              width: 56,
              height: 56,
              alignment: Alignment.center,
              child: const Icon(
                Icons.add_comment,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: teal300.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _searchController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'ابحث في المحادثات أو المجموعات...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          icon: Icon(Icons.search, color: teal300),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: Icon(Icons.clear, color: teal300),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                    });
                  },
                )
              : null,
        ),
        onChanged: (value) {
          setState(() {
            _searchQuery = value.toLowerCase().trim();
          });
        },
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(80),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              teal700.withValues(alpha: 0.95),
              teal900.withValues(alpha: 0.95),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 20,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Row(
              children: [
                // Modern icon with background
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.white,
                    size: 26,
                  ),
                ),
                const SizedBox(width: 14),
                // Title with subtitle
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      'المحادثات',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    StreamBuilder<int>(
                      stream: _currentUserId != null
                          ? _messagesRepository.getUnreadMessageCount(_currentUserId!)
                          : const Stream.empty(),
                      builder: (context, snapshot) {
                        final unreadCount = snapshot.data ?? 0;
                        if (unreadCount == 0) {
                          return Text(
                            'لا توجد رسائل جديدة',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.7),
                              fontSize: 12,
                              fontWeight: FontWeight.w400,
                            ),
                          );
                        }
                        return Text(
                          '$unreadCount ${unreadCount == 1 ? 'رسالة جديدة' : 'رسائل جديدة'}',
                          style: TextStyle(
                            color: teal100,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const Spacer(),
                // Modern badge
                StreamBuilder<int>(
                  stream: _currentUserId != null
                      ? _messagesRepository.getUnreadMessageCount(_currentUserId!)
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    if (unreadCount == 0) return const SizedBox.shrink();

                    return Container(
                      constraints: const BoxConstraints(minWidth: 32),
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [red500, red700],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: red500.withValues(alpha: 0.4),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Text(
                        unreadCount > 99 ? '99+' : unreadCount.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupConversationTile(BuildContext context, GroupChatModel group) {
    // Filter by search query
    if (_searchQuery.isNotEmpty && !group.groupName.toLowerCase().contains(_searchQuery)) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [teal700.withValues(alpha: 0.3), teal900.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: teal300.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => GroupChatScreen(
                  groupId: group.id!,
                  groupName: group.groupName,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 60,
                  height: 60,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [teal500, teal700],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 30),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              group.groupName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (group.lastMessageAt != null)
                            Text(
                              _formatMessageTime(group.lastMessageAt),
                              style: TextStyle(
                                color: teal100,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(
                            Icons.people,
                            size: 16,
                            color: Colors.white.withValues(alpha: 0.6),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '${group.memberIds.length} أعضاء',
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                              fontSize: 14,
                            ),
                          ),
                          if (group.lastMessage != null) ...[
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                ' • ${group.lastMessage}',
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.7),
                                  fontSize: 15,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildConversationTile(
    BuildContext context,
    String otherUserId,
    MessageModel lastMessage,
    bool isUnread,
  ) {
    final isMe = lastMessage.senderId == _currentUserId;

    return StreamBuilder<UserModel?>(
      stream: _usersRepository.getUserByIdStream(otherUserId),
      builder: (context, userSnapshot) {
        final otherUser = userSnapshot.data;
        final userName = otherUser?.fullName ?? 'مستخدم';
        final userImage = otherUser?.profileImageUrl;

        // Filter by search query
        if (_searchQuery.isNotEmpty && !userName.toLowerCase().contains(_searchQuery)) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUnread
                  ? [teal700.withValues(alpha: 0.3), teal900.withValues(alpha: 0.3)]
                  : [sage900.withValues(alpha: 0.3), sage700.withValues(alpha: 0.3)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? teal300.withValues(alpha: 0.5) : sage300.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ChattingScreen(
                      receiverId: otherUserId,
                      receiverName: userName,
                      receiverImageUrl: userImage,
                    ),
                  ),
                );
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Stack(
                      children: [
                        AvatarDisplayWidget(
                          user: otherUser,
                          imageUrl: userImage,
                          name: userName,
                          size: 60,
                          showBorder: false,
                        ),
                        if (isUnread)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                color: red500,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  userName,
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: isUnread ? FontWeight.bold : FontWeight.w600,
                                  ),
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              Text(
                                _formatMessageTime(lastMessage.timestamp),
                                style: TextStyle(
                                  color: isUnread ? teal100 : Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                  fontWeight: isUnread ? FontWeight.w600 : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              if (isMe)
                                Padding(
                                  padding: const EdgeInsets.only(right: 4),
                                  child: Icon(
                                    lastMessage.isSeen ? Icons.done_all : Icons.done,
                                    size: 16,
                                    color: lastMessage.isSeen
                                        ? teal100
                                        : Colors.white.withValues(alpha: 0.5),
                                  ),
                                ),
                              Expanded(
                                child: Text(
                                  lastMessage.text,
                                  style: TextStyle(
                                    color: isUnread
                                        ? Colors.white.withValues(alpha: 0.9)
                                        : Colors.white.withValues(alpha: 0.6),
                                    fontSize: 15,
                                    fontWeight: isUnread ? FontWeight.w500 : FontWeight.normal,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  String _formatMessageTime(DateTime? timestamp) {
    if (timestamp == null) return '';

    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inDays == 0) {
      return DateFormat('hh:mm a').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else {
      return DateFormat('dd/MM').format(timestamp);
    }
  }
}
