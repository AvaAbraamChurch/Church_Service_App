import 'package:church/core/services/account_manager_service.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/modules/Auth/login/login_screen.dart';
import 'package:church/modules/Splash/splash_screen.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';

class AccountSwitcherScreen extends StatefulWidget {
  const AccountSwitcherScreen({super.key});

  @override
  State<AccountSwitcherScreen> createState() => _AccountSwitcherScreenState();
}

class _AccountSwitcherScreenState extends State<AccountSwitcherScreen> {
  final AccountManagerService _accountManager = AccountManagerService();
  List<Map<String, dynamic>> _accounts = [];
  String? _activeAccountId;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadAccounts();
  }

  Future<void> _loadAccounts() async {
    setState(() => _loading = true);

    final accounts = await _accountManager.getSavedAccounts();
    final activeId = await _accountManager.getActiveAccountId();

    debugPrint('📱 Loaded ${accounts.length} accounts');
    debugPrint('📱 Active account ID: $activeId');
    for (var acc in accounts) {
      debugPrint('  - ${acc['displayName']} (${acc['email']})');
    }

    setState(() {
      _accounts = accounts;
      _activeAccountId = activeId;
      _loading = false;
    });
  }

  Future<void> _switchAccount(String userId) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(
        child: CircularProgressIndicator(),
      ),
    );

    final success = await _accountManager.switchAccount(userId);

    if (mounted) {
      Navigator.pop(context); // Close loading

      if (success) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم التبديل إلى الحساب بنجاح'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 1),
          ),
        );

        // Wait a moment for the message to show
        await Future.delayed(const Duration(milliseconds: 500));

        if (!mounted) return;

        // Restart the app by navigating to splash screen and removing all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (context) => const SplashScreen(),
          ),
          (route) => false, // Remove all previous routes
        );
      } else {
        // Show error dialog with option to login manually
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text(
              'فشل التبديل',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
            content: const Text(
              'فشل التبديل إلى الحساب. قد يكون الحساب محذوف أو تم تغيير كلمة المرور.',
              style: TextStyle(fontFamily: 'Alexandria'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('إلغاء'),
              ),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  // Navigate to login screen
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(
                      builder: (context) => const LoginScreen(),
                    ),
                    (route) => false,
                  );
                },
                child: const Text('تسجيل الدخول'),
              ),
            ],
          ),
        );
      }
    }
  }

  Future<void> _removeAccount(String userId, String email) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'إزالة الحساب',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: Text(
          'هل تريد إزالة الحساب "$email" من القائمة؟',
          style: const TextStyle(fontFamily: 'Alexandria'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('إزالة'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await _accountManager.removeAccount(userId);
      _loadAccounts();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم إزالة الحساب'),
            backgroundColor: Colors.green,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(70),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF00695C), // teal700
                const Color(0xFF00897B), // teal600
                const Color(0xFF26A69A), // teal400
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF00897B).withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: AppBar(
            title: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.swap_horiz_rounded,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                const Text(
                  'تبديل الحساب',
                  style: TextStyle(
                    fontFamily: 'Alexandria',
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.transparent,
            elevation: 0,
            centerTitle: true,
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.arrow_back_ios_new,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              // Debug button to reload accounts
              IconButton(
                icon: const Icon(Icons.refresh, color: Colors.white),
                onPressed: () {
                  debugPrint('🔄 Manual refresh requested');
                  _loadAccounts();
                },
              ),
            ],
          ),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _accounts.isEmpty
              ? _buildEmptyState()
              : _buildAccountsList(),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          navigateTo(context, const LoginScreen());
        },
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF00897B), // teal600
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text(
          'إضافة حساب',
          style: TextStyle(
            fontFamily: 'Alexandria',
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.account_circle_outlined,
            size: 120,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 24),
          Text(
            'لا توجد حسابات محفوظة',
            style: TextStyle(
              fontSize: 20,
              color: Colors.grey[600],
              fontFamily: 'Alexandria',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'قم بإضافة حساب للبدء',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
              fontFamily: 'Alexandria',
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccountsList() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _accounts.length,
      itemBuilder: (context, index) {
        final account = _accounts[index];
        final isActive = account['userId'] == _activeAccountId;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isActive
                  ? [Colors.green[50]!, Colors.green[100]!]
                  : [Colors.white, Colors.grey[50]!],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(16),
            border: isActive
                ? Border.all(color: Colors.green[600]!, width: 2)
                : Border.all(color: Colors.grey[300]!),
            boxShadow: [
              BoxShadow(
                color: isActive
                    ? Colors.green.withValues(alpha: 0.3)
                    : Colors.grey.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: isActive ? null : () => _switchAccount(account['userId']),
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    // Avatar
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.green[200],
                          backgroundImage: account['photoUrl'] != null
                              ? NetworkImage(account['photoUrl'])
                              : null,
                          child: account['photoUrl'] == null
                              ? Text(
                                  (account['displayName'] as String)
                                      .substring(0, 1)
                                      .toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[700],
                                  ),
                                )
                              : null,
                        ),
                        if (isActive)
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.green[600],
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                              ),
                              child: const Icon(
                                Icons.check,
                                size: 12,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    // Account Info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  account['displayName'] ?? 'Unknown',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green[900],
                                    fontFamily: 'Alexandria',
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              if (isActive)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green[600],
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Text(
                                    'نشط',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            account['email'] ?? '',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontFamily: 'Alexandria',
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.blue[100],
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  account['userType'] ?? 'user',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.blue[700],
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Remove Button
                    if (!isActive)
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () => _removeAccount(
                          account['userId'],
                          account['email'],
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
}

