import 'package:church/core/repositories/group_chat_repository.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../core/repositories/messages_repository.dart';
import '../core/repositories/users_reopsitory.dart';

class MigrationScreen extends StatelessWidget {
  final MessagesRepository _repo = MessagesRepository();
  final GroupChatRepository _grepo = GroupChatRepository();
  static const String _adminUid = 'h2xPvUO88qVuVwFed9YDqV33E2A2';


  Future<void> debugClassGroup() async {
    final userId = FirebaseAuth.instance.currentUser?.uid;
    if (userId == null) return;

    final user = await UsersRepository().getUserById(userId);
    debugPrint('👤 Current user: ${user.fullName}, type: ${user.userType.code}, class: ${user.userClass}');

    final repo = GroupChatRepository();
    await GroupChatRepository().backfillExistingClassGroups(); // ← Call backfill function to fix existing groups (run once, then comment out)
    await repo.ensureUserInClassGroup(
      userId: userId,
      userClass: user.userClass,
      createdBy: userId,
    );

    final groups = await repo.getUserGroupChats(userId).first;
    debugPrint('📦 User sees ${groups.length} groups:');
    for (final g in groups) {
      debugPrint('   - ${g.groupName} | id: ${g.id} | isDefault: ${g.isDefault} | userClass: ${g.userClass}');
    }
  }



  @override
  Widget build(BuildContext context) {
    debugClassGroup(); // ← Call debug function on build for testing

    return Scaffold(
      appBar: AppBar(title: const Text('Admin Migration')),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            if (FirebaseAuth.instance.currentUser?.uid != _adminUid) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('🔒 Unauthorized')),
              );
              return;
            }

            // Show loading
            showDialog(context: context, barrierDismissible: false, builder: (_) => const Center(child: CircularProgressIndicator()));

            try {
              final count = await _repo.backfillParticipants();
              final groupCount = await _grepo.backfillGroupChatFields();
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('✅ Backfilled $count messages and $groupCount group chats')),
                );
              }
            } catch (e) {
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('❌ Error: $e'), backgroundColor: Colors.red),
                );
              }
            }
          },
          child: const Text('Run Migration'),
        ),
      ),
    );
  }
}