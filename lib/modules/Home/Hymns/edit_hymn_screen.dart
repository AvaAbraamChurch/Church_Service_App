import 'package:church/core/models/hymn_model.dart';
import 'package:church/core/services/hymns_service.dart';
import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../../../core/models/class_mapping/class_mapping_model.dart';
import '../../../core/repositories/users_reopsitory.dart';

class EditHymnScreen extends StatefulWidget {
  final HymnModel? initialHymn;

  const EditHymnScreen({super.key, this.initialHymn});

  @override
  State<EditHymnScreen> createState() => _EditHymnScreenState();
}

class _EditHymnScreenState extends State<EditHymnScreen> {
  final _formKey = GlobalKey<FormState>();
  final HymnsService _hymnsService = HymnsService();
  final UsersRepository _usersRepository = UsersRepository();

  HymnModel? _selectedHymn;
  bool _isSaving = false;
  String? _currentUserClass;

  // Controllers
  final _titleController = TextEditingController();
  final _arabicTitleController = TextEditingController();
  final _copticTitleController = TextEditingController();
  final _copticArlyricsController = TextEditingController();
  final _arabicLyricsController = TextEditingController();
  final _copticLyricsController = TextEditingController();
  final _audioUrlController = TextEditingController();
  final _videoUrlController = TextEditingController();
  final _orderController = TextEditingController();

  String? _selectedOccasion;
  final List<String> _occasions = [
    'General',
    'Sunday',
    'Lent',
    'Feast',
    'Christmas',
    'Easter',
    'Resurrection',
    'Pascha',
  ];

