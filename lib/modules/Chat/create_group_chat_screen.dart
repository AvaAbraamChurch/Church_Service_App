import 'package:church/core/utils/gender_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../core/models/messages/group_chat_model.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/group_chat_repository.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/styles/colors.dart';
import '../../core/styles/themeScaffold.dart';
import '../../core/utils/userType_enum.dart';
import '../../shared/avatar_display_widget.dart';
import 'group_chat_screen.dart';

class CreateGroupChatScreen extends StatefulWidget {
  final UserModel currentUser;

  const CreateGroupChatScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<CreateGroupChatScreen> createState() => _CreateGroupChatScreenState();
}

class _CreateGroupChatScreenState extends State<CreateGroupChatScreen> {
  final UsersRepository _usersRepository = UsersRepository();
  final GroupChatRepository _groupChatRepository = GroupChatRepository();
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  final Set<String> _selectedUserIds = {};
  String _searchQuery = '';
  bool _isCreating = false;

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboardVisible = MediaQuery.of(context).viewInsets.bottom > 0;

    return ThemedScaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Group Name Input
          _buildGroupNameInput(),

          // Search Bar
          _buildSearchBar(),

          // Selected Users Chips
          if (_selectedUserIds.isNotEmpty) _buildSelectedUsersChips(),

