import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/messages/message_model.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/messages_repository.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/styles/colors.dart';
import '../../core/styles/themeScaffold.dart';
import 'chat_screen.dart';
import 'user_selection_screen.dart';

class ConversationsListScreen extends StatefulWidget {
  const ConversationsListScreen({super.key});

  @override
  State<ConversationsListScreen> createState() => _ConversationsListScreenState();
}

class _ConversationsListScreenState extends State<ConversationsListScreen> {
  final MessagesRepository _messagesRepository = MessagesRepository();
  final UsersRepository _usersRepository = UsersRepository();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
  }

  @override
  Widget build(BuildContext context) {
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
      body: StreamBuilder<List<MessageModel>>(
        stream: _messagesRepository.getUserMessages(_currentUserId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(color: teal300),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Text(
                'حدث خطأ في تحميل المحادثات',
                style: TextStyle(color: red300, fontSize: 16),
              ),
            );
          }

          final messages = snapshot.data ?? [];

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

          if (conversations.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 100,
                    color: teal300.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'لا توجد محادثات',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'ابدأ محادثة جديدة الآن',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            );
          }

          final conversationsList = conversations.entries.toList()
            ..sort((a, b) {
              if (a.value.timestamp == null) return 1;
              if (b.value.timestamp == null) return -1;
              return b.value.timestamp!.compareTo(a.value.timestamp!);
            });

          return ListView.builder(
            padding: const EdgeInsets.symmetric(vertical: 8),
            itemCount: conversationsList.length,
            itemBuilder: (context, index) {
              final entry = conversationsList[index];
              final otherUserId = entry.key;
              final lastMessage = entry.value;
              final isUnread = lastMessage.receiverId == _currentUserId && !lastMessage.isSeen;

              return _buildConversationTile(
                context,
                otherUserId,
                lastMessage,
                isUnread,
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
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
        backgroundColor: teal500,
        child: const Icon(Icons.add_comment, color: Colors.white),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [teal700.withValues(alpha: 0.9), teal900.withValues(alpha: 0.9)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.3),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                const Icon(Icons.chat_bubble_rounded, color: teal100, size: 28),
                const SizedBox(width: 12),
                const Text(
                  'المحادثات',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                StreamBuilder<int>(
                  stream: _currentUserId != null
                      ? _messagesRepository.getUnreadMessageCount(_currentUserId!)
                      : const Stream.empty(),
                  builder: (context, snapshot) {
                    final unreadCount = snapshot.data ?? 0;
                    if (unreadCount == 0) return const SizedBox.shrink();

                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: red500,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
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

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isUnread
                  ? [teal700.withValues(alpha: 0.3), teal900.withValues(alpha: 0.3)]
                  : [brown900.withValues(alpha: 0.2), brown700.withValues(alpha: 0.2)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isUnread ? teal300.withValues(alpha: 0.5) : Colors.white.withValues(alpha: 0.1),
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
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: brown300,
                          backgroundImage: userImage != null
                              ? NetworkImage(userImage)
                              : null,
                          child: userImage == null
                              ? Text(
                                  userName[0].toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
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
      return DateFormat('HH:mm').format(timestamp);
    } else if (difference.inDays == 1) {
      return 'أمس';
    } else if (difference.inDays < 7) {
      return '${difference.inDays} أيام';
    } else {
      return DateFormat('dd/MM').format(timestamp);
    }
  }
}