  List<String> _availableUserClasses = [];
  final Set<String> _selectedUserClasses = {};
  bool _isLoadingClasses = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUserClass();
    _loadUserClasses();
    if (widget.initialHymn != null) {
      _loadHymnData(widget.initialHymn!);
    }
  }

  /// Load the current user's class from Firebase
  Future<void> _loadCurrentUserClass() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await _usersRepository.getUserById(userId);
        if (mounted) {
          setState(() {
            _currentUserClass = userDoc.userClass;
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading current user class: $e');
    }
  }

  /// Load user classes from Firestore
  Future<void> _loadUserClasses() async {
    try {
      // Get all active class mappings
      final classMappings =
          await ClassMappingService.getActiveClassMappings().first;

      if (mounted) {
        setState(() {
          // Filter and extract class names with numeric classCode only (1, 2, 3, 4, etc.)
          // Exclude compound codes like "1&2", "3&4", etc.
          _availableUserClasses = classMappings
              .where((mapping) {
                // Check if classCode is a single digit or number (no special characters)
                final code = mapping.classCode.trim();
                return RegExp(r'^\d+$').hasMatch(code);
              })
              .map((mapping) => mapping.className)
              .toSet()
              .toList();

          if (_availableUserClasses.isNotEmpty) {
            _availableUserClasses.sort(); // Sort alphabetically
          }

          _isLoadingClasses = false;
        });
      }
    } catch (e) {
      debugPrint('Error loading user classes: $e');
      if (mounted) {
        setState(() {
          _isLoadingClasses = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تعذر تحميل الفصول: $e'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _arabicTitleController.dispose();
    _copticTitleController.dispose();
    _copticArlyricsController.dispose();
    _arabicLyricsController.dispose();
    _copticLyricsController.dispose();
    _audioUrlController.dispose();
    _videoUrlController.dispose();
    _orderController.dispose();
    super.dispose();
  }

  void _loadHymnData(HymnModel hymn) {
    setState(() {
      _selectedHymn = hymn;
      _titleController.text = hymn.title;
      _arabicTitleController.text = hymn.arabicTitle;
      _copticTitleController.text = hymn.copticTitle;
      _copticArlyricsController.text = hymn.copticArlyrics ?? '';
      _arabicLyricsController.text = hymn.arabicLyrics ?? '';
      _copticLyricsController.text = hymn.copticLyrics ?? '';
      _audioUrlController.text = hymn.audioUrl ?? '';
      _videoUrlController.text = hymn.videoUrl ?? '';
      _orderController.text = hymn.order.toString();
      _selectedOccasion = hymn.occasion;
      _selectedUserClasses.clear();
      _selectedUserClasses.addAll(hymn.userClasses);
    });
  }

  Future<void> _updateHymn() async {
    if (_selectedHymn == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار لحن للتعديل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_selectedUserClasses.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('الرجاء اختيار فصل واحد على الأقل'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final updatedHymn = HymnModel(
        id: _selectedHymn!.id,
        title: _titleController.text.trim(),
        arabicTitle: _arabicTitleController.text.trim(),
        copticTitle: _copticTitleController.text.trim(),
        copticArlyrics: _copticArlyricsController.text.trim().isEmpty
            ? null
            : _copticArlyricsController.text.trim(),
        arabicLyrics: _arabicLyricsController.text.trim().isEmpty
            ? null
            : _arabicLyricsController.text.trim(),
        copticLyrics: _copticLyricsController.text.trim().isEmpty
            ? null
            : _copticLyricsController.text.trim(),
        audioUrl: _audioUrlController.text.trim().isEmpty
            ? null
            : _audioUrlController.text.trim(),
        videoUrl: _videoUrlController.text.trim().isEmpty
            ? null
            : _videoUrlController.text.trim(),
        occasion: _selectedOccasion,
        userClasses: _selectedUserClasses.toList(),
        order: int.tryParse(_orderController.text) ?? 0,
        createdAt: _selectedHymn!.createdAt,
      );

      final success = await _hymnsService.updateHymn(
        _selectedHymn!.id,
        updatedHymn,
      );

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم تحديث اللحن بنجاح'),
            backgroundColor: teal500,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في تحديث اللحن'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _deleteHymn() async {
    if (_selectedHymn == null) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('تأكيد الحذف'),
        content: Text(
          'هل أنت متأكد من حذف اللحن "${_selectedHymn!.arabicTitle}"؟',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('إلغاء'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('حذف'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isSaving = true);

    try {
      final success = await _hymnsService.deleteHymn(_selectedHymn!.id);

      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف اللحن بنجاح'),
            backgroundColor: teal500,
          ),
        );
        Navigator.pop(context, true);
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('فشل في حذف اللحن'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('خطأ: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('تعديل لحن', style: TextStyle(color: Colors.white)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: Colors.transparent,
        actions: [
          if (_selectedHymn != null && !_isSaving)
            IconButton(
              onPressed: _deleteHymn,
              icon: const Icon(Icons.delete),
              tooltip: 'حذف',
            ),
          if (_selectedHymn != null && !_isSaving)
            IconButton(
              onPressed: _updateHymn,
              icon: const Icon(Icons.save),
              tooltip: 'حفظ',
            ),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              // Hymn Selector
              if (_selectedHymn == null)
                Container(
                  padding: const EdgeInsets.all(16.0),
                  child: StreamBuilder<List<HymnModel>>(
                    stream: _currentUserClass != null
                        ? _hymnsService.getHymnsByUserClass(_currentUserClass!)
                        : _hymnsService.getAllHymns(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Text(
                          'خطأ في تحميل الألحان: ${snapshot.error}',
                          style: const TextStyle(color: Colors.red),
                          textAlign: TextAlign.center,
                        );
                      }

                      final hymns = snapshot.data ?? [];

                      if (hymns.isEmpty) {
                        return const Text(
                          'لا توجد ألحان متاحة',
                          style: TextStyle(fontSize: 16),
                          textAlign: TextAlign.center,
                        );
                      }

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Show filter indicator if user class is loaded
                          if (_currentUserClass != null)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: teal500.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: teal500.withValues(alpha: 0.3),
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.filter_list,
                                      size: 16,
                                      color: teal700,
                                    ),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        'الألحان المتاحة لفصلك: $_currentUserClass',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: teal700,
                                          fontWeight: FontWeight.w600,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: teal500.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: teal500.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  Icons.info_outline,
                                  color: teal700,
                                  size: 20,
                                ),
                                const SizedBox(width: 8),
                                const Expanded(
                                  child: Text(
                                    'اختر اللحن الذي تريد تعديله',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 16),
                          DropdownButtonFormField<String>(
                            decoration: InputDecoration(
                              labelText: 'اختر اللحن',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.9),
                            ),
                            isExpanded: true,
                            hint: const Text('اختر لحناً من القائمة'),
                            items: hymns.map((hymn) {
                              return DropdownMenuItem<String>(
                                value: hymn.id,
                                child: Text(
                                  hymn.arabicTitle,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                final hymn = hymns.firstWhere(
                                  (h) => h.id == newValue,
                                );
                                _loadHymnData(hymn);
                              }
                            },
                          ),
                        ],
                      );
                    },
                  ),
                ),

              // Edit Form (only show when hymn is selected)
              if (_selectedHymn != null)
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Selected Hymn Info
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: teal500.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: teal500.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: teal700, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'تعديل: ${_selectedHymn!.arabicTitle}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: teal700,
                                    ),
                                  ),
                                ),
                                IconButton(
                                  onPressed: () {
                                    setState(() {
                                      _selectedHymn = null;
                                      _formKey.currentState?.reset();
                                    });
                                  },
                                  icon: const Icon(Icons.close, size: 20),
                                  tooltip: 'إلغاء',
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Titles Section
                          _buildSectionHeader('العناوين'),
                          _buildTextField(
                            controller: _arabicTitleController,
                            label: 'العنوان بالعربية',
                            hint: 'أدخل العنوان بالعربية',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'العنوان بالعربية مطلوب';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _copticTitleController,
                            label: 'العنوان بالقبطية',
                            hint: 'أدخل العنوان بالقبطية',
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _titleController,
                            label: 'العنوان بالإنجليزية',
                            hint: 'Enter title in English',
                            validator: (value) {
                              if (value == null || value.trim().isEmpty) {
                                return 'English title is required';
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // Lyrics Section
                          _buildSectionHeader('الكلمات'),
                          _buildTextField(
                            controller: _arabicLyricsController,
                            label: 'الكلمات بالعربية',
                            hint: 'أدخل كلمات اللحن بالعربية',
                            maxLines: 8,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _copticLyricsController,
                            label: 'الكلمات بالقبطية',
                            hint: 'أدخل كلمات اللحن بالقبطية',
                            maxLines: 8,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _copticArlyricsController,
                            label: 'الكلمات بالإنجليزية',
                            hint: 'Enter lyrics in English',
                            maxLines: 8,
                          ),

                          const SizedBox(height: 32),

                          // Media URLs Section
                          _buildSectionHeader('الوسائط'),
                          _buildTextField(
                            controller: _audioUrlController,
                            label: 'رابط الصوت',
                            hint: 'https://example.com/audio.mp3',
                            keyboardType: TextInputType.url,
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _videoUrlController,
                            label: 'رابط الفيديو',
                            hint: 'https://example.com/video.mp4',
                            keyboardType: TextInputType.url,
                          ),

                          const SizedBox(height: 32),

                          // Occasion and Order Section
                          _buildSectionHeader('التصنيف'),
                          DropdownButtonFormField<String>(
                            initialValue: _selectedOccasion,
                            decoration: InputDecoration(
                              labelText: 'المناسبة',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              filled: true,
                              fillColor: Colors.white.withValues(alpha: 0.9),
                            ),
                            hint: const Text('اختر المناسبة'),
                            items: _occasions.map((occasion) {
                              return DropdownMenuItem(
                                value: occasion,
                                child: Text(occasion),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setState(() => _selectedOccasion = value);
                            },
                          ),
                          const SizedBox(height: 16),
                          _buildTextField(
                            controller: _orderController,
                            label: 'الترتيب',
                            hint: '0',
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value != null && value.isNotEmpty) {
                                if (int.tryParse(value) == null) {
                                  return 'الرجاء إدخال رقم صحيح';
                                }
                              }
                              return null;
                            },
                          ),

                          const SizedBox(height: 32),

                          // User Classes Section
                          _buildSectionHeader('الفصول المتاحة'),
                          _isLoadingClasses
                              ? Container(
                                  padding: const EdgeInsets.all(32),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: teal500.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: const Center(
                                    child: Column(
                                      children: [
                                        CircularProgressIndicator(
                                          color: teal500,
                                        ),
                                        SizedBox(height: 16),
                                        Text(
                                          'جاري تحميل الفصول...',
                                          style: TextStyle(color: Colors.grey),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                              : _availableUserClasses.isEmpty
                              ? Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(color: Colors.orange),
                                  ),
                                  child: const Row(
                                    children: [
                                      Icon(
                                        Icons.warning_rounded,
                                        color: Colors.orange,
                                      ),
                                      SizedBox(width: 12),
                                      Expanded(
                                        child: Text(
                                          'لا توجد فصول متاحة',
                                          style: TextStyle(
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.9),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: _selectedUserClasses.isEmpty
                                          ? Colors.red.withValues(alpha: 0.5)
                                          : teal500.withValues(alpha: 0.3),
                                    ),
                                  ),
                                  child: Wrap(
                                    spacing: 8,
                                    runSpacing: 8,
                                    children: _availableUserClasses.map((
                                      userClass,
                                    ) {
                                      final isSelected = _selectedUserClasses
                                          .contains(userClass);
                                      return FilterChip(
                                        label: Text(userClass),
                                        selected: isSelected,
                                        onSelected: (selected) {
                                          setState(() {
                                            if (selected) {
                                              _selectedUserClasses.add(
                                                userClass,
                                              );
                                            } else {
                                              _selectedUserClasses.remove(
                                                userClass,
                                              );
                                            }
                                          });
                                        },
                                        selectedColor: teal500.withValues(
                                          alpha: 0.3,
                                        ),
                                        checkmarkColor: teal700,
                                        labelStyle: TextStyle(
                                          color: isSelected
                                              ? teal700
                                              : Colors.black87,
                                          fontWeight: isSelected
                                              ? FontWeight.w600
                                              : FontWeight.normal,
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ),
                          if (_selectedUserClasses.isEmpty)
                            const Padding(
                              padding: EdgeInsets.only(top: 8, left: 12),
                              child: Text(
                                'اختر فصلاً واحداً على الأقل',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontSize: 12,
                                ),
                              ),
                            ),

                          const SizedBox(height: 32),

                          // Action Buttons
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: _isSaving ? null : _deleteHymn,
                                  icon: const Icon(Icons.delete),
                                  label: const Text('حذف اللحن'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.red,
                                    side: const BorderSide(color: Colors.red),
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                flex: 2,
                                child: ElevatedButton.icon(
                                  onPressed: _isSaving ? null : _updateHymn,
                                  icon: const Icon(Icons.save),
                                  label: Text(
                                    _isSaving
                                        ? 'جاري الحفظ...'
                                        : 'حفظ التعديلات',
                                  ),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: teal500,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 32),
                        ],
                      ),
                    ),
                  ),
                ),

              // Empty state when no hymn selected
              if (_selectedHymn == null)
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit_note,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'اختر لحناً من القائمة أعلاه للتعديل',
                          style: TextStyle(fontSize: 16, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),

          // Loading overlay
          if (_isSaving)
            Container(
              color: Colors.black.withValues(alpha: 0.3),
              child: const Center(
                child: CircularProgressIndicator(color: teal500),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 24,
            decoration: BoxDecoration(
              color: teal500,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 12),
          Text(
            title,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: teal700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true,
        fillColor: Colors.white.withValues(alpha: 0.9),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
