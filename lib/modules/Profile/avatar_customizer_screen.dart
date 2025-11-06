import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:fluttermoji/fluttermoji.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
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

  @override
  void initState() {
    super.initState();
    _initializeAvatar();
  }

  // Default Fluttermoji config in JSON format (what Fluttermoji natively uses)
  final fluttermoji = FluttermojiFunctions();

  // Default avatar configuration as JSON string
  static const String _defaultConfig = '{"topType":6,"accessoriesType":1,"hairColor":2,"facialHairType":0,"facialHairColor":2,"clotheType":4,"eyeType":9,"eyebrowType":4,"mouthType":8,"skinColor":1,"clotheColor":8,"style":0,"graphicType":0}';

  Future<void> _initializeAvatar() async {
    try {
      final prefs = await SharedPreferences.getInstance();

      // If Firestore already has an avatar for this user (passed in), seed it into
      // Fluttermoji's internal key so the customizer loads it.
      final existing = widget.existingAvatar;
      if (existing != null && existing.trim().isNotEmpty) {
        // Fluttermoji expects JSON string format: {"topType":6,"accessoriesType":3,...}
        await prefs.setString('fluttermojiSelectedOptions', existing);
      } else {
        // No avatar in Firestore → use default configuration
        await prefs.setString('fluttermojiSelectedOptions', _defaultConfig);

      }
    } catch (e) {
      // ignore: avoid_print
      print('Avatar init error: $e');
      // Even if something goes wrong, ensure the screen becomes interactive
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _saveAvatar() async {
    setState(() => isLoading = true);

    try {
      // Use Fluttermoji's native method to get the avatar config as JSON string
      // This returns format: {"topType":6,"accessoriesType":3,"hairColor":1,...}
      final avatarConfig = await fluttermoji.encodeMySVGtoString();

      if (avatarConfig.isEmpty) {
        throw Exception('لم يتم العثور على بيانات الأفاتار');
      }

      // Verify it's valid JSON
      jsonDecode(avatarConfig); // This will throw if invalid

      // Persist directly to Firestore in JSON format
      await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .set({'avatar': avatarConfig}, SetOptions(merge: true));

      if (mounted) {
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('تم حفظ الأفاتار بنجاح'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        // Return configuration back to profile screen for immediate preview
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
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: teal900,
      appBar: AppBar(
        backgroundColor: teal900,
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
                autosave: true, // keep config updated internally
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