          // Users List - Flexible for better keyboard handling
          Flexible(
            child: _buildUsersList(),
          ),
        ],
      ),
      floatingActionButton: (_selectedUserIds.length >= 2 && !keyboardVisible)
          ? Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(30),
                gradient: LinearGradient(
                  colors: _isCreating
                      ? [brown700, brown900]
                      : [teal300, teal700],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: (_isCreating ? brown700 : teal500).withValues(alpha: 0.5),
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
                child: InkWell(
                  onTap: _isCreating ? null : _createGroup,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _isCreating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  color: Colors.white,
                                  strokeWidth: 2.5,
                                ),
                              )
                            : Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check_circle,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                        const SizedBox(width: 12),
                        Text(
                          _isCreating ? 'جاري الإنشاء...' : 'إنشاء المجموعة',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : null,
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
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'إنشاء مجموعة جديدة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'اختر عضوين على الأقل',
                        style: TextStyle(
                          color: teal100.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: _selectedUserIds.length >= 2 ? teal500 : sage700.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_selectedUserIds.length} محدد',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGroupNameInput() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: teal300.withValues(alpha: 0.3)),
      ),
      child: TextField(
        controller: _groupNameController,
        style: const TextStyle(color: Colors.white, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'اسم المجموعة...',
          hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
          border: InputBorder.none,
          icon: Icon(Icons.group, color: teal300),
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          hintText: 'ابحث عن أعضاء...',
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

  Widget _buildSelectedUsersChips() {
    return Container(
      height: 60,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: StreamBuilder<List<UserModel>>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const SizedBox.shrink();

          final allUsers = snapshot.data!;
          final selectedUsers = allUsers.where((user) => _selectedUserIds.contains(user.id)).toList();

          return ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: selectedUsers.length,
            itemBuilder: (context, index) {
              final user = selectedUsers[index];
              return Container(
                margin: const EdgeInsets.only(right: 8),
                child: Chip(
                  backgroundColor: sage700.withValues(alpha: 0.5),
                  deleteIconColor: red300,
                  label: Text(
                    user.fullName,
                    style: const TextStyle(color: Colors.white),
                  ),
                  avatar: AvatarDisplayWidget(
                    user: user,
                    imageUrl: user.profileImageUrl,
                    name: user.fullName,
                    size: 32,
                    showBorder: false,
                  ),
                  onDeleted: () {
                    setState(() {
                      _selectedUserIds.remove(user.id);
                    });
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildUsersList() {
    return StreamBuilder<List<UserModel>>(
      stream: _getUsersStream(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(color: teal300),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.error_outline, size: 60, color: red300),
                const SizedBox(height: 16),
                Text(
                  'حدث خطأ في تحميل المستخدمين',
                  style: TextStyle(color: red300, fontSize: 16),
                ),
              ],
            ),
          );
        }

        var users = snapshot.data ?? [];

        // Filter out current user
        users = users.where((user) => user.id != widget.currentUser.id).toList();

        // Apply search filter
        if (_searchQuery.isNotEmpty) {
          users = users.where((user) {
            final nameMatch = user.fullName.toLowerCase().contains(_searchQuery);
            final phoneMatch = user.phoneNumber?.contains(_searchQuery) ?? false;
            return nameMatch || phoneMatch;
          }).toList();
        }

        if (users.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _searchQuery.isNotEmpty ? Icons.search_off : Icons.people_outline,
                  size: 80,
                  color: teal300.withValues(alpha: 0.3),
                ),
                const SizedBox(height: 20),
                Text(
                  _searchQuery.isNotEmpty ? 'لا توجد نتائج' : 'لا يوجد مستخدمين متاحين',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          itemCount: users.length,
          itemBuilder: (context, index) {
            final user = users[index];
            final isSelected = _selectedUserIds.contains(user.id);
            return _buildUserTile(user, isSelected);
          },
        );
      },
    );
  }

  Widget _buildUserTile(UserModel user, bool isSelected) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isSelected
              ? [teal700.withValues(alpha: 0.5), teal900.withValues(alpha: 0.5)]
              : [sage900.withValues(alpha: 0.3), sage700.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? teal300 : sage300.withValues(alpha: 0.2),
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () {
            setState(() {
              if (isSelected) {
                _selectedUserIds.remove(user.id);
              } else {
                _selectedUserIds.add(user.id);
              }
            });
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                AvatarDisplayWidget(
                  user: user,
                  imageUrl: user.profileImageUrl,
                  name: user.fullName,
                  size: 56,
                  showBorder: false,
                ),
                const SizedBox(width: 16),

                // User Info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: _getUserTypeColor(user.userType).withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getUserTypeColor(user.userType).withValues(alpha: 0.5),
                              ),
                            ),
                            child: Text(
                              user.userType.label,
                              style: TextStyle(
                                color: _getUserTypeColor(user.userType),
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Selection Indicator
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected ? teal500 : Colors.white.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    isSelected ? Icons.check : Icons.person_add_outlined,
                    color: isSelected ? Colors.white : teal300,
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Stream<List<UserModel>> _getUsersStream() {
    final currentUser = widget.currentUser;

    switch (currentUser.userType) {
      case UserType.priest:
        return _usersRepository.getUsers().map((usersList) {
          return usersList.map((userData) => UserModel.fromJson(userData)).toList();
        });

      case UserType.superServant:
        return _usersRepository.getUsersByMultipleTypesAndGender(
          [UserType.priest.code, UserType.superServant.code, UserType.servant.code, UserType.child.code],
          currentUser.gender.code,
        );

      default:
        return Stream.value([]);
    }
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.priest:
        return const Color(0xFFFFD700);
      case UserType.superServant:
        return teal300;
      case UserType.servant:
        return tawny;
      case UserType.child:
        return sage300;
    }
  }

  Future<void> _createGroup() async {
    if (_groupNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى إدخال اسم المجموعة'),
          backgroundColor: red500,
        ),
      );
      return;
    }

    if (_selectedUserIds.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('يرجى اختيار عضوين على الأقل'),
          backgroundColor: red500,
        ),
      );
      return;
    }

    setState(() {
      _isCreating = true;
    });

    try {
      final currentUserId = FirebaseAuth.instance.currentUser?.uid;
      if (currentUserId == null) {
        throw Exception('يجب تسجيل الدخول أولاً');
      }

      final memberIds = [currentUserId, ..._selectedUserIds];

      final groupChat = GroupChatModel(
        groupName: _groupNameController.text.trim(),
        createdBy: currentUserId,
        memberIds: memberIds,
        createdAt: DateTime.now(),
      );

      final groupId = await _groupChatRepository.createGroupChat(groupChat);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => GroupChatScreen(
              groupId: groupId,
              groupName: groupChat.groupName,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ: $e'),
            backgroundColor: red500,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}

