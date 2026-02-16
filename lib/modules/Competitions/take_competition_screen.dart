import 'package:church/core/blocs/competitions/competitions_cubit.dart';
import 'package:church/core/models/competitions/competition_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:flutter/material.dart';

import '../../core/models/class_mapping/class_mapping_model.dart';

class TakeCompetitionScreen extends StatefulWidget {
  final CompetitionModel competition;
  final String userId;
  final UserModel? user; // Optional for backward compatibility

  const TakeCompetitionScreen({
    super.key,
    required this.competition,
    required this.userId,
    this.user,
  });

  @override
  State<TakeCompetitionScreen> createState() => _TakeCompetitionScreenState();
}

class _TakeCompetitionScreenState extends State<TakeCompetitionScreen> {
  final Map<int, List<String>> _userAnswers = {};
  bool _isSubmitted = false;
  double _totalScore = 0.0;
  List<bool> _correctness = [];
  String? _userClassCode;
  bool _isLoadingClassCode = true;
  bool _hasAccess = true;

  @override
  void initState() {
    super.initState();
    _loadUserClassCodeAndCheckAccess();
  }

  /// Load user's classCode from ClassMapping and check access
  Future<void> _loadUserClassCodeAndCheckAccess() async {
    if (widget.user == null) {
      setState(() {
        _isLoadingClassCode = false;
        _hasAccess = true; // No user info, allow access
      });
      return;
    }

    try {
      final userClassName = widget.user!.userClass;
      if (userClassName.isEmpty) {
        setState(() {
          _isLoadingClassCode = false;
          _hasAccess = true; // No class, allow access
        });
        return;
      }

      // Try to get the ClassMapping for this user's class
      final classMappings =
          await ClassMappingService.getActiveClassMappings().first;

      // Find the mapping that matches the user's className
      final userMapping = classMappings.firstWhere(
        (mapping) => mapping.className == userClassName,
        orElse: () => ClassMapping(
          id: '',
          classCode: userClassName, // Fallback: treat className as code
          className: userClassName,
        ),
      );

      final classCode = userMapping.classCode;
      final targetAudience = widget.competition.targetAudience ?? 'all';

      // Check access using classCode
      final canAccess =
          targetAudience == 'all' ||
          targetAudience.isEmpty ||
          CompetitionClassMapping.canAccessCompetition(
            classCode,
            targetAudience,
          );

      if (mounted) {
        setState(() {
          _userClassCode = classCode;
          _hasAccess = canAccess;
          _isLoadingClassCode = false;
        });

        // Show error and navigate back if no access
        if (!canAccess) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('عذراً، هذه المسابقة غير متاحة لصفك الدراسي'),
                  backgroundColor: Colors.red,
                  duration: Duration(seconds: 3),
                ),
              );
              Navigator.pop(context);
            }
          });
        }
      }
    } catch (e) {
      debugPrint('Error loading user class code: $e');
      if (mounted) {
        setState(() {
          _userClassCode = widget.user!.userClass;
          _hasAccess = true; // Fallback: allow access on error
          _isLoadingClassCode = false;
        });
      }
    }
  }

  void _selectAnswer(int questionIndex, String answerId, bool isMultiple) {
    setState(() {
      if (isMultiple) {
        _userAnswers[questionIndex] ??= [];
        if (_userAnswers[questionIndex]!.contains(answerId)) {
          _userAnswers[questionIndex]!.remove(answerId);
        } else {
          _userAnswers[questionIndex]!.add(answerId);
        }
      } else {
        _userAnswers[questionIndex] = [answerId];
      }
    });
  }

  Future<void> _submitAnswers() async {
    // Validate all questions are answered
    for (int i = 0; i < widget.competition.questions.length; i++) {
      if (!_userAnswers.containsKey(i) || _userAnswers[i]!.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('يرجى الإجابة على السؤال ${i + 1}'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
    }

    // Calculate score
    _totalScore = 0.0;
    _correctness = [];
    final pointsPerQuestion = widget.competition.pointsPerQuestion ?? 10.0;

    for (int i = 0; i < widget.competition.questions.length; i++) {
      final question = widget.competition.questions[i];
      final userAnswer = _userAnswers[i]!;
      final isCorrect = question.isCorrectAnswer(userAnswer);

      _correctness.add(isCorrect);
      if (isCorrect) {
        // Use question-specific points if available, otherwise use default pointsPerQuestion
        _totalScore += (question.points ?? pointsPerQuestion);
      }
    }

    setState(() {
      _isSubmitted = true;
    });

    // Save score to user account
    final cubit = CompetitionsCubit.get(context);
    await cubit.submitCompetitionResult(
      userId: widget.userId,
      competitionId: widget.competition.id!,
      score: _totalScore,
      totalQuestions: widget.competition.questions.length,
      correctAnswers: _correctness.where((c) => c).length,
    );

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ النتيجة! لقد حصلت على $_totalScore نقطة'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Show loading state while checking access
    if (_isLoadingClassCode) {
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
            ),
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                child: Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: Colors.white),
                    ),
                    const Expanded(
                      child: Text(
                        'جاري التحميل...',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        body: const Center(
          child: CircularProgressIndicator(color: Colors.green),
        ),
      );
    }

    // Access check is now done in _loadUserClassCodeAndCheckAccess
    // If no access, user is already navigated back
    if (!_hasAccess) {
      return const SizedBox.shrink();
    }

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
                        Text(
                          widget.competition.competitionName,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.competition.numberOfQuestions} سؤال',
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
                      Icons.quiz,
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
      body: Column(
        children: [
          // Competition Info Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [const Color(0xFF43A047), const Color(0xFF66BB6A)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              children: [
                if (widget.competition.imageUrl != null)
                  Container(
                    width: 100,
                    height: 100,
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(13),
                      child: Image.network(
                        widget.competition.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            color: Colors.white.withValues(alpha: 0.2),
                            child: const Icon(
                              Icons.sports_score,
                              size: 50,
                              color: Colors.white,
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                if (widget.competition.description != null)
                  Text(
                    widget.competition.description!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontFamily: 'Alexandria',
                    ),
                    textAlign: TextAlign.center,
                  ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildInfoChip(
                      Icons.quiz_outlined,
                      '${widget.competition.numberOfQuestions} سؤال',
                    ),
                    _buildInfoChip(
                      Icons.card_giftcard,
                      '${widget.competition.totalPoints?.toStringAsFixed(2) ?? "0"} نقطة',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Questions List
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: widget.competition.questions.length,
              itemBuilder: (context, index) {
                final question = widget.competition.questions[index];
                final isCorrect = _isSubmitted && _correctness.isNotEmpty
                    ? _correctness[index]
                    : null;

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  elevation: 4,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: isCorrect != null
                        ? BorderSide(
                            color: isCorrect ? Colors.green : Colors.red,
                            width: 2,
                          )
                        : BorderSide.none,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Question Header
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: isCorrect == null
                                    ? const Color(0xFF43A047)
                                    : (isCorrect ? Colors.green : Colors.red),
                                shape: BoxShape.circle,
                              ),
                              child: Text(
                                '${index + 1}',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    question.questionText,
                                    style: const TextStyle(
                                      color: Colors.black,
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    question.type.label,
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                      fontFamily: 'Alexandria',
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (isCorrect != null)
                              Icon(
                                isCorrect ? Icons.check_circle : Icons.cancel,
                                color: isCorrect ? Colors.green : Colors.red,
                                size: 28,
                              ),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // Question Image (if exists)
                        if (question.imageUrl != null &&
                            question.imageUrl!.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 16),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Image.network(
                                question.imageUrl!,
                                fit: BoxFit.cover,
                                width: double.infinity,
                                loadingBuilder:
                                    (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Container(
                                        height: 200,
                                        alignment: Alignment.center,
                                        child: CircularProgressIndicator(
                                          value:
                                              loadingProgress
                                                      .expectedTotalBytes !=
                                                  null
                                              ? loadingProgress
                                                        .cumulativeBytesLoaded /
                                                    loadingProgress
                                                        .expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 200,
                                    alignment: Alignment.center,
                                    color: Colors.grey[200],
                                    child: const Icon(
                                      Icons.error,
                                      size: 48,
                                      color: Colors.grey,
                                    ),
                                  );
                                },
                              ),
                            ),
                          ),

                        // Answer Options
                        ...question.answerOptions.asMap().entries.map((entry) {
                          final option = entry.value;
                          final isSelected =
                              _userAnswers[index]?.contains(option.id) ?? false;
                          final isMultiple =
                              question.type == QuestionType.multipleChoice;

                          // Show correct answer after submission
                          bool? isThisCorrect;
                          if (_isSubmitted) {
                            if (question.type == QuestionType.multipleChoice) {
                              isThisCorrect = question.correctAnswerIds
                                  ?.contains(option.id);
                            } else {
                              isThisCorrect =
                                  question.correctAnswerId == option.id;
                            }
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: InkWell(
                              onTap: _isSubmitted
                                  ? null
                                  : () => _selectAnswer(
                                      index,
                                      option.id,
                                      isMultiple,
                                    ),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: _isSubmitted
                                      ? (isThisCorrect == true
                                            ? Colors.green.withValues(
                                                alpha: 0.1,
                                              )
                                            : (isSelected
                                                  ? Colors.red.withValues(
                                                      alpha: 0.1,
                                                    )
                                                  : Colors.transparent))
                                      : (isSelected
                                            ? const Color(
                                                0xFF43A047,
                                              ).withValues(alpha: 0.1)
                                            : Colors.transparent),
                                  border: Border.all(
                                    color: _isSubmitted
                                        ? (isThisCorrect == true
                                              ? Colors.green
                                              : (isSelected
                                                    ? Colors.red
                                                    : Colors.grey[300]!))
                                        : (isSelected
                                              ? const Color(0xFF43A047)
                                              : Colors.grey[300]!),
                                    width: 2,
                                  ),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  children: [
                                    if (isMultiple)
                                      Icon(
                                        isSelected
                                            ? Icons.check_box
                                            : Icons.check_box_outline_blank,
                                        color: _isSubmitted
                                            ? (isThisCorrect == true
                                                  ? Colors.green
                                                  : (isSelected
                                                        ? Colors.red
                                                        : Colors.grey))
                                            : (isSelected
                                                  ? const Color(0xFF43A047)
                                                  : Colors.grey),
                                      )
                                    else
                                      Icon(
                                        isSelected
                                            ? Icons.radio_button_checked
                                            : Icons.radio_button_unchecked,
                                        color: _isSubmitted
                                            ? (isThisCorrect == true
                                                  ? Colors.green
                                                  : (isSelected
                                                        ? Colors.red
                                                        : Colors.grey))
                                            : (isSelected
                                                  ? const Color(0xFF43A047)
                                                  : Colors.grey),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            option.answerText,
                                            style: TextStyle(
                                              color: Colors.black,
                                              fontSize: 14,
                                              fontFamily: 'Alexandria',
                                            ),
                                          ),
                                          // Answer Image (if exists)
                                          if (option.imageUrl != null &&
                                              option.imageUrl!.isNotEmpty)
                                            Padding(
                                              padding: const EdgeInsets.only(
                                                top: 8,
                                              ),
                                              child: ClipRRect(
                                                borderRadius:
                                                    BorderRadius.circular(8),
                                                child: Image.network(
                                                  option.imageUrl!,
                                                  height: 100,
                                                  fit: BoxFit.cover,
                                                  loadingBuilder: (context, child, loadingProgress) {
                                                    if (loadingProgress == null)
                                                      return child;
                                                    return Container(
                                                      height: 100,
                                                      alignment:
                                                          Alignment.center,
                                                      child: CircularProgressIndicator(
                                                        value:
                                                            loadingProgress
                                                                    .expectedTotalBytes !=
                                                                null
                                                            ? loadingProgress
                                                                      .cumulativeBytesLoaded /
                                                                  loadingProgress
                                                                      .expectedTotalBytes!
                                                            : null,
                                                      ),
                                                    );
                                                  },
                                                  errorBuilder:
                                                      (
                                                        context,
                                                        error,
                                                        stackTrace,
                                                      ) {
                                                        return Container(
                                                          height: 100,
                                                          alignment:
                                                              Alignment.center,
                                                          color:
                                                              Colors.grey[200],
                                                          child: const Icon(
                                                            Icons.error,
                                                            size: 24,
                                                            color: Colors.grey,
                                                          ),
                                                        );
                                                      },
                                                ),
                                              ),
                                            ),
                                        ],
                                      ),
                                    ),
                                    if (_isSubmitted && isThisCorrect == true)
                                      const Icon(
                                        Icons.check,
                                        color: Colors.green,
                                      ),
                                    if (_isSubmitted &&
                                        isSelected &&
                                        isThisCorrect != true)
                                      const Icon(
                                        Icons.close,
                                        color: Colors.red,
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Submit/Results Button
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: const Offset(0, -3),
                ),
              ],
            ),
            child: _isSubmitted
                ? Column(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              const Color(0xFF43A047),
                              const Color(0xFF66BB6A),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Column(
                              children: [
                                const Text(
                                  'النتيجة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_totalScore.toStringAsFixed(2)}/${widget.competition.totalPoints?.toStringAsFixed(2) ?? "0"}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              width: 2,
                              height: 50,
                              color: Colors.white.withValues(alpha: 0.3),
                            ),
                            Column(
                              children: [
                                const Text(
                                  'إجابات صحيحة',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '${_correctness.where((c) => c).length}/${widget.competition.numberOfQuestions}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(Icons.check_circle),
                          label: const Text(
                            'إنهاء',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF43A047),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  )
                : SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitAnswers,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF43A047),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'إرسال الإجابات',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 18, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.bold,
              fontFamily: 'Alexandria',
            ),
          ),
        ],
      ),
    );
  }
}
