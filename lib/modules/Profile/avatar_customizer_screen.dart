import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/styles/colors.dart';

class AvatarCustomizerScreen extends StatefulWidget {
  final String userId;
  final String? existingAvatar;

  const AvatarCustomizerScreen({
    super.key,
    required this.userId,
    this.existingAvatar,
  });

  @override
  State<AvatarCustomizerScreen> createState() => _AvatarCustomizerScreenState();
}

class _AvatarCustomizerScreenState extends State<AvatarCustomizerScreen> {
  bool isLoading = true;
  String? avatarPreview;

  @override
  void initState() {
    super.initState();
    _initializeAvatar();
  }

  Future<void> _initializeAvatar() async {
    // Load existing avatar configuration if available
    final prefs = await SharedPreferences.getInstance();

    // Try to load user-specific avatar first, otherwise use the passed one
    String? existingConfig = prefs.getString('fluttermoji_config_${widget.userId}');

    if (existingConfig == null && widget.existingAvatar != null) {
      // If we have an existing avatar SVG, save it to SharedPreferences
      // so the customizer can work with it
      avatarPreview = widget.existingAvatar;
    }

    setState(() {
      isLoading = false;
    });
  }

  Future<void> _saveAvatar() async {
    setState(() => isLoading = true);

    try {
      // Get the avatar configuration from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final avatarConfig = prefs.getString('fluttermojiSelectedOptions');

      if (avatarConfig == null || avatarConfig.isEmpty) {
        throw Exception('لم يتم العثور على بيانات الأفاتار');
      }

      // Save with user-specific key
      await prefs.setString('fluttermoji_config_${widget.userId}', avatarConfig);

      // Return the configuration to the profile screen
      if (mounted) {
        Navigator.pop(context, avatarConfig);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('حدث خطأ في حفظ الأفاتار: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[900],
      appBar: AppBar(
        backgroundColor: Colors.grey[850],
        elevation: 0,
        title: const Text(
          'تخصيص الأفاتار',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (!isLoading)
            TextButton.icon(
              onPressed: _saveAvatar,
              icon: const Icon(Icons.check, color: Colors.white),
              label: const Text(
                'حفظ',
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              style: TextButton.styleFrom(
                backgroundColor: teal500,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            )
          else
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              ),
            ),
        ],
      ),
      body: isLoading
          ? Center(
              child: CircularProgressIndicator(color: teal500),
            )
          : Column(
              children: [
                // Real-time Avatar Preview
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [teal700, teal500],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Column(
                    children: [
                      Container(
                        width: 180,
                        height: 180,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 4),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.3),
                              blurRadius: 15,
                              spreadRadius: 2,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: ClipOval(
                          child: FluttermojiCircleAvatar(
                            backgroundColor: Colors.white,
                            radius: 90,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'معاينة حية للأفاتار',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.9),
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),

                // Customizer Options
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey[850],
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: FluttermojiCustomizer(
                      scaffoldWidth: MediaQuery.of(context).size.width,
                      autosave: false,
                      theme: FluttermojiThemeData(
                        boxDecoration: BoxDecoration(
                          color: Colors.grey[850],
                        ),
                        primaryBgColor: Colors.grey[800]!,
                        secondaryBgColor: Colors.grey[700]!,
                        selectedTileDecoration: BoxDecoration(
                          color: teal500,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: teal300, width: 2),
                        ),
                        unselectedTileDecoration: BoxDecoration(
                          color: Colors.grey[700],
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.grey[600]!, width: 1),
                        ),
                        labelTextStyle: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        iconColor: teal300,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}

