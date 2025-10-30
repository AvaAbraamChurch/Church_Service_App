import 'package:church/core/utils/gender_enum.dart';
import 'package:flutter/material.dart';

import '../../core/models/user/user_model.dart';
import '../../core/repositories/users_reopsitory.dart';
import '../../core/styles/colors.dart';
import '../../core/styles/themeScaffold.dart';
import '../../core/utils/userType_enum.dart';
import 'chat_screen.dart';

class UserSelectionScreen extends StatefulWidget {
  final UserModel currentUser;

  const UserSelectionScreen({
    super.key,
    required this.currentUser,
  });

  @override
  State<UserSelectionScreen> createState() => _UserSelectionScreenState();
}

class _UserSelectionScreenState extends State<UserSelectionScreen> {
  final UsersRepository _usersRepository = UsersRepository();
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: _buildAppBar(),
      body: Column(
        children: [
          // Search Bar
          _buildSearchBar(),

          // Users List
          Expanded(
            child: _buildUsersList(),
          ),
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
                        'اختر محادثة جديدة',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        _getRoleDescription(),
                        style: TextStyle(
                          color: teal100.withValues(alpha: 0.8),
                          fontSize: 12,
                        ),
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
          hintText: 'ابحث بالاسم أو رقم الهاتف...',
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

  Widget _buildUsersList() {
    // Children can only see received conversations - redirect them
    if (widget.currentUser.userType == UserType.child) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.lock_outline,
              size: 80,
              color: brown300.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 20),
            Text(
              'لا يمكنك بدء محادثات جديدة',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'يمكنك فقط الرد على المحادثات المستلمة',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.6),
                fontSize: 16,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

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
            return _buildUserTile(user);
          },
        );
      },
    );
  }

  Widget _buildUserTile(UserModel user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [brown900.withValues(alpha: 0.3), brown700.withValues(alpha: 0.3)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.1),
          width: 1,
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
                  receiverId: user.id,
                  receiverName: user.fullName,
                  receiverImageUrl: user.profileImageUrl,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // Avatar
                CircleAvatar(
                  radius: 28,
                  backgroundColor: _getUserTypeColor(user.userType),
                  backgroundImage: user.profileImageUrl != null
                      ? NetworkImage(user.profileImageUrl!)
                      : null,
                  child: user.profileImageUrl == null
                      ? Text(
                          user.fullName[0].toUpperCase(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        )
                      : null,
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
                          if (user.phoneNumber != null) ...[
                            const SizedBox(width: 8),
                            Icon(Icons.phone, size: 14, color: teal300.withValues(alpha: 0.7)),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                user.phoneNumber!,
                                style: TextStyle(
                                  color: Colors.white.withValues(alpha: 0.6),
                                  fontSize: 12,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (user.userClass.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            user.userClass,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.5),
                              fontSize: 12,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),

                // Chat Icon
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: teal500.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.chat_bubble_outline,
                    color: teal300,
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
        // Priest can chat with anyone - get all users
        return _usersRepository.getUsers().map((usersList) {
          return usersList
              .map((userData) => UserModel.fromJson(userData))
              .toList();
        });

      case UserType.superServant:
        // Super Servant can chat with:
        // - Priests
        // - All servants with same gender
        // - All children with same gender
        return _usersRepository.getUsersByMultipleTypesAndGender(
          [UserType.priest.code, UserType.superServant.code, UserType.servant.code, UserType.child.code],
          currentUser.gender.code,
        );

      case UserType.servant:
        // Servant can chat with:
        // - Priests
        // - Super Servants with same gender
        // - Servants with same gender and userClass
        // - Children with same gender and userClass
        return _usersRepository.getUsersByMultipleTypes(
          currentUser.userClass,
          [UserType.priest.code, UserType.superServant.code, UserType.servant.code, UserType.child.code],
          currentUser.gender.code,
        );

      case UserType.child:
        // Children cannot initiate chats - return empty stream
        return Stream.value([]);
    }
  }

  String _getRoleDescription() {
    switch (widget.currentUser.userType) {
      case UserType.priest:
        return 'يمكنك التواصل مع جميع المستخدمين';
      case UserType.superServant:
        return 'يمكنك التواصل مع الخدام والمخدومين من نفس النوع';
      case UserType.servant:
        return 'يمكنك التواصل مع الكهنة والخدام والمخدومين من نفس الفصل';
      case UserType.child:
        return 'يمكنك الرد على المحادثات المستلمة فقط';
    }
  }

  Color _getUserTypeColor(UserType userType) {
    switch (userType) {
      case UserType.priest:
        return const Color(0xFFFFD700); // Gold
      case UserType.superServant:
        return teal300;
      case UserType.servant:
        return brown300;
      case UserType.child:
        return sage300;
    }
  }
}

