import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/messages/message_model.dart';
import '../../core/repositories/messages_repository.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/styles/colors.dart';
import '../../core/styles/themeScaffold.dart';
import '../../shared/avatar_display_widget.dart';

class ChattingScreen extends StatefulWidget {
  final String receiverId;
  final String receiverName;
  final String? receiverImageUrl;

  const ChattingScreen({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.receiverImageUrl,
  });

  @override
  State<ChattingScreen> createState() => _ChattingScreenState();
}

class _ChattingScreenState extends State<ChattingScreen> {
  final MessagesRepository _messagesRepository = MessagesRepository();
  final UsersRepository _usersRepository = UsersRepository();
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _currentUserId = FirebaseAuth.instance.currentUser?.uid;
    _markMessagesAsRead();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _markMessagesAsRead() {
    if (_currentUserId != null) {
      _messagesRepository.markConversationAsSeen(
        currentUserId: _currentUserId!,
        otherUserId: widget.receiverId,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final message = MessageModel(
      senderId: _currentUserId!,
      receiverId: widget.receiverId,
      text: _messageController.text.trim(),
      type: MessageType.text,
      timestamp: DateTime.now(),
      isSeen: false,
    );

    _messagesRepository.sendMessage(message);
    _messageController.clear();

    // Scroll to bottom after sending
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_currentUserId == null) {
      return ThemedScaffold(
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
          // Messages List
          Expanded(
            child: StreamBuilder<List<MessageModel>>(
              stream: _messagesRepository.getConversation(
                userId1: _currentUserId!,
                userId2: widget.receiverId,
              ),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(color: teal300),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'حدث خطأ في تحميل الرسائل',
                      style: TextStyle(color: red300, fontSize: 16),
                    ),
                  );
                }

                final messages = snapshot.data ?? [];

                if (messages.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 80,
                          color: teal300.withValues(alpha: 0.3),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد رسائل بعد',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.7),
                            fontSize: 18,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'ابدأ المحادثة بإرسال رسالة',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Scroll to bottom when new messages arrive
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (_scrollController.hasClients) {
                    _scrollController.jumpTo(
                      _scrollController.position.maxScrollExtent,
                    );
                  }
                });

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 20,
                  ),
                  itemCount: messages.length,
                  reverse: false,
                  itemBuilder: (context, index) {
                    final message = messages[messages.length - 1 - index];
                    final isMe = message.senderId == _currentUserId;
                    final showTimestamp = _shouldShowTimestamp(messages, index);

                    return Column(
                      children: [
                        if (showTimestamp) _buildDateDivider(message.timestamp),
                        _buildMessageBubble(message, isMe),
                      ],
                    );
                  },
                );
              },
            ),
          ),

          // Message Input
          _buildMessageInput(),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              teal700.withValues(alpha: 0.9),
              teal900.withValues(alpha: 0.9),
            ],
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                // Live receiver avatar from Firestore
                StreamBuilder(
                  stream: _usersRepository.getUserByIdStream(widget.receiverId),
                  builder: (context, snapshot) {
                    final receiverUser = snapshot.data;
                    return AvatarDisplayWidget(
                      user: receiverUser,
                      imageUrl: widget.receiverImageUrl,
                      name: widget.receiverName,
                      size: 44,
                      showBorder: false,
                    );
                  },
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.receiverName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'نشط الآن',
                        style: TextStyle(
                          color: teal100.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: teal900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'delete_all') {
                      _showDeleteConversationDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'delete_all',
                      child: Row(
                        children: [
                          const Icon(
                            Icons.delete_sweep,
                            color: red500,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          const Text(
                            'حذف جميع الرسائل',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDeleteConversationDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: red500, size: 28),
            const SizedBox(width: 12),
            const Text(
              'تأكيد الحذف',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف جميع الرسائل في هذه المحادثة؟',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Text(
              'لن تتمكن من استرجاع الرسائل المحذوفة.',
              style: TextStyle(
                color: red300,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(
                color: teal300,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _deleteConversation();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
            child: const Text(
              'حذف',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteConversation() async {
    if (_currentUserId == null) return;

    try {
      // Show modern loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        barrierColor: Colors.black.withValues(alpha: 0.7),
        builder: (context) => Center(
          child: Dialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.8,
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 20),
                padding: const EdgeInsets.all(32),
                constraints: const BoxConstraints(maxWidth: 340),
                // Add max width constraint
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      teal900.withValues(alpha: 0.95),
                      teal700.withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 30,
                      offset: const Offset(0, 10),
                    ),
                  ],
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Animated container with icon
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.delete_sweep_rounded,
                        color: red300,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const SizedBox(
                      width: 40,
                      height: 40,
                      child: CircularProgressIndicator(
                        color: teal300,
                        strokeWidth: 3,
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'جاري الحذف',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontFamily: 'Alexandria',
                      ),
                      textAlign: TextAlign.center, // Add text alignment
                      maxLines: 2,
                      overflow:
                          TextOverflow.visible, // Ensure text doesn't overflow
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'يرجى الانتظار',
                      style: TextStyle(
                        color: teal100.withValues(alpha: 0.7),
                        fontSize: 14,
                        fontFamily: 'Alexandria',
                      ),
                      maxLines: 2,
                      textAlign: TextAlign.center, // Add text alignment
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

      await _messagesRepository.deleteConversation(
        userId1: _currentUserId!,
        userId2: widget.receiverId,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم حذف جميع الرسائل بنجاح',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: teal700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 2),
            elevation: 8,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.error_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'فشل حذف الرسائل: $e',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            backgroundColor: red500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 3),
            elevation: 8,
          ),
        );
      }
    }
  }

  Widget _buildMessageBubble(MessageModel message, bool isMe) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMe) ...[
            // Display receiver's avatar with Firestore support
            StreamBuilder(
              stream: _usersRepository.getUserByIdStream(widget.receiverId),
              builder: (context, snapshot) {
                final receiverUser = snapshot.data;
                return AvatarDisplayWidget(
                  user: receiverUser,
                  imageUrl: widget.receiverImageUrl,
                  name: widget.receiverName,
                  size: 32,
                  showBorder: false,
                );
              },
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                gradient: isMe
                    ? LinearGradient(
                        colors: [teal500, teal700],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : LinearGradient(
                        colors: [
                          sage600.withValues(alpha: 0.9),
                          sage900.withValues(alpha: 0.9),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(20),
                  topRight: const Radius.circular(20),
                  bottomLeft: Radius.circular(isMe ? 20 : 4),
                  bottomRight: Radius.circular(isMe ? 4 : 20),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.text,
                    style: const TextStyle(color: Colors.white, fontSize: 16),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        _formatTime(message.timestamp),
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.7),
                          fontSize: 11,
                        ),
                      ),
                      if (isMe) ...[
                        const SizedBox(width: 4),
                        Icon(
                          message.isSeen ? Icons.done_all : Icons.done,
                          size: 16,
                          color: message.isSeen
                              ? teal100
                              : Colors.white.withValues(alpha: 0.7),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ),
          if (isMe) const SizedBox(width: 8),
        ],
      ),
    );
  }

  Widget _buildDateDivider(DateTime? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: teal900.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(timestamp),
                style: TextStyle(
                  color: teal100,
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.3),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: teal900.withValues(alpha: 0.7),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 10,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Attachment button
            Container(
              decoration: BoxDecoration(
                color: teal700.withValues(alpha: 0.5),
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  // TODO: Implement attachment functionality
                },
                icon: const Icon(Icons.add, color: teal100),
              ),
            ),
            const SizedBox(width: 12),

            // Text input field
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(color: teal300.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  controller: _messageController,
                  style: const TextStyle(color: Colors.white, fontSize: 16),
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  maxLines: null,
                  textInputAction: TextInputAction.send,
                  onSubmitted: (_) => _sendMessage(),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Send button
            Container(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [teal500, teal700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: teal500.withValues(alpha: 0.5),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: IconButton(
                onPressed: _sendMessage,
                icon: const Icon(Icons.send_rounded, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  bool _shouldShowTimestamp(List<MessageModel> messages, int index) {
    if (index == 0) return true;

    final currentIndex = messages.length - 1 - index;
    final previousIndex = messages.length - index;

    // Check if indices are valid
    if (currentIndex < 0 ||
        currentIndex >= messages.length ||
        previousIndex < 0 ||
        previousIndex >= messages.length) {
      return false;
    }

    final currentMessage = messages[currentIndex];
    final previousMessage = messages[previousIndex];

    if (currentMessage.timestamp == null || previousMessage.timestamp == null) {
      return false;
    }

    return !_isSameDay(currentMessage.timestamp!, previousMessage.timestamp!);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('hh:mm a').format(timestamp);
  }

  String _formatDate(DateTime timestamp) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(
      timestamp.year,
      timestamp.month,
      timestamp.day,
    );

    if (messageDate == today) {
      return 'اليوم';
    } else if (messageDate == yesterday) {
      return 'أمس';
    } else {
      return DateFormat('dd/MM/yyyy').format(timestamp);
    }
  }
}
