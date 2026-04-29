import 'package:church/core/utils/userType_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

import '../../core/models/messages/group_message_model.dart';
import '../../core/models/messages/group_chat_model.dart';
import '../../core/repositories/group_chat_repository.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/styles/colors.dart';
import '../../core/styles/themeScaffold.dart';
import '../../core/utils/link_utils.dart';
import '../../shared/avatar_display_widget.dart';

class GroupChatScreen extends StatefulWidget {
  final String groupId;
  final String groupName;

  const GroupChatScreen({
    super.key,
    required this.groupId,
    required this.groupName,
  });

  @override
  State<GroupChatScreen> createState() => _GroupChatScreenState();
}

class _GroupChatScreenState extends State<GroupChatScreen> {
  final GroupChatRepository _groupChatRepository = GroupChatRepository();
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
      _groupChatRepository.markGroupMessagesAsSeen(
        widget.groupId,
        _currentUserId!,
      );
    }
  }

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty || _currentUserId == null) {
      return;
    }

    final message = GroupMessageModel(
      groupId: widget.groupId,
      senderId: _currentUserId!,
      text: _messageController.text.trim(),
      type: GroupMessageType.text,
      timestamp: DateTime.now(),
      seenBy: {_currentUserId!: true},
    );

    _groupChatRepository.sendGroupMessage(message);
    _messageController.clear();

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

  void _copyMessageText(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'تم نسخ النص',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        backgroundColor: teal500,
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
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
          Expanded(
            child: StreamBuilder<List<GroupMessageModel>>(
              stream: _groupChatRepository.getGroupMessages(widget.groupId),
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
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: teal500.withValues(alpha: 0.3),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.group, color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: StreamBuilder<GroupChatModel?>(
                    stream: _groupChatRepository.getGroupChatByIdStream(
                      widget.groupId,
                    ),
                    builder: (context, snapshot) {
                      final group = snapshot.data;
                      final memberCount = group?.memberIds.length ?? 0;

                      return Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.groupName,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            '$memberCount أعضاء',
                            style: TextStyle(
                              color: teal100.withValues(alpha: 0.8),
                              fontSize: 12,
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_vert, color: Colors.white),
                  color: teal900,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  onSelected: (value) {
                    if (value == 'view_members') {
                      _showGroupMembers();
                    } else if (value == 'delete_group') {
                      _showDeleteGroupDialog();
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'view_members',
                      child: Row(
                        children: [
                          Icon(Icons.people, color: teal300, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'عرض الأعضاء',
                            style: TextStyle(color: Colors.white, fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'delete_group',
                      child: Row(
                        children: [
                          Icon(Icons.delete_sweep, color: red500, size: 20),
                          SizedBox(width: 12),
                          Text(
                            'حذف المجموعة',
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

  Widget _buildMessageBubble(GroupMessageModel message, bool isMe) {
    return FutureBuilder(
      future: _usersRepository.getUserById(message.senderId),
      builder: (context, snapshot) {
        final senderName = snapshot.data?.fullName ?? 'مستخدم';
        final senderImage = snapshot.data?.profileImageUrl;

        return Align(
          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.75,
            ),
            margin: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                if (!isMe) ...[
                  AvatarDisplayWidget(
                    user: snapshot.data,
                    imageUrl: senderImage,
                    name: senderName,
                    size: 32,
                    showBorder: false,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: GestureDetector(
                    onLongPress: () => _copyMessageText(message.text),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: isMe
                              ? [teal500, teal900]
                              : [
                                  sage700.withValues(alpha: 0.8),
                                  sage900.withValues(alpha: 0.8),
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
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!isMe)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                senderName,
                                style: TextStyle(
                                  color: teal100,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          LinkUtils.buildLinkifiedTextWidget(
                            text: message.text,
                            normalStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                            ),
                            linkStyle: TextStyle(
                              color: isMe ? teal100 : Colors.lightBlueAccent,
                              fontSize: 16,
                              decoration: TextDecoration.underline,
                              decorationColor: isMe
                                  ? teal100
                                  : Colors.lightBlueAccent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _formatTime(message.timestamp),
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 11,
                                ),
                              ),
                              if (isMe) ...[
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.done_all,
                                  size: 14,
                                  color: _getSeenIconColor(message),
                                ),
                              ],
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: sage900.withValues(alpha: 0.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: Row(
          children: [
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
                  maxLines: null,
                  decoration: InputDecoration(
                    hintText: 'اكتب رسالة...',
                    hintStyle: TextStyle(
                      color: Colors.white.withValues(alpha: 0.5),
                    ),
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            GestureDetector(
              onTap: _sendMessage,
              child: Container(
                padding: const EdgeInsets.all(12),
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
                child: const Icon(Icons.send, color: Colors.white, size: 24),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDateDivider(DateTime? timestamp) {
    if (timestamp == null) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 16),
      child: Row(
        children: [
          Expanded(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: sage700.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                _formatDate(timestamp),
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.7),
                  fontSize: 12,
                ),
              ),
            ),
          ),
          Expanded(
            child: Divider(
              color: Colors.white.withValues(alpha: 0.2),
              thickness: 1,
            ),
          ),
        ],
      ),
    );
  }

  bool _shouldShowTimestamp(List<GroupMessageModel> messages, int index) {
    if (index == messages.length - 1) return true;

    final currentMessage = messages[messages.length - 1 - index];
    final nextMessage = messages[messages.length - 2 - index];

    if (currentMessage.timestamp == null || nextMessage.timestamp == null) {
      return false;
    }

    return !_isSameDay(currentMessage.timestamp!, nextMessage.timestamp!);
  }

  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
        date1.month == date2.month &&
        date1.day == date2.day;
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
      return DateFormat('d MMMM y', 'ar').format(timestamp);
    }
  }

  String _formatTime(DateTime? timestamp) {
    if (timestamp == null) return '';
    return DateFormat('h:mm a', 'ar').format(timestamp);
  }

  Color _getSeenIconColor(GroupMessageModel message) {
    final seenCount = message.seenBy.values.where((seen) => seen).length;
    if (seenCount > 1) {
      return teal300; // Seen by others
    }
    return Colors.white.withValues(alpha: 0.5); // Only seen by sender
  }

  void _showGroupMembers() async {
    final group = await _groupChatRepository.getGroupChatById(widget.groupId);
    if (group == null || !mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: sage900,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'أعضاء المجموعة (${group.memberIds.length})',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: group.memberIds.length,
                  itemBuilder: (context, index) {
                    final userId = group.memberIds[index];
                    return FutureBuilder(
                      future: _usersRepository.getUserById(userId),
                      builder: (context, snapshot) {
                        final user = snapshot.data;
                        if (user == null) return const SizedBox.shrink();

                        return ListTile(
                          leading: AvatarDisplayWidget(
                            user: user,
                            imageUrl: user.profileImageUrl,
                            name: user.fullName,
                            size: 40,
                            showBorder: false,
                          ),
                          title: Text(
                            user.fullName,
                            style: const TextStyle(color: Colors.white),
                          ),
                          subtitle: Text(
                            user.userType.label,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                          ),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }





  void _showDeleteGroupDialog() {
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent accidental dismiss
      builder: (context) => AlertDialog(
        backgroundColor: sage900,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: red500, size: 28),
            const SizedBox(width: 12),
            const Text(
              'حذف المجموعة',
              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'هل أنت متأكد من حذف هذه المجموعة نهائياً؟',
              style: TextStyle(color: Colors.white, fontSize: 16),
            ),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: red500.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: red500.withValues(alpha: 0.3)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline, color: red300, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'سيتم حذف جميع الرسائل والأعضاء ولن يمكن استرجاعها.',
                      style: TextStyle(color: red300, fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'المجموعة: ${widget.groupName}',
              style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'إلغاء',
              style: TextStyle(color: teal300, fontSize: 16, fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context); // Close dialog first
              await _deleteGroup();
            },
            icon: const Icon(Icons.delete_sweep, size: 18),
            label: const Text('حذف', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            ),
          ),
        ],
        actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),
    );
  }



  Future<void> _deleteGroup() async {
    if (_currentUserId == null || !mounted) return;

    // ← Optional: Verify user is group creator (extra safety)
    try {
      final group = await _groupChatRepository.getGroupChatById(widget.groupId);
      if (group?.createdBy != _currentUserId) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('فقط منشئ المجموعة يمكنه حذفها'),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }
    } catch (e) {
      debugPrint('⚠️ Could not verify group creator: $e');
      // Continue with delete attempt - server rules will enforce
    }

    // Show loading overlay
    _showDeleteLoadingOverlay(context);

    try {
      await _groupChatRepository.deleteGroupChat(widget.groupId);

      if (mounted) {
        // Close loading overlay (root navigator to avoid dialog stack issues)
        Navigator.of(context, rootNavigator: true).pop();

        // Success feedback
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
                  child: const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'تم حذف المجموعة بنجاح',
                    style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: teal700,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 2),
            elevation: 8,
          ),
        );

        // Return to conversations list
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        // Close loading
        Navigator.of(context, rootNavigator: true).pop();

        // Error feedback with retry
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
                  child: const Icon(Icons.error_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'فشل الحذف: ${e.toString().replaceAll('Exception: ', '')}',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: red500,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            duration: const Duration(seconds: 4),
            elevation: 8,
            action: SnackBarAction(
              label: 'إعادة المحاولة',
              textColor: Colors.white,
              onPressed: () => _deleteGroup(),
            ),
          ),
        );
      }

      // Log for monitoring
      debugPrint('❌ Delete group error: $e');
      // Optional: FirebaseCrashlytics.instance.recordError(e, stackTrace);
    }
  }


  void _showDeleteLoadingOverlay(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black.withValues(alpha: 0.7),
      builder: (context) => Center(
        child: Dialog(
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.all(32),
            constraints: const BoxConstraints(maxWidth: 340),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [sage900.withValues(alpha: 0.95), sage700.withValues(alpha: 0.95)],
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
              border: Border.all(color: Colors.white.withValues(alpha: 0.1), width: 1.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.delete_sweep_rounded, color: red300, size: 40),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 40,
                  height: 40,
                  child: CircularProgressIndicator(color: teal300, strokeWidth: 3),
                ),
                const SizedBox(height: 24),
                const Text(
                  'جاري الحذف',
                  style: TextStyle(color: Colors.white, fontSize: 16, fontFamily: 'Alexandria'),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                Text(
                  'يرجى الانتظار',
                  style: TextStyle(color: teal100.withValues(alpha: 0.7), fontSize: 14, fontFamily: 'Alexandria'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }



}
