import 'dart:io';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/blocs/competitions/competitions_cubit.dart';
import 'package:church/core/blocs/competitions/competitions_states.dart';
import 'package:church/core/models/competitions/competition_model.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

class CreateCompetitionScreen extends StatefulWidget {
  const CreateCompetitionScreen({super.key});

  @override
  State<CreateCompetitionScreen> createState() => _CreateCompetitionScreenState();
}

class _CreateCompetitionScreenState extends State<CreateCompetitionScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsPerQuestionController = TextEditingController();

  DateTime? _startDate;
  DateTime? _endDate;
  String _targetAudience = 'all';
  String _targetGender = 'all'; // 'all', 'M', 'F'
  File? _imageFile;
  final ImagePicker _picker = ImagePicker();
  bool _isActive = true;

  // Scoring mode: 'perQuestion' or 'total'
  String _scoringMode = 'perQuestion';
  final _totalPointsController = TextEditingController();

  final List<QuestionModel> _questions = [];

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsPerQuestionController.dispose();
    _totalPointsController.dispose();
    super.dispose();
  }

  String? _imageUrl;

  Future<void> _pickImage() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اختر مصدر الصورة',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(
                'من المعرض',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text(
                'من رابط URL',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () => Navigator.pop(context, 'url'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'gallery') {
      await _pickImageFromGallery();
    } else if (choice == 'url') {
      await _pickImageFromUrl();
    }
  }

  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imageFile = File(image.path);
          _imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار الصورة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromUrl() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'أدخل رابط الصورة',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                Navigator.pop(context, urlController.text.trim());
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() {
        _imageUrl = url;
        _imageFile = null;
      });
    }
  }

  Future<void> _selectDate(BuildContext context, bool isStartDate) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );

    if (picked != null) {
      setState(() {
        if (isStartDate) {
          _startDate = picked;
        } else {
          _endDate = picked;
        }
      });
    }
  }

  List<DropdownMenuItem<String>> _buildClassDropdownItems() {
    List<DropdownMenuItem<String>> items = [];
    final groupedOptions = CompetitionClassMapping.getGroupedClassOptions();

    groupedOptions.forEach((groupName, options) {
      // Add group header (disabled item)
      items.add(
        DropdownMenuItem<String>(
          value: null,
          enabled: false,
          child: Text(
            groupName,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              fontSize: 14,
            ),
          ),
        ),
      );

      // Add options in this group
      for (var option in options) {
        items.add(
          DropdownMenuItem<String>(
            value: option.key,
            child: Padding(
              padding: const EdgeInsets.only(right: 16.0),
              child: Text(option.value),
            ),
          ),
        );
      }
    });

    return items;
  }

  void _addQuestion() {
    showDialog(
      context: context,
      builder: (context) => AddQuestionDialog(
        orderIndex: _questions.length,
        onQuestionAdded: (question) {
          setState(() {
            _questions.add(question);
          });
        },
      ),
    );
  }

  Future<void> _createCompetition() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (_questions.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يجب إضافة سؤال واحد على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Validate dates
    if (_startDate != null && _endDate != null) {
      if (_endDate!.isBefore(_startDate!)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تاريخ الانتهاء يجب أن يكون بعد تاريخ البدء'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Warn if end date is in the past
    if (_endDate != null && _endDate!.isBefore(DateTime.now())) {
      final shouldContinue = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text(
            'تحذير',
            style: TextStyle(fontFamily: 'Alexandria'),
          ),
          content: const Text(
            'تاريخ الانتهاء في الماضي. هل تريد المتابعة؟',
            style: TextStyle(fontFamily: 'Alexandria'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('إلغاء'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('متابعة'),
            ),
          ],
        ),
      );

      if (shouldContinue != true) {
        return;
      }
    }

    final pointsPerQuestion = double.tryParse(_pointsPerQuestionController.text) ?? 10.0;
    final totalPoints = _scoringMode == 'total'
        ? (double.tryParse(_totalPointsController.text) ?? (_questions.length * 10.0))
        : (pointsPerQuestion * _questions.length);

    // Distribute points to each question if using total points mode
    final updatedQuestions = _questions.map((question) {
      if (_scoringMode == 'total') {
        final distributedPoints = totalPoints / _questions.length;
        return question.copyWith(points: distributedPoints);
      } else {
        return question.copyWith(points: pointsPerQuestion);
      }
    }).toList();

    final competition = CompetitionModel(
      competitionName: _nameController.text.trim(),
      description: _descriptionController.text.trim(),
      createdAt: DateTime.now(),
      startDate: _startDate,
      endDate: _endDate,
      numberOfQuestions: _questions.length,
      questions: updatedQuestions,
      isActive: _isActive,
      targetAudience: _targetAudience,
      targetGender: _targetGender,
      pointsPerQuestion: _scoringMode == 'perQuestion' ? pointsPerQuestion : null,
      totalPoints: totalPoints,
    );

    final cubit = CompetitionsCubit.get(context);
    final competitionId = await cubit.createCompetition(
      competition: competition,
      imageFile: _imageFile,
      imageUrl: _imageUrl,
    );

    if (competitionId != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('تم إنشاء المسابقة بنجاح'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<CompetitionsCubit, CompetitionsState>(
      listener: (context, state) {
        if (state is CreateCompetitionError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('خطأ: ${state.error}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      },
      builder: (context, state) {
        final isLoading = state is CreateCompetitionLoading || state is UploadImageLoading;

        return ThemedScaffold(
          appBar: PreferredSize(
            preferredSize: const Size.fromHeight(70),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[400]!, Colors.green[700]!],
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
                        icon: const Icon(Icons.arrow_back, color: Colors.white),
                        tooltip: 'رجوع',
                      ),
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'إنشاء مسابقة جديدة',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'أضف أسئلة واختبر معرفة الطلاب',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.9),
                                fontSize: 12,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.add_circle,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          body: Stack(
            children: [
              Form(
                key: _formKey,
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    // Image Picker
                    Center(
                      child: GestureDetector(
                        onTap: _pickImage,
                        child: Container(
                          width: 150,
                          height: 150,
                          decoration: BoxDecoration(
                            color: Colors.green[50],
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: Colors.green[300]!, width: 2),
                          ),
                          child: _imageFile != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(14),
                                  child: Image.file(
                                    _imageFile!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : _imageUrl != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(14),
                                      child: Image.network(
                                        _imageUrl!,
                                        fit: BoxFit.cover,
                                        loadingBuilder: (context, child, loadingProgress) {
                                          if (loadingProgress == null) return child;
                                          return Center(
                                            child: CircularProgressIndicator(
                                              value: loadingProgress.expectedTotalBytes != null
                                                  ? loadingProgress.cumulativeBytesLoaded /
                                                      loadingProgress.expectedTotalBytes!
                                                  : null,
                                            ),
                                          );
                                        },
                                        errorBuilder: (context, error, stackTrace) {
                                          return Column(
                                            mainAxisAlignment: MainAxisAlignment.center,
                                            children: [
                                              Icon(Icons.error, size: 40, color: Colors.red[300]),
                                              const SizedBox(height: 8),
                                              Text(
                                                'فشل تحميل الصورة',
                                                style: TextStyle(
                                                  color: Colors.red[700],
                                                  fontSize: 12,
                                                  fontFamily: 'Alexandria',
                                                ),
                                              ),
                                            ],
                                          );
                                        },
                                      ),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.add_photo_alternate, size: 50, color: Colors.green[300]),
                                        const SizedBox(height: 8),
                                        Text(
                                          'إضافة صورة',
                                          style: TextStyle(
                                            color: Colors.green[700],
                                            fontFamily: 'Alexandria',
                                          ),
                                        ),
                                      ],
                                    ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Competition Name
                    TextFormField(
                      controller: _nameController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'اسم المسابقة',
                        labelStyle: const TextStyle(color: Colors.white),
                        fillColor: Colors.white,
                        prefixIcon: const Icon(Icons.sports_score, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'يرجى إدخال اسم المسابقة';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),

                    // Description
                    TextFormField(
                      controller: _descriptionController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'الوصف',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(Icons.description, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),

                    // Scoring Mode Selector
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.white30),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.white, size: 20),
                              const SizedBox(width: 8),
                              const Text(
                                'نظام النقاط',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          Row(
                            children: [
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _scoringMode = 'perQuestion';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: _scoringMode == 'perQuestion'
                                          ? Colors.green[600]
                                          : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _scoringMode == 'perQuestion'
                                            ? Colors.green[600]!
                                            : Colors.white30,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.quiz,
                                          color: _scoringMode == 'perQuestion'
                                              ? Colors.white
                                              : Colors.white70,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'نقاط لكل سؤال',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _scoringMode == 'perQuestion'
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 12,
                                            fontWeight: _scoringMode == 'perQuestion'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontFamily: 'Alexandria',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: InkWell(
                                  onTap: () {
                                    setState(() {
                                      _scoringMode = 'total';
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                                    decoration: BoxDecoration(
                                      color: _scoringMode == 'total'
                                          ? Colors.green[600]
                                          : Colors.white.withValues(alpha: 0.1),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: _scoringMode == 'total'
                                            ? Colors.green[600]!
                                            : Colors.white30,
                                        width: 2,
                                      ),
                                    ),
                                    child: Column(
                                      children: [
                                        Icon(
                                          Icons.emoji_events,
                                          color: _scoringMode == 'total'
                                              ? Colors.white
                                              : Colors.white70,
                                          size: 24,
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'إجمالي النقاط',
                                          textAlign: TextAlign.center,
                                          style: TextStyle(
                                            color: _scoringMode == 'total'
                                                ? Colors.white
                                                : Colors.white70,
                                            fontSize: 12,
                                            fontWeight: _scoringMode == 'total'
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            fontFamily: 'Alexandria',
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),
                          if (_scoringMode == 'perQuestion')
                            TextFormField(
                              controller: _pointsPerQuestionController,
                              style: const TextStyle(color: Colors.white),
                              decoration: InputDecoration(
                                labelText: 'النقاط لكل سؤال',
                                labelStyle: const TextStyle(color: Colors.white),
                                hintText: 'مثال: 10',
                                hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                prefixIcon: const Icon(Icons.card_giftcard, color: Colors.white),
                                filled: true,
                                fillColor: Colors.white.withValues(alpha: 0.1),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              validator: (value) {
                                if (value != null && value.isNotEmpty) {
                                  final points = double.tryParse(value);
                                  if (points == null || points <= 0) {
                                    return 'يرجى إدخال رقم صحيح';
                                  }
                                }
                                return null;
                              },
                            )
                          else
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                TextFormField(
                                  controller: _totalPointsController,
                                  style: const TextStyle(color: Colors.white),
                                  decoration: InputDecoration(
                                    labelText: 'إجمالي نقاط المسابقة',
                                    labelStyle: const TextStyle(color: Colors.white),
                                    hintText: 'مثال: 100',
                                    hintStyle: TextStyle(color: Colors.white.withValues(alpha: 0.5)),
                                    prefixIcon: const Icon(Icons.emoji_events, color: Colors.white),
                                    filled: true,
                                    fillColor: Colors.white.withValues(alpha: 0.1),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                  ),
                                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                                  validator: (value) {
                                    if (value != null && value.isNotEmpty) {
                                      final points = double.tryParse(value);
                                      if (points == null || points <= 0) {
                                        return 'يرجى إدخال رقم صحيح';
                                      }
                                    }
                                    return null;
                                  },
                                  onChanged: (value) {
                                    // Show real-time point distribution
                                    setState(() {});
                                  },
                                ),
                                const SizedBox(height: 8),
                                Builder(
                                  builder: (context) {
                                    if (_questions.isEmpty || _totalPointsController.text.isEmpty) {
                                      return Text(
                                        'سيتم توزيع النقاط على جميع الأسئلة',
                                        style: TextStyle(
                                          color: Colors.white.withValues(alpha: 0.7),
                                          fontSize: 12,
                                          fontFamily: 'Alexandria',
                                        ),
                                      );
                                    }
                                    final totalPoints = double.tryParse(_totalPointsController.text);
                                    if (totalPoints != null && totalPoints > 0) {
                                      final pointsPerQuestion = totalPoints / _questions.length;
                                      return Text(
                                        'سيتم توزيع النقاط: ${pointsPerQuestion.toStringAsFixed(3)} نقطة لكل سؤال (${_questions.length} سؤال)',
                                        style: TextStyle(
                                          color: Colors.green[300],
                                          fontSize: 12,
                                          fontFamily: 'Alexandria',
                                          fontWeight: FontWeight.bold,
                                        ),
                                      );
                                    }
                                    return Text(
                                      'سيتم توزيع النقاط على جميع الأسئلة',
                                      style: TextStyle(
                                        color: Colors.white.withValues(alpha: 0.7),
                                        fontSize: 12,
                                        fontFamily: 'Alexandria',
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Target Audience
                    DropdownButtonFormField<String>(
                      value: _targetAudience,
                      style: const TextStyle(color: Colors.black, fontFamily: 'Alexandria'),
                      decoration: InputDecoration(
                        labelText: 'الفئة المستهدفة / الصف',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(Icons.group, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: _buildClassDropdownItems(),
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _targetAudience = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Target Gender
                    DropdownButtonFormField<String>(
                      value: _targetGender,
                      style: const TextStyle(color: Colors.black, fontFamily: 'Alexandria'),
                      decoration: InputDecoration(
                        labelText: 'النوع المستهدف',
                        labelStyle: const TextStyle(color: Colors.white),
                        prefixIcon: const Icon(Icons.wc, color: Colors.white),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'all',
                          child: Text('الكل'),
                        ),
                        DropdownMenuItem(
                          value: 'M',
                          child: Text('ذكور فقط'),
                        ),
                        DropdownMenuItem(
                          value: 'F',
                          child: Text('إناث فقط'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value != null) {
                          setState(() {
                            _targetGender = value;
                          });
                        }
                      },
                    ),
                    const SizedBox(height: 16),

                    // Start Date
                    InkWell(
                      onTap: () => _selectDate(context, true),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ البدء',
                          labelStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(Icons.calendar_today, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _startDate != null
                              ? '${_startDate!.year}-${_startDate!.month}-${_startDate!.day}'
                              : 'اختر تاريخ البدء',
                          style: TextStyle(
                            color: _startDate != null ? Colors.white : const Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // End Date
                    InkWell(
                      onTap: () => _selectDate(context, false),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'تاريخ الانتهاء',
                          labelStyle: const TextStyle(color: Colors.white),
                          prefixIcon: const Icon(Icons.event, color: Colors.white),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          _endDate != null
                              ? '${_endDate!.year}-${_endDate!.month}-${_endDate!.day}'
                              : 'اختر تاريخ الانتهاء',
                          style: TextStyle(
                            color: _endDate != null ? Colors.white : const Color(0xFFE0E0E0),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Active Status
                    SwitchListTile(
                      title: const Text('المسابقة نشطة', style: TextStyle(color: Colors.white),),
                      subtitle: const Text('السماح للمستخدمين بالمشاركة', style: TextStyle(color: Colors.white30),),
                      value: _isActive,
                      activeColor: Colors.green[600],
                      onChanged: (value) {
                        setState(() {
                          _isActive = value;
                        });
                      },
                    ),
                    const SizedBox(height: 24),

                    // Questions Section
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'الأسئلة (${_questions.length})',
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        Flexible(
                          child: ElevatedButton.icon(
                            onPressed: _addQuestion,
                            icon: const Icon(Icons.add),
                            label: const Text('إضافة سؤال'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green[600],
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Questions List
                    if (_questions.isNotEmpty)
                      ...List.generate(_questions.length, (index) {
                        final question = _questions[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: ListTile(
                            leading: CircleAvatar(
                              backgroundColor: Colors.green[600],
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(color: Colors.white),
                              ),
                            ),
                            title: Text(
                              question.questionText,
                              style: const TextStyle(fontFamily: 'Alexandria'),
                            ),
                            subtitle: Text(
                              '${question.answerOptions.length} إجابات - ${question.type.label}',
                              style: const TextStyle(fontFamily: 'Alexandria'),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (context) => EditQuestionDialog(
                                        question: question,
                                        orderIndex: index,
                                        onQuestionEdited: (editedQuestion) {
                                          setState(() {
                                            _questions[index] = editedQuestion;
                                          });
                                        },
                                      ),
                                    );
                                  },
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      _questions.removeAt(index);
                                    });
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      })
                    else
                      Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Text(
                            'لم يتم إضافة أسئلة بعد',
                            style: TextStyle(
                              color: Colors.white30,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Create Button
                    ElevatedButton(
                      onPressed: isLoading ? null : _createCompetition,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green[600],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إنشاء المسابقة',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),

              // Loading Overlay
              if (isLoading)
                Container(
                  color: Colors.white.withValues(alpha: 0.3),
                  child: const Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

// Dialog for adding questions
class AddQuestionDialog extends StatefulWidget {
  final Function(QuestionModel) onQuestionAdded;
  final int orderIndex;

  const AddQuestionDialog({
    super.key,
    required this.onQuestionAdded,
    required this.orderIndex,
  });

  @override
  State<AddQuestionDialog> createState() => _AddQuestionDialogState();
}

class _AddQuestionDialogState extends State<AddQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  final _questionController = TextEditingController();
  final List<AnswerController> _answers = [
    AnswerController(),
    AnswerController(),
  ];
  int _correctAnswerIndex = 0;
  QuestionType _questionType = QuestionType.singleChoice;
  final Set<int> _correctAnswerIndices = {0};
  final _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();
  File? _questionImageFile;
  String? _questionImageUrl;

  @override
  void dispose() {
    _questionController.dispose();
    for (var answer in _answers) {
      answer.dispose();
    }
    super.dispose();
  }

  Future<void> _pickQuestionImage() async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اختر مصدر الصورة',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(
                'من المعرض',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text(
                'من رابط URL',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () => Navigator.pop(context, 'url'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'gallery') {
      await _pickQuestionImageFromGallery();
    } else if (choice == 'url') {
      await _pickQuestionImageFromUrl();
    }
  }

  Future<void> _pickQuestionImageFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _questionImageFile = File(image.path);
          _questionImageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار صورة السؤال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickQuestionImageFromUrl() async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'أدخل رابط صورة السؤال',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                Navigator.pop(context, urlController.text.trim());
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() {
        _questionImageUrl = url;
        _questionImageFile = null;
      });
    }
  }

  Future<void> _pickAnswerImage(int index) async {
    final choice = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'اختر مصدر الصورة',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.photo_library),
              title: const Text(
                'من المعرض',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () => Navigator.pop(context, 'gallery'),
            ),
            ListTile(
              leading: const Icon(Icons.link),
              title: const Text(
                'من رابط URL',
                style: TextStyle(fontFamily: 'Alexandria'),
              ),
              onTap: () => Navigator.pop(context, 'url'),
            ),
          ],
        ),
      ),
    );

    if (choice == 'gallery') {
      await _pickAnswerImageFromGallery(index);
    } else if (choice == 'url') {
      await _pickAnswerImageFromUrl(index);
    }
  }

  Future<void> _pickAnswerImageFromGallery(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _answers[index].imageFile = File(image.path);
          _answers[index].imageUrl = null;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار صورة الإجابة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAnswerImageFromUrl(int index) async {
    final urlController = TextEditingController();
    final url = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text(
          'أدخل رابط صورة الإجابة',
          style: TextStyle(fontFamily: 'Alexandria'),
        ),
        content: TextField(
          controller: urlController,
          decoration: const InputDecoration(
            labelText: 'URL',
            hintText: 'https://example.com/image.jpg',
          ),
          keyboardType: TextInputType.url,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            onPressed: () {
              if (urlController.text.trim().isNotEmpty) {
                Navigator.pop(context, urlController.text.trim());
              }
            },
            child: const Text('تأكيد'),
          ),
        ],
      ),
    );

    if (url != null && url.isNotEmpty) {
      setState(() {
        _answers[index].imageUrl = url;
        _answers[index].imageFile = null;
      });
    }
  }

  void _addAnswer() {
    setState(() {
      _answers.add(AnswerController());
    });
  }

  void _removeAnswer(int index) {
    if (_answers.length > 2) {
      setState(() {
        _answers[index].dispose();
        _answers.removeAt(index);

        // Update correct answer indices
        if (_questionType == QuestionType.singleChoice) {
          if (_correctAnswerIndex >= _answers.length) {
            _correctAnswerIndex = _answers.length - 1;
          } else if (_correctAnswerIndex > index) {
            _correctAnswerIndex--;
          }
        } else if (_questionType == QuestionType.multipleChoice) {
          _correctAnswerIndices.remove(index);
          // Adjust indices greater than removed index
          final newIndices = <int>{};
          for (var i in _correctAnswerIndices) {
            if (i > index) {
              newIndices.add(i - 1);
            } else {
              newIndices.add(i);
            }
          }
          _correctAnswerIndices.clear();
          _correctAnswerIndices.addAll(newIndices);
        }
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate at least one correct answer for multiple choice
    if (_questionType == QuestionType.multipleChoice && _correctAnswerIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار إجابة صحيحة واحدة على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Upload question image if exists
      String? questionImageUrl = _questionImageUrl;
      if (_questionImageFile != null) {
        questionImageUrl = await _uploadImage(_questionImageFile!, 'questions');
      }

      // Upload answer images if they exist
      final answerOptions = <AnswerOptionModel>[];
      for (var answer in _answers) {
        String? answerImageUrl = answer.imageUrl;
        if (answer.imageFile != null) {
          answerImageUrl = await _uploadImage(answer.imageFile!, 'answers');
        }

        answerOptions.add(AnswerOptionModel(
          id: _uuid.v4(),
          answerText: answer.controller.text.trim(),
          imageUrl: answerImageUrl,
        ));
      }

      String? correctAnswerId;
      List<String>? correctAnswerIds;

      if (_questionType == QuestionType.singleChoice ||
          _questionType == QuestionType.trueFalse ||
          _questionType == QuestionType.images) {
        // For images type, check if using multiple choice mode
        if (_questionType == QuestionType.images && _correctAnswerIndices.length > 1) {
          correctAnswerIds = _correctAnswerIndices
              .map((index) => answerOptions[index].id)
              .toList();
        } else {
          correctAnswerId = answerOptions[_correctAnswerIndex].id;
        }
      } else if (_questionType == QuestionType.multipleChoice) {
        correctAnswerIds = _correctAnswerIndices
            .map((index) => answerOptions[index].id)
            .toList();
      }

      final question = QuestionModel(
        questionText: _questionController.text.trim(),
        type: _questionType,
        answerOptions: answerOptions,
        correctAnswerId: correctAnswerId,
        correctAnswerIds: correctAnswerIds,
        orderIndex: widget.orderIndex,
        imageUrl: questionImageUrl,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        widget.onQuestionAdded(question);
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل رفع الصور: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadImage(File imageFile, String folder) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = _uuid.v4().substring(0, 8);
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('competitions/$folder/${timestamp}_$random.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'إضافة سؤال',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [

              // Question Type
              DropdownButtonFormField<QuestionType>(
                value: _questionType,
                style: const TextStyle(color: Colors.black, fontFamily: 'Alexandria'),
                decoration: InputDecoration(
                  labelText: 'نوع السؤال',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                items: QuestionType.values.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(type.label),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value != null) {
                    setState(() {
                      _questionType = value;
                      if (_questionType == QuestionType.trueFalse) {
                        // Set true/false answers
                        _answers.clear();
                        _answers.add(AnswerController()..controller.text = 'صح');
                        _answers.add(AnswerController()..controller.text = 'خطأ');
                        _correctAnswerIndex = 0;
                        _correctAnswerIndices.clear();
                      } else if (_questionType == QuestionType.multipleChoice) {
                        _correctAnswerIndices.clear();
                        _correctAnswerIndices.add(0);
                      }
                    });
                  }
                },
              ),
              const SizedBox(height: 16),

              // Question Text
              TextFormField(
                controller: _questionController,
                style: const TextStyle(color: Colors.black),
                decoration: InputDecoration(
                  labelText: 'نص السؤال',
                  labelStyle: const TextStyle(color: Colors.black),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                maxLines: 2,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'يرجى إدخال نص السؤال';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Question Image (for images type or optional for other types)
              if (_questionType == QuestionType.images || _questionImageFile != null || _questionImageUrl != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'صورة السؤال',
                            style: TextStyle(
                              color: Colors.black,
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                          if (_questionImageFile != null || _questionImageUrl != null)
                            IconButton(
                              icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                              onPressed: () {
                                setState(() {
                                  _questionImageFile = null;
                                  _questionImageUrl = null;
                                });
                              },
                            ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_questionImageFile != null || _questionImageUrl != null)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: _questionImageFile != null
                              ? Image.file(
                                  _questionImageFile!,
                                  height: 150,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _questionImageUrl!,
                                  height: 150,
                                  fit: BoxFit.cover,
                                  loadingBuilder: (context, child, loadingProgress) {
                                    if (loadingProgress == null) return child;
                                    return SizedBox(
                                      height: 150,
                                      child: Center(
                                        child: CircularProgressIndicator(
                                          value: loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                  loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      ),
                                    );
                                  },
                                  errorBuilder: (context, error, stackTrace) {
                                    return Container(
                                      height: 150,
                                      color: Colors.grey[200],
                                      child: const Center(
                                        child: Icon(Icons.error, color: Colors.red, size: 40),
                                      ),
                                    );
                                  },
                                ),
                        )
                      else
                        OutlinedButton.icon(
                          onPressed: _pickQuestionImage,
                          icon: const Icon(Icons.add_photo_alternate),
                          label: const Text('اختر صورة السؤال'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ),
              if (_questionType == QuestionType.images || _questionImageFile != null || _questionImageUrl != null)
                const SizedBox(height: 16),

              // Answers
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _answers.length,
                itemBuilder: (context, index) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade300),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                if (_questionType == QuestionType.singleChoice || _questionType == QuestionType.trueFalse)
                                  Radio<int>(
                                    value: index,
                                    groupValue: _correctAnswerIndex,
                                    onChanged: (value) {
                                      if (value != null) {
                                        setState(() {
                                          _correctAnswerIndex = value;
                                        });
                                      }
                                    },
                                    activeColor: Colors.green[600],
                                  )
                                else
                                  Checkbox(
                                    value: _correctAnswerIndices.contains(index),
                                    onChanged: (value) {
                                      setState(() {
                                        if (value == true) {
                                          _correctAnswerIndices.add(index);
                                        } else {
                                          _correctAnswerIndices.remove(index);
                                        }
                                      });
                                    },
                                    activeColor: Colors.green[600],
                                  ),
                                Expanded(
                                  child: TextFormField(
                                    controller: _answers[index].controller,
                                    style: const TextStyle(color: Colors.black),
                                    decoration: InputDecoration(
                                      labelText: 'إجابة ${index + 1}',
                                      labelStyle: const TextStyle(color: Colors.black),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                    ),
                                    enabled: _questionType != QuestionType.trueFalse,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'يرجى إدخال الإجابة';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                if (_answers.length > 2 && _questionType != QuestionType.trueFalse)
                                  IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () => _removeAnswer(index),
                                  ),
                              ],
                            ),
                            // Answer image (for images type or optional)
                            if (_questionType == QuestionType.images || _answers[index].imageFile != null || _answers[index].imageUrl != null)
                              Padding(
                                padding: const EdgeInsets.only(top: 8, right: 48),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.stretch,
                                  children: [
                                    if (_answers[index].imageFile != null || _answers[index].imageUrl != null)
                                      Stack(
                                        children: [
                                          ClipRRect(
                                            borderRadius: BorderRadius.circular(8),
                                            child: _answers[index].imageFile != null
                                                ? Image.file(
                                                    _answers[index].imageFile!,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  )
                                                : Image.network(
                                                    _answers[index].imageUrl!,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    loadingBuilder: (context, child, loadingProgress) {
                                                      if (loadingProgress == null) return child;
                                                      return SizedBox(
                                                        height: 100,
                                                        child: Center(
                                                          child: CircularProgressIndicator(
                                                            value: loadingProgress.expectedTotalBytes != null
                                                                ? loadingProgress.cumulativeBytesLoaded /
                                                                    loadingProgress.expectedTotalBytes!
                                                                : null,
                                                          ),
                                                        ),
                                                      );
                                                    },
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 100,
                                                        color: Colors.grey[200],
                                                        child: const Center(
                                                          child: Icon(Icons.error, color: Colors.red),
                                                        ),
                                                      );
                                                    },
                                                  ),
                                          ),
                                          Positioned(
                                            top: 4,
                                            right: 4,
                                            child: IconButton(
                                              icon: const Icon(Icons.delete, color: Colors.red),
                                              style: IconButton.styleFrom(
                                                backgroundColor: Colors.white,
                                                padding: const EdgeInsets.all(4),
                                              ),
                                              onPressed: () {
                                                setState(() {
                                                  _answers[index].imageFile = null;
                                                  _answers[index].imageUrl = null;
                                                });
                                              },
                                            ),
                                          ),
                                        ],
                                      )
                                    else
                                      OutlinedButton.icon(
                                        onPressed: () => _pickAnswerImage(index),
                                        icon: const Icon(Icons.add_photo_alternate, size: 16),
                                        label: const Text(
                                          'إضافة صورة',
                                          style: TextStyle(fontSize: 12),
                                        ),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.green[600],
                                          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),

              // Add Answer Button (not for true/false)
              if (_questionType != QuestionType.trueFalse)
                TextButton.icon(
                  onPressed: _addAnswer,
                  icon: const Icon(Icons.add),
                  label: const Text('إضافة إجابة'),
                  style: TextButton.styleFrom(
                    foregroundColor: Colors.green[600],
                  ),
                ),
            ],
          ),
        ),
      ),

      // Save Button at bottom
      const Divider(height: 1),
      Padding(
        padding: const EdgeInsets.all(16),
        child: ElevatedButton(
          onPressed: _saveQuestion,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green[600],
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: const Text(
            'حفظ السؤال',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              fontFamily: 'Alexandria',
            ),
          ),
        ),
      ),
    ],
          ),
        ),
      ),
    );
  }
}

class AnswerController {
  final TextEditingController controller = TextEditingController();
  File? imageFile;
  String? imageUrl;

  void dispose() {
    controller.dispose();
  }
}

// Dialog for editing questions
class EditQuestionDialog extends StatefulWidget {
  final QuestionModel question;
  final Function(QuestionModel) onQuestionEdited;
  final int orderIndex;

  const EditQuestionDialog({
    super.key,
    required this.question,
    required this.onQuestionEdited,
    required this.orderIndex,
  });

  @override
  State<EditQuestionDialog> createState() => _EditQuestionDialogState();
}

class _EditQuestionDialogState extends State<EditQuestionDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _questionController;
  late final List<AnswerController> _answers;
  late int _correctAnswerIndex;
  late QuestionType _questionType;
  late final Set<int> _correctAnswerIndices;
  final _uuid = const Uuid();
  final ImagePicker _picker = ImagePicker();
  File? _questionImageFile;
  String? _questionImageUrl;

  @override
  void initState() {
    super.initState();

    // Initialize with existing question data
    _questionController = TextEditingController(text: widget.question.questionText);
    _questionType = widget.question.type;
    _questionImageUrl = widget.question.imageUrl;

    // Initialize answers from existing question
    _answers = widget.question.answerOptions.map((answer) {
      final controller = AnswerController();
      controller.controller.text = answer.answerText;
      controller.imageUrl = answer.imageUrl;
      return controller;
    }).toList();

    // Initialize correct answer(s)
    _correctAnswerIndices = {};
    if (widget.question.correctAnswerIds != null) {
      // Multiple choice
      for (var correctId in widget.question.correctAnswerIds!) {
        final index = widget.question.answerOptions.indexWhere((a) => a.id == correctId);
        if (index != -1) {
          _correctAnswerIndices.add(index);
        }
      }
      _correctAnswerIndex = _correctAnswerIndices.isNotEmpty ? _correctAnswerIndices.first : 0;
    } else if (widget.question.correctAnswerId != null) {
      // Single choice
      final index = widget.question.answerOptions.indexWhere(
        (a) => a.id == widget.question.correctAnswerId
      );
      _correctAnswerIndex = index != -1 ? index : 0;
      _correctAnswerIndices.add(_correctAnswerIndex);
    } else {
      _correctAnswerIndex = 0;
      _correctAnswerIndices.add(0);
    }
  }

  @override
  void dispose() {
    _questionController.dispose();
    for (var answer in _answers) {
      answer.dispose();
    }
    super.dispose();
  }

  Future<void> _pickQuestionImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _questionImageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار صورة السؤال: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickAnswerImage(int index) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _answers[index].imageFile = File(image.path);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل اختيار صورة الإجابة: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _addAnswer() {
    setState(() {
      _answers.add(AnswerController());
    });
  }

  void _removeAnswer(int index) {
    if (_answers.length > 2) {
      setState(() {
        _answers[index].dispose();
        _answers.removeAt(index);

        // Update correct answer indices
        if (_questionType == QuestionType.singleChoice) {
          if (_correctAnswerIndex >= _answers.length) {
            _correctAnswerIndex = _answers.length - 1;
          } else if (_correctAnswerIndex > index) {
            _correctAnswerIndex--;
          }
        } else if (_questionType == QuestionType.multipleChoice) {
          _correctAnswerIndices.remove(index);
          // Adjust indices greater than removed index
          final newIndices = <int>{};
          for (var i in _correctAnswerIndices) {
            if (i > index) {
              newIndices.add(i - 1);
            } else {
              newIndices.add(i);
            }
          }
          _correctAnswerIndices.clear();
          _correctAnswerIndices.addAll(newIndices);
        }
      });
    }
  }

  Future<void> _saveQuestion() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate at least one correct answer for multiple choice
    if (_questionType == QuestionType.multipleChoice && _correctAnswerIndices.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('يرجى اختيار إجابة صحيحة واحدة على الأقل'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Show loading
    if (mounted) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    try {
      // Upload question image if new image selected
      String? questionImageUrl = _questionImageUrl;
      if (_questionImageFile != null) {
        questionImageUrl = await _uploadImage(_questionImageFile!, 'questions');
      }

      // Upload answer images if they exist
      final answerOptions = <AnswerOptionModel>[];
      for (int i = 0; i < _answers.length; i++) {
        final answer = _answers[i];
        String? answerImageUrl = answer.imageUrl;

        // Upload new image if selected
        if (answer.imageFile != null) {
          answerImageUrl = await _uploadImage(answer.imageFile!, 'answers');
        }

        // Use existing answer ID if available, otherwise generate new
        String answerId;
        if (i < widget.question.answerOptions.length) {
          answerId = widget.question.answerOptions[i].id;
        } else {
          answerId = _uuid.v4();
        }

        answerOptions.add(AnswerOptionModel(
          id: answerId,
          answerText: answer.controller.text.trim(),
          imageUrl: answerImageUrl,
        ));
      }

      String? correctAnswerId;
      List<String>? correctAnswerIds;

      if (_questionType == QuestionType.singleChoice ||
          _questionType == QuestionType.trueFalse ||
          _questionType == QuestionType.images) {
        // For images type, check if using multiple choice mode
        if (_questionType == QuestionType.images && _correctAnswerIndices.length > 1) {
          correctAnswerIds = _correctAnswerIndices
              .map((index) => answerOptions[index].id)
              .toList();
        } else {
          correctAnswerId = answerOptions[_correctAnswerIndex].id;
        }
      } else if (_questionType == QuestionType.multipleChoice) {
        correctAnswerIds = _correctAnswerIndices
            .map((index) => answerOptions[index].id)
            .toList();
      }

      final editedQuestion = QuestionModel(
        questionText: _questionController.text.trim(),
        type: _questionType,
        answerOptions: answerOptions,
        correctAnswerId: correctAnswerId,
        correctAnswerIds: correctAnswerIds,
        orderIndex: widget.orderIndex,
        imageUrl: questionImageUrl,
      );

      if (mounted) {
        Navigator.pop(context); // Close loading
        widget.onQuestionEdited(editedQuestion);
        Navigator.pop(context); // Close dialog
      }
    } catch (e) {
      if (mounted) {
        Navigator.pop(context); // Close loading
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل حفظ التعديلات: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<String> _uploadImage(File imageFile, String folder) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = _uuid.v4().substring(0, 8);
      final storage = FirebaseStorage.instance;
      final ref = storage.ref().child('competitions/$folder/${timestamp}_$random.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 500, maxHeight: 700),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'تعديل السؤال',
                      style: TextStyle(
                        color: Colors.black,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Scrollable content
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Question Type
                      DropdownButtonFormField<QuestionType>(
                        value: _questionType,
                        style: const TextStyle(color: Colors.black, fontFamily: 'Alexandria'),
                        decoration: InputDecoration(
                          labelText: 'نوع السؤال',
                          labelStyle: const TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        items: QuestionType.values.map((type) {
                          return DropdownMenuItem(
                            value: type,
                            child: Text(type.label),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              _questionType = value;
                              if (_questionType == QuestionType.trueFalse) {
                                // Set true/false answers
                                _answers.clear();
                                _answers.add(AnswerController()..controller.text = 'صح');
                                _answers.add(AnswerController()..controller.text = 'خطأ');
                                _correctAnswerIndex = 0;
                                _correctAnswerIndices.clear();
                              } else if (_questionType == QuestionType.multipleChoice) {
                                _correctAnswerIndices.clear();
                                _correctAnswerIndices.add(0);
                              }
                            });
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Question Text
                      TextFormField(
                        controller: _questionController,
                        style: const TextStyle(color: Colors.black),
                        decoration: InputDecoration(
                          labelText: 'نص السؤال',
                          labelStyle: const TextStyle(color: Colors.black),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        maxLines: 2,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'يرجى إدخال نص السؤال';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Question Image
                      if (_questionType == QuestionType.images || _questionImageFile != null || _questionImageUrl != null)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text(
                                    'صورة السؤال',
                                    style: TextStyle(
                                      color: Colors.black,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                  if (_questionImageFile != null || _questionImageUrl != null)
                                    IconButton(
                                      icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                                      onPressed: () {
                                        setState(() {
                                          _questionImageFile = null;
                                          _questionImageUrl = null;
                                        });
                                      },
                                    ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (_questionImageFile != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    _questionImageFile!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              else if (_questionImageUrl != null)
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.network(
                                    _questionImageUrl!,
                                    height: 150,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return Container(
                                        height: 150,
                                        color: Colors.grey[200],
                                        child: const Icon(Icons.error),
                                      );
                                    },
                                  ),
                                )
                              else
                                OutlinedButton.icon(
                                  onPressed: _pickQuestionImage,
                                  icon: const Icon(Icons.add_photo_alternate),
                                  label: const Text('اختر صورة السؤال'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.green[600],
                                  ),
                                ),
                              if (_questionImageFile == null && _questionImageUrl != null)
                                Padding(
                                  padding: const EdgeInsets.only(top: 8),
                                  child: OutlinedButton.icon(
                                    onPressed: _pickQuestionImage,
                                    icon: const Icon(Icons.edit),
                                    label: const Text('تغيير الصورة'),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: Colors.blue[600],
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      if (_questionType == QuestionType.images || _questionImageFile != null || _questionImageUrl != null)
                        const SizedBox(height: 16),

                      // Answers
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _answers.length,
                        itemBuilder: (context, index) {
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 12),
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade300),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      if (_questionType == QuestionType.singleChoice || _questionType == QuestionType.trueFalse)
                                        Radio<int>(
                                          value: index,
                                          groupValue: _correctAnswerIndex,
                                          onChanged: (value) {
                                            if (value != null) {
                                              setState(() {
                                                _correctAnswerIndex = value;
                                              });
                                            }
                                          },
                                          activeColor: Colors.green[600],
                                        )
                                      else
                                        Checkbox(
                                          value: _correctAnswerIndices.contains(index),
                                          onChanged: (value) {
                                            setState(() {
                                              if (value == true) {
                                                _correctAnswerIndices.add(index);
                                              } else {
                                                _correctAnswerIndices.remove(index);
                                              }
                                            });
                                          },
                                          activeColor: Colors.green[600],
                                        ),
                                      Expanded(
                                        child: TextFormField(
                                          controller: _answers[index].controller,
                                          style: const TextStyle(color: Colors.black),
                                          decoration: InputDecoration(
                                            labelText: 'إجابة ${index + 1}',
                                            labelStyle: const TextStyle(color: Colors.black),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                          ),
                                          enabled: _questionType != QuestionType.trueFalse,
                                          validator: (value) {
                                            if (value == null || value.trim().isEmpty) {
                                              return 'يرجى إدخال الإجابة';
                                            }
                                            return null;
                                          },
                                        ),
                                      ),
                                      if (_answers.length > 2 && _questionType != QuestionType.trueFalse)
                                        IconButton(
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                          onPressed: () => _removeAnswer(index),
                                        ),
                                    ],
                                  ),
                                  // Answer image
                                  if (_questionType == QuestionType.images || _answers[index].imageFile != null || _answers[index].imageUrl != null)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 8, right: 48),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.stretch,
                                        children: [
                                          if (_answers[index].imageFile != null)
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.file(
                                                    _answers[index].imageFile!,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      padding: const EdgeInsets.all(4),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _answers[index].imageFile = null;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            )
                                          else if (_answers[index].imageUrl != null)
                                            Stack(
                                              children: [
                                                ClipRRect(
                                                  borderRadius: BorderRadius.circular(8),
                                                  child: Image.network(
                                                    _answers[index].imageUrl!,
                                                    height: 100,
                                                    fit: BoxFit.cover,
                                                    errorBuilder: (context, error, stackTrace) {
                                                      return Container(
                                                        height: 100,
                                                        color: Colors.grey[200],
                                                        child: const Icon(Icons.error),
                                                      );
                                                    },
                                                  ),
                                                ),
                                                Positioned(
                                                  top: 4,
                                                  right: 4,
                                                  child: IconButton(
                                                    icon: const Icon(Icons.delete, color: Colors.red),
                                                    style: IconButton.styleFrom(
                                                      backgroundColor: Colors.white,
                                                      padding: const EdgeInsets.all(4),
                                                    ),
                                                    onPressed: () {
                                                      setState(() {
                                                        _answers[index].imageUrl = null;
                                                      });
                                                    },
                                                  ),
                                                ),
                                              ],
                                            )
                                          else
                                            OutlinedButton.icon(
                                              onPressed: () => _pickAnswerImage(index),
                                              icon: const Icon(Icons.add_photo_alternate, size: 16),
                                              label: const Text(
                                                'إضافة صورة',
                                                style: TextStyle(fontSize: 12),
                                              ),
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.green[600],
                                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                              ),
                                            ),
                                          if (_answers[index].imageFile == null && _answers[index].imageUrl != null)
                                            Padding(
                                              padding: const EdgeInsets.only(top: 4),
                                              child: OutlinedButton.icon(
                                                onPressed: () => _pickAnswerImage(index),
                                                icon: const Icon(Icons.edit, size: 16),
                                                label: const Text(
                                                  'تغيير الصورة',
                                                  style: TextStyle(fontSize: 12),
                                                ),
                                                style: OutlinedButton.styleFrom(
                                                  foregroundColor: Colors.blue[600],
                                                  padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),

                      // Add Answer Button (not for true/false)
                      if (_questionType != QuestionType.trueFalse)
                        TextButton.icon(
                          onPressed: _addAnswer,
                          icon: const Icon(Icons.add),
                          label: const Text('إضافة إجابة'),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.green[600],
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              // Save Button at bottom
              const Divider(height: 1),
              Padding(
                padding: const EdgeInsets.all(16),
                child: ElevatedButton(
                  onPressed: _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green[600],
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text(
                    'حفظ التعديلات',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
