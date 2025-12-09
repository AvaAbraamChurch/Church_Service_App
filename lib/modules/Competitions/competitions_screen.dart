import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/core/utils/classes_mapping.dart';
import 'package:church/core/blocs/competitions/competitions_cubit.dart';
import 'package:church/core/blocs/competitions/competitions_states.dart';
import 'package:church/modules/Competitions/create_competition_screen.dart';
import 'package:church/modules/Competitions/edit_competition_screen.dart';
import 'package:church/modules/Competitions/take_competition_screen.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/models/user/user_model.dart';

class CompetitionsScreen extends StatefulWidget {
  final UserModel user;
  final UserType type;
  final bool isAdmin;

  const CompetitionsScreen({
    super.key,
    required this.user,
    required this.type,
    required this.isAdmin
  });

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  // Store user's competition results: competitionId -> result data
  final Map<String, Map<String, dynamic>> _userResults = {};
  bool _loadingResults = false;

  /// Load user results for all competitions
  Future<void> _loadUserResults(List competitions, CompetitionsCubit cubit) async {
    if (_loadingResults) return;

    setState(() {
      _loadingResults = true;
    });

    for (var competition in competitions) {
      if (competition.id != null) {
        final result = await cubit.getUserCompetitionResult(
          widget.user.id,
          competition.id,
        );

        if (result != null && mounted) {
          setState(() {
            _userResults[competition.id] = result;
          });
        }
      }
    }

    if (mounted) {
      setState(() {
        _loadingResults = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (BuildContext context) => CompetitionsCubit()..loadActiveCompetitions(),
      child: BlocConsumer<CompetitionsCubit, CompetitionsState>(
        builder: (BuildContext context, state) {
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
                                'المسابقات',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'اختبر معرفتك واكسب كوبونات',
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
                            Icons.sports_score,
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
            floatingActionButton:
            widget.type.code == UserType.priest.code ||
                widget.type.code == UserType.superServant.code ||
                widget.type.code == UserType.servant.code
                ? FloatingActionButton(
              onPressed: () {
                final cubit = CompetitionsCubit.get(context);
                navigateTo(
                  context,
                  BlocProvider.value(
                    value: cubit,
                    child: const CreateCompetitionScreen(),
                  ),
                );
              },
              backgroundColor: Colors.green[600],
              child: const Icon(Icons.add, color: Colors.white),
            )
                : null,
            body: BlocBuilder<CompetitionsCubit, CompetitionsState>(
              builder: (context, state) {
                final cubit = CompetitionsCubit.get(context);
                final allCompetitions = cubit.displayList ?? [];

                // Filter competitions based on user's class
                // Servants/priests/superServants see all competitions for management
                final List competitions;
                if (widget.type.code == UserType.priest.code ||
                    widget.type.code == UserType.superServant.code ||
                    widget.type.code == UserType.servant.code) {
                  competitions = allCompetitions;
                } else {
                  // Regular users only see competitions they can access
                  competitions = allCompetitions.where((competition) {
                    final targetAudience = competition.targetAudience ?? 'all';
                    return CompetitionClassMapping.canAccessCompetition(
                      widget.user.userClass,
                      targetAudience,
                    );
                  }).toList();
                }

                // Load user results when competitions are loaded
                if (state is LoadCompetitionsSuccess && competitions.isNotEmpty && !_loadingResults && _userResults.isEmpty) {
                  Future.microtask(() => _loadUserResults(competitions, cubit));
                }

                // Show loading indicator
                if (state is LoadCompetitionsLoading && competitions.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(
                      color: Colors.green,
                    ),
                  );
                }

                // Show error message
                if (state is LoadCompetitionsError && competitions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: Colors.red[300],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'حدث خطأ في تحميل المسابقات',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.red[700],
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          state.error,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontFamily: 'Alexandria',
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 24),
                        ElevatedButton.icon(
                          onPressed: () => cubit.loadActiveCompetitions(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('إعادة المحاولة'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green[600],
                            foregroundColor: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                // Show empty state
                if (competitions.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.sports_score_outlined,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'لا توجد مسابقات متاحة حالياً',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey[600],
                            fontFamily: 'Alexandria',
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'سيتم إضافة مسابقات جديدة قريباً',
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

                // Show competitions list
                return Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: ListView.builder(
                    itemCount: competitions.length,
                    itemBuilder: (context, index) {
                      final competition = competitions[index];
                      final userResult = competition.id != null ? _userResults[competition.id] : null;
                      final isCompleted = userResult != null;

                      return buildCompetitionCard(
                        competition: competition,
                        userResult: userResult,
                        isCompleted: isCompleted,
                        onTap: () => _handleCompetitionTap(context, competition, isCompleted),
                      );
                    },
                  ),
                );
              },
            ),
          );
        },
        listener: (BuildContext context, state) {  },
      ),
    );
  }

  void _handleCompetitionTap(BuildContext context, competition, bool isCompleted) {
    final cubit = CompetitionsCubit.get(context);
    final userId = widget.user.id;

    // If user is priest, super servant, or servant -> show edit screen
    if (widget.type.code == UserType.priest.code ||
        widget.type.code == UserType.superServant.code ||
        widget.type.code == UserType.servant.code) {
      navigateTo(
        context,
        BlocProvider.value(
          value: cubit,
          child: EditCompetitionScreen(
            competition: competition,
            userType: widget.type,
            isAdmin: widget.isAdmin,
          ),
        ),
      );
    }
    // If user is child or other types
    else {
      // If competition is already completed, show score dialog
      if (isCompleted) {
        _showCompletionDialog(context, competition);
      } else {
        // Navigate to take competition screen
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BlocProvider.value(
              value: cubit,
              child: TakeCompetitionScreen(
                competition: competition,
                userId: userId,
                user: widget.user,
              ),
            ),
          ),
        ).then((_) {
          // Reload results after completing competition
          if (mounted) {
            final cubit = CompetitionsCubit.get(context);
            final competitions = cubit.displayList ?? [];
            _userResults.clear();
            _loadUserResults(competitions, cubit);
          }
        });
      }
    }
  }

  /// Show dialog with user's score and completion status
  void _showCompletionDialog(BuildContext context, competition) {
    final result = _userResults[competition.id];
    if (result == null) return;

    final score = result['score'] as int? ?? 0;
    final totalQuestions = result['totalQuestions'] as int? ?? 0;
    final correctAnswers = result['correctAnswers'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.green[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle,
                color: Colors.green[700],
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'تم إنهاء المسابقة',
                style: TextStyle(
                  fontFamily: 'Alexandria',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.green[50]!, Colors.green[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Text(
                    'نتيجتك',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.green[900],
                      fontFamily: 'Alexandria',
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildScoreItem(
                        icon: Icons.card_giftcard,
                        label: 'النقاط',
                        value: '$score',
                        color: Colors.amber,
                      ),
                      _buildScoreItem(
                        icon: Icons.check_circle,
                        label: 'صحيحة',
                        value: '$correctAnswers',
                        color: Colors.green,
                      ),
                      _buildScoreItem(
                        icon: Icons.quiz,
                        label: 'الأسئلة',
                        value: '$totalQuestions',
                        color: Colors.blue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'لقد أكملت هذه المسابقة من قبل',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontFamily: 'Alexandria',
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(
                fontFamily: 'Alexandria',
                fontSize: 16,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreItem({
    required IconData icon,
    required String label,
    required String value,
    required MaterialColor color,
  }) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color[100],
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: color[700], size: 24),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color[900],
            fontFamily: 'Alexandria',
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontFamily: 'Alexandria',
          ),
        ),
      ],
    );
  }

  Widget buildCompetitionCard({
    required competition,
    required Map<String, dynamic>? userResult,
    required bool isCompleted,
    required VoidCallback onTap,
  }) {
    final score = userResult?['score'] as int? ?? 0;
    final totalQuestions = userResult?['totalQuestions'] as int? ?? 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isCompleted
              ? [Colors.green[50]!, Colors.green[100]!]
              : [Colors.white, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isCompleted
            ? Border.all(color: Colors.green[600]!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isCompleted
                ? Colors.green.withValues(alpha: 0.4)
                : Colors.green.withValues(alpha: 0.2),
            blurRadius: 15,
            spreadRadius: 2,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            children: [
              // Completion badge
              if (isCompleted)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: Colors.green[600],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.green.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.check_circle, color: Colors.white, size: 16),
                        const SizedBox(width: 4),
                        const Text(
                          'مكتمل',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Alexandria',
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: [
                    // Competition Details
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SizedBox(height: 40.0,),
                          // Competition Name
                          Text(
                            competition.competitionName,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.green[900],
                              fontFamily: 'Alexandria',
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 8),

                          // Show score if completed, otherwise show questions count
                          if (isCompleted) ...[
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.star,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'نتيجتك: $score نقطة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.check_circle,
                                    size: 16,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  'من $totalQuestions سؤال',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Target Audience (Class)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    CompetitionClassMapping.getClassName(
                                      competition.targetAudience ?? 'all'
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Alexandria',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Number of Questions
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.green[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.quiz_outlined,
                                    size: 16,
                                    color: Colors.green[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${competition.numberOfQuestions} سؤال',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.green[700],
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Total Points
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.amber[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.card_giftcard,
                                    size: 16,
                                    color: Colors.amber[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Text(
                                  '${competition.totalPoints ?? 0} نقطة',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.w600,
                                    fontFamily: 'Alexandria',
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            // Target Audience (Class)
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(6),
                                  decoration: BoxDecoration(
                                    color: Colors.blue[100],
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    Icons.school,
                                    size: 16,
                                    color: Colors.blue[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    CompetitionClassMapping.getClassName(
                                      competition.targetAudience ?? 'all'
                                    ),
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.blue[700],
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'Alexandria',
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Competition Image or Placeholder with text underneath
                    Column(
                      children: [
                        Container(
                          width: 80,
                          height: 80,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(16),
                            gradient: LinearGradient(
                              colors: isCompleted
                                  ? [Colors.green[400]!, Colors.green[700]!]
                                  : [Colors.green[300]!, Colors.green[600]!],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.green.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 3),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(16),
                            child: competition.imageUrl != null && competition.imageUrl.isNotEmpty
                                ? Image.network(
                                    competition.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) {
                                      return _buildPlaceholderIcon();
                                    },
                                    loadingBuilder: (context, child, loadingProgress) {
                                      if (loadingProgress == null) return child;
                                      return Center(
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          value:
                                              loadingProgress.expectedTotalBytes != null
                                              ? loadingProgress.cumulativeBytesLoaded /
                                                    loadingProgress.expectedTotalBytes!
                                              : null,
                                        ),
                                      );
                                    },
                                  )
                                : _buildPlaceholderIcon(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Text under image
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: isCompleted ? Colors.green[200] : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted ? Icons.remove_red_eye : Icons.arrow_forward_ios,
                                size: 14,
                                color: Colors.green[700],
                              ),
                              const SizedBox(width: 4),
                              Text(
                                isCompleted ? 'عرض' : 'ابدأ',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green[700],
                                  fontFamily: 'Alexandria',
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPlaceholderIcon() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.green[300]!, Colors.green[600]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Icon(Icons.sports_score, size: 40, color: Colors.white),
      ),
    );
  }
}
