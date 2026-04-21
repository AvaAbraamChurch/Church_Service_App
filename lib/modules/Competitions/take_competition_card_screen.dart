import 'package:church/core/blocs/competitions/competitions_cubit.dart';
import 'package:church/core/models/competitions/competition_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:flutter/material.dart';

import '../../core/models/class_mapping/class_mapping_model.dart';
import '../../core/styles/colors.dart';
// Answer-option accent colours (one per slot, cycling)
const List<Color> _optionColors = [
  Color(0xFF009CA6), // teal500
  Color(0xFF005A69), // teal700
  Color(0xFF75D1CF), // teal300
  Color(0xFF003844), // teal900
];

class TakeCompetitionCardScreen extends StatefulWidget {
  final CompetitionModel competition;
  final String userId;
  final UserModel? user;

  const TakeCompetitionCardScreen({
    super.key,
    required this.competition,
    required this.userId,
    this.user,
  });

  @override
  State<TakeCompetitionCardScreen> createState() =>
      _TakeCompetitionCardScreenState();
}

class _TakeCompetitionCardScreenState extends State<TakeCompetitionCardScreen>
    with TickerProviderStateMixin {
  final Map<int, List<String>> _userAnswers = {};
  bool _isSubmitted = false;
  double _totalScore = 0.0;
  List<bool> _correctness = [];
  bool _isLoadingClassCode = true;
  bool _hasAccess = true;
  late PageController _pageController;
  int _currentQuestionIndex = 0;
  late AnimationController _fadeController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _fadeController = AnimationController(
      duration: const Duration(milliseconds: 350),
      vsync: this,
    );
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _fadeController.forward();
    });
    _loadUserClassCodeAndCheckAccess();
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  // ── Access-check logic (unchanged) ────────────────────────────────────────
  Future<void> _loadUserClassCodeAndCheckAccess() async {
    if (widget.user == null) {
      setState(() {
        _isLoadingClassCode = false;
        _hasAccess = true;
      });
      return;
    }

    try {
      final userClassName = widget.user!.userClass;
      if (userClassName.isEmpty) {
        setState(() {
          _isLoadingClassCode = false;
          _hasAccess = true;
        });
        return;
      }

      final classMappings =
          await ClassMappingService.getActiveClassMappings().first;

      final userMapping = classMappings.firstWhere(
        (mapping) => mapping.className == userClassName,
        orElse: () => ClassMapping(
          id: '',
          classCode: userClassName,
          className: userClassName,
        ),
      );

      final classCode     = userMapping.classCode;
      final targetAudience = widget.competition.targetAudience ?? 'all';

      final canAccess =
          targetAudience == 'all' ||
          targetAudience.isEmpty ||
          CompetitionClassMapping.canAccessCompetition(classCode, targetAudience);

      if (mounted) {
        setState(() {
          _hasAccess            = canAccess;
          _isLoadingClassCode   = false;
        });

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
      if (mounted) {
        setState(() {
          _hasAccess          = true;
          _isLoadingClassCode = false;
        });
      }
    }
  }

  // ── Answer helpers ─────────────────────────────────────────────────────────
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

  void _goToNextQuestion() {
    if (_currentQuestionIndex < widget.competition.questions.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  void _goToPreviousQuestion() {
    if (_currentQuestionIndex > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _submitAnswers() async {
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

    _totalScore  = 0.0;
    _correctness = [];
    final pointsPerQuestion = widget.competition.pointsPerQuestion ?? 10.0;

    for (int i = 0; i < widget.competition.questions.length; i++) {
      final question  = widget.competition.questions[i];
      final userAnswer = _userAnswers[i]!;
      final isCorrect = question.isCorrectAnswer(userAnswer);

      _correctness.add(isCorrect);
      if (isCorrect) _totalScore += (question.points ?? pointsPerQuestion);
    }

    setState(() => _isSubmitted = true);

    final cubit = CompetitionsCubit.get(context);
    await cubit.submitCompetitionResult(
      userId: widget.userId,
      competitionId: widget.competition.id!,
      score: _totalScore,
      totalQuestions: widget.competition.questions.length,
      correctAnswers: _correctness.where((c) => c).length,
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم حفظ النتيجة! لقد حصلت على $_totalScore نقطة'),
          backgroundColor: teal700,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  // ── build ──────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_isLoadingClassCode) return _buildLoadingScreen();
    if (!_hasAccess)         return const SizedBox.shrink();
    if (_isSubmitted)        return _buildResultsScreen();
    return _buildQuizScreen();
  }

  // ── Loading screen ─────────────────────────────────────────────────────────
  Widget _buildLoadingScreen() {
    return ThemedScaffold(
      appBar: _buildAppBar(
        title: 'جاري التحميل..',
        subtitle: null,
      ),
      body: const Center(
        child: CircularProgressIndicator(color: teal500),
      ),
    );
  }

  // ── Quiz screen ────────────────────────────────────────────────────────────
  Widget _buildQuizScreen() {
    final total    = widget.competition.numberOfQuestions;
    final current  = _currentQuestionIndex + 1;
    final progress = current / total;

    return ThemedScaffold(
      appBar: _buildAppBar(
        title:    widget.competition.competitionName,
        subtitle: 'السؤال $current من $total',
        trailing: _pill('$current/$total'),
      ),
      body: Column(
        children: [
          // ── Progress bar ──
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'التقدم',
                      style: TextStyle(
                        fontSize: 12,
                        color: teal700,
                        fontFamily: 'Alexandria',
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: const TextStyle(
                        fontSize: 12,
                        color: teal700,
                        fontFamily: 'Alexandria',
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: progress,
                    minHeight: 8,
                    backgroundColor: teal100,
                    valueColor: const AlwaysStoppedAnimation<Color>(teal500),
                  ),
                ),
              ],
            ),
          ),

          // ── Questions ──
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              physics: const NeverScrollableScrollPhysics(),
              onPageChanged: (index) {
                setState(() {
                  _currentQuestionIndex = index;
                  _fadeController.forward(from: 0);
                });
              },
              itemCount: widget.competition.questions.length,
              itemBuilder: (context, index) => _buildQuestionCard(index),
            ),
          ),

          // ── Bottom action bar ──
          _buildBottomBar(),
        ],
      ),
    );
  }

  // ── Bottom bar ─────────────────────────────────────────────────────────────
  Widget _buildBottomBar() {
    final isFirst = _currentQuestionIndex == 0;
    final isLast  = _currentQuestionIndex ==
        widget.competition.questions.length - 1;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: teal900.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Prev / Next row
          Row(
            children: [
              Expanded(
                child: _navButton(
                  label: 'السابق',
                  icon: Icons.arrow_back_ios_new_rounded,
                  onPressed: isFirst ? null : _goToPreviousQuestion,
                  isPrimary: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _navButton(
                  label: 'التالي',
                  icon: Icons.arrow_forward_ios_rounded,
                  onPressed: isLast ? null : _goToNextQuestion,
                  isPrimary: false,
                  iconTrailing: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Submit button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton.icon(
              onPressed: _submitAnswers,
              icon: const Icon(Icons.check_circle_outline_rounded, size: 22),
              label: const Text(
                'إنهاء المسابقة',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  fontFamily: 'Alexandria',
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: teal700,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Question card ──────────────────────────────────────────────────────────
  Widget _buildQuestionCard(int index) {
    final question   = widget.competition.questions[index];
    final isAnswered =
        _userAnswers.containsKey(index) && _userAnswers[index]!.isNotEmpty;

    return FadeTransition(
      opacity: _fadeController,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Question bubble ──
            Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                gradient: const LinearGradient(
                  colors: [teal700, teal500],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: teal500.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.20),
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Text(
                      'السؤال ${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    question.questionText,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Alexandria',
                      height: 1.5,
                    ),
                  ),
                  // Optional image
                  if (question.imageUrl != null &&
                      question.imageUrl!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          question.imageUrl!,
                          fit: BoxFit.cover,
                          height: 180,
                          errorBuilder: (_, __, ___) => Container(
                            height: 180,
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Icon(Icons.image,
                                size: 48, color: Colors.white),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ── Hint label ──
            Row(
              children: [
                Icon(
                  isAnswered
                      ? Icons.check_circle_rounded
                      : Icons.touch_app_rounded,
                  size: 18,
                  color: isAnswered ? teal500 : teal300,
                ),
                const SizedBox(width: 6),
                Text(
                  isAnswered ? 'تم اختيار إجابة' : 'اختر الإجابة الصحيحة',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isAnswered ? teal700 : teal500,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // ── Answer options ──
            ...question.answerOptions.asMap().entries.map((entry) {
              final option     = entry.value;
              final isSelected =
                  _userAnswers[index]?.contains(option.id) ?? false;
              final isMultiple =
                  question.type == QuestionType.multipleChoice;

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: _buildAnswerButton(
                  option:      option,
                  isSelected:  isSelected,
                  isMultiple:  isMultiple,
                  optionIndex: entry.key,
                  onTap: () =>
                      _selectAnswer(index, option.id, isMultiple),
                ),
              );
            }),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  // ── Answer button ──────────────────────────────────────────────────────────
  // FIX: removed BackdropFilter – it was blurring the entire page because it
  // had no bounded parent. The glassy effect is replaced with a clean solid
  // card that matches the teal palette.
  Widget _buildAnswerButton({
    required AnswerOptionModel option,
    required bool isSelected,
    required bool isMultiple,
    required VoidCallback onTap,
    required int optionIndex,
  }) {
    final accent = _optionColors[optionIndex % _optionColors.length];

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: isSelected ? accent : teal50,
          border: Border.all(
            color: isSelected ? accent : teal200,
            width: isSelected ? 2.5 : 1.5,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: accent.withValues(alpha: 0.30),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : [],
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              // Icon circle
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected
                      ? Colors.white.withValues(alpha: 0.25)
                      : accent.withValues(alpha: 0.12),
                ),
                child: Icon(
                  isMultiple
                      ? (isSelected
                          ? Icons.check_box_rounded
                          : Icons.check_box_outline_blank_rounded)
                      : (isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_unchecked_rounded),
                  color: isSelected ? Colors.white : accent,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Answer text + optional image
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      option.answerText,
                      style: TextStyle(
                        color: isSelected ? Colors.white : teal900,
                        fontSize: 15,
                        fontWeight: isSelected
                            ? FontWeight.bold
                            : FontWeight.w500,
                        fontFamily: 'Alexandria',
                        height: 1.35,
                      ),
                    ),
                    if (option.imageUrl != null &&
                        option.imageUrl!.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(10),
                          child: Image.network(
                            option.imageUrl!,
                            height: 90,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => Container(
                              height: 90,
                              color: teal100,
                              child: const Icon(Icons.image),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Selection check mark
              if (isSelected) ...[
                const SizedBox(width: 8),
                Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(alpha: 0.30),
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  // ── Results screen ─────────────────────────────────────────────────────────
  Widget _buildResultsScreen() {
    final correctCount      = _correctness.where((c) => c).length;
    final percentage        =
        ((correctCount / widget.competition.numberOfQuestions) * 100).toInt();
    final totalPossiblePoints = widget.competition.totalPoints ?? 0.0;

    Color performanceColor() {
      if (percentage >= 80) return const Color(0xFF00897B); // teal-green
      if (percentage >= 60) return const Color(0xFFF9A825); // amber
      return const Color(0xFFE53935);                        // red
    }

    String performanceMessage() {
      if (percentage >= 90) return '👏 ممتاز جداً!';
      if (percentage >= 80) return '👍 رائع!';
      if (percentage >= 70) return '😊 جيد جداً!';
      if (percentage >= 60) return '📚 جيد!';
      return '💪 حاول مرة أخرى!';
    }

    final pColor = performanceColor();

    return ThemedScaffold(
      appBar: _buildAppBar(
        title:    'النتائج',
        subtitle: null,
        trailing: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.20),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(
            Icons.emoji_events_rounded,
            color: Colors.white,
            size: 28,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 32),
        child: Column(
          children: [
            // Performance message
            Text(
              performanceMessage(),
              style: const TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                fontFamily: 'Alexandria',
              ),
            ),
            const SizedBox(height: 24),

            // Score circle
            Container(
              width: 180,
              height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    Color.lerp(pColor, Colors.white, 0.25) ?? pColor,
                    pColor,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: pColor.withValues(alpha: 0.35),
                    blurRadius: 24,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$percentage%',
                    style: const TextStyle(
                      fontSize: 60,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  Text(
                    'من الإجابات',
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.white.withValues(alpha: 0.9),
                      fontFamily: 'Alexandria',
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Stats cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.check_circle_rounded,
                    title: 'إجابات صحيحة',
                    value:
                        '$correctCount/${widget.competition.numberOfQuestions}',
                    color: const Color(0xFF00897B),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    icon: Icons.emoji_events_rounded,
                    title: 'النقاط',
                    value:
                        '${_totalScore.toStringAsFixed(0)}/${totalPossiblePoints.toStringAsFixed(0)}',
                    color: teal500,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Question summary
            if (_correctness.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: teal50,
                  border: Border.all(color: teal100, width: 1.5),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(
                          Icons.list_alt_rounded,
                          color: teal500,
                          size: 22,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'ملخص الأسئلة',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                            color: teal900,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ...List.generate(_correctness.length, (index) {
                      final ok = _correctness[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: ok
                                    ? const Color(0xFFE0F2F1)
                                    : const Color(0xFFFFEBEE),
                              ),
                              child: Icon(
                                ok
                                    ? Icons.check_rounded
                                    : Icons.close_rounded,
                                color: ok
                                    ? const Color(0xFF00897B)
                                    : Colors.red,
                                size: 22,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'السؤال ${index + 1}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: teal900,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ),
                            Text(
                              ok ? '✓ صحيح' : '✗ خطأ',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: ok
                                    ? const Color(0xFF00897B)
                                    : Colors.red,
                                fontFamily: 'Alexandria',
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

            const SizedBox(height: 28),

            // Back home button
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.home_rounded, size: 22),
                label: const Text(
                  'العودة للرئيسية',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alexandria',
                  ),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal700,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Shared sub-widgets ─────────────────────────────────────────────────────

  /// Unified teal app-bar used across all three screens.
  PreferredSizeWidget _buildAppBar({
    required String title,
    required String? subtitle,
    Widget? trailing,
  }) {
    return PreferredSize(
      preferredSize: const Size.fromHeight(64),
      child: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [teal900, teal700],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: Color(0x33000000),
              blurRadius: 8,
              offset: Offset(0, 3),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(
                    Icons.arrow_back_ios_new_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  tooltip: 'رجوع',
                ),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Alexandria',
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle,
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.80),
                            fontSize: 11,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (trailing != null) trailing,
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.20),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  Widget _navButton({
    required String label,
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isPrimary,
    bool iconTrailing = false,
  }) {
    final enabled = onPressed != null;
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: enabled ? teal500 : const Color(0xFFE0E0E0),
          foregroundColor: enabled ? Colors.white : Colors.grey,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: iconTrailing
              ? [
                  Text(label,
                      style: const TextStyle(
                        fontFamily: 'Alexandria',
                        fontWeight: FontWeight.bold,
                      )),
                  const SizedBox(width: 6),
                  Icon(icon, size: 16),
                ]
              : [
                  Icon(icon, size: 16),
                  const SizedBox(width: 6),
                  Text(label,
                      style: const TextStyle(
                        fontFamily: 'Alexandria',
                        fontWeight: FontWeight.bold,
                      )),
                ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String title,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: color.withValues(alpha: 0.08),
        border: Border.all(
          color: color.withValues(alpha: 0.25),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 30),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: teal700,
              fontFamily: 'Alexandria',
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
              fontFamily: 'Alexandria',
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

// A small helper so Border.all can reference teal200 without importing theme.
const Color teal200 = Color(0xFFAAE4E2);
