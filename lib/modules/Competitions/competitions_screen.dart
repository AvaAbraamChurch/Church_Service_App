import 'package:church/core/blocs/competitions/competitions_cubit.dart';
import 'package:church/core/blocs/competitions/competitions_states.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/modules/Competitions/create_competition_screen.dart';
import 'package:church/modules/Competitions/edit_competition_screen.dart';
import 'package:church/modules/Competitions/take_competition_card_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../core/models/user/user_model.dart';

// FIX summary
// -----------
// 1. Removed the dead StreamBuilder that wrapped the whole build() method.
//    `_classCodeStream` was never defined, so the app would crash immediately.
//    The class code is read directly from `widget.user.userClass` – it is a
//    plain string on the user document, no stream needed.
//
// 2. Admin routing fix: priests / servants now call `loadAllCompetitions()`
//    instead of `loadCompetitionsByClass()`, so they see every competition.
//
// 3. User list fix: regular users now read from `cubit.activeCompetitions`
//    (populated by `loadCompetitionsByClass`) rather than `cubit.allCompetitions`.
//    Both are exposed by `displayList`, so we just keep using that – the cubit
//    fix in `displayList` already prefers `activeCompetitions` over `allCompetitions`.
//
// 4. Removed the unused `gender_enum.dart` import.

class CompetitionsScreen extends StatefulWidget {
  final UserModel user;
  final UserType type;
  final bool isAdmin;

  const CompetitionsScreen({
    super.key,
    required this.user,
    required this.type,
    required this.isAdmin,
  });

  @override
  State<CompetitionsScreen> createState() => _CompetitionsScreenState();
}

class _CompetitionsScreenState extends State<CompetitionsScreen> {
  // competitionId -> result data
  final Map<String, Map<String, dynamic>> _userResults = {};
  bool _loadingResults = false;
  bool _pendingResultsReload = false;

  bool get _isAdminUser =>
      widget.type.code == UserType.priest.code ||
      widget.type.code == UserType.superServant.code ||
      widget.type.code == UserType.servant.code;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _loadUserResults(
    List competitions,
    CompetitionsCubit cubit,
  ) async {
    if (_loadingResults) {
      _pendingResultsReload = true;
      return;
    }

    setState(() => _loadingResults = true);

    for (var competition in competitions) {
      if (competition.id != null) {
        final result = await cubit.getUserCompetitionResult(
          widget.user.id,
          competition.id,
        );
        if (result != null && mounted) {
          setState(() => _userResults[competition.id] = result);
        }
      }
    }

    if (mounted) setState(() => _loadingResults = false);

    if (_pendingResultsReload) {
      _pendingResultsReload = false;
      await _loadUserResults(competitions, cubit);
    }
  }

  Future<void> _refreshCompetitionsAfterAction(
    CompetitionsCubit cubit,
  ) async {
    _userResults.clear();
    _pendingResultsReload = false;
    if (_isAdminUser) {
      await cubit.loadAllCompetitions();
    } else {
      final userClass = widget.user.userClass.trim();
      if (userClass.isEmpty) {
        await cubit.loadActiveCompetitions();
      } else {
        await cubit.loadCompetitionsByClass(userClass);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    // FIX: plain synchronous value – no StreamBuilder needed.
    final classCode = widget.user.userClass.trim();

    return BlocProvider(
      create: (context) {
        final cubit = CompetitionsCubit();

        if (_isAdminUser) {
          // FIX: admins always load ALL competitions.
          cubit.loadAllCompetitions();
        } else {
          if (classCode.isEmpty) {
            cubit.loadActiveCompetitions();
          } else {
            // FIX: passes the class *name* string that matches what
            //      `targetClasses` stores in Firestore.
            cubit.loadCompetitionsByClass(classCode);
          }
        }

        return cubit;
      },
      child: BlocConsumer<CompetitionsCubit, CompetitionsState>(
        listener: (context, state) {},
        builder: (context, state) {
          final cubit = CompetitionsCubit.get(context);

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
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 8,
                    ),
                    child: Row(
                      children: [
                        IconButton(
                          onPressed: () => Navigator.pop(context),
                          icon: const Icon(
                            Icons.arrow_back,
                            color: Colors.white,
                          ),
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
            floatingActionButton: _isAdminUser
                ? FloatingActionButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => BlocProvider.value(
                            value: cubit,
                            child: const CreateCompetitionScreen(),
                          ),
                        ),
                      ).then((_) async {
                        if (!mounted) return;
                        await _refreshCompetitionsAfterAction(cubit);
                      });
                    },
                    backgroundColor: Colors.green[600],
                    child: const Icon(Icons.add, color: Colors.white),
                  )
                : null,
            body: BlocBuilder<CompetitionsCubit, CompetitionsState>(
              builder: (context, state) {
                // FIX: `displayList` now correctly returns `activeCompetitions`
                //      for regular users (populated by loadCompetitionsByClass)
                //      and `allCompetitions` for admins.
                final competitions = cubit.displayList ?? [];

                // Eagerly load user results once competitions arrive.
                if (state is LoadCompetitionsSuccess &&
                    competitions.isNotEmpty &&
                    !_isAdminUser &&
                    !_loadingResults &&
                    _userResults.isEmpty) {
                  Future.microtask(
                    () => _loadUserResults(competitions, cubit),
                  );
                }

                if (state is LoadCompetitionsLoading && competitions.isEmpty) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.green),
                  );
                }

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
                          onPressed: () =>
                              _refreshCompetitionsAfterAction(cubit),
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

                // Categorise competitions.
                final now = DateTime.now();
                final List newCompetitions = [];
                final List solvedCompetitions = [];
                final List expiredCompetitions = [];
                final List activeCompetitionsList = [];
                final List notActiveCompetitions = [];

                if (_isAdminUser) {
                  for (var c in competitions) {
                    if (c.isActive ?? true) {
                      activeCompetitionsList.add(c);
                    } else {
                      notActiveCompetitions.add(c);
                    }
                  }
                } else {
                  for (var c in competitions) {
                    final userResult =
                        c.id != null ? _userResults[c.id] : null;
                    final isCompleted = userResult != null;
                    final isExpired =
                        (c.endDate != null && c.endDate!.isBefore(now)) ||
                        !(c.isActive ?? true);

                    if (isCompleted) {
                      solvedCompetitions.add(c);
                    } else if (isExpired) {
                      expiredCompetitions.add(c);
                    } else {
                      newCompetitions.add(c);
                    }
                  }
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (_isAdminUser) ...[
                        if (activeCompetitionsList.isNotEmpty)
                          _buildCategoryExpansionTile(
                            title: 'مسابقات نشطة',
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            count: activeCompetitionsList.length,
                            competitions: activeCompetitionsList,
                            cubit: cubit,
                            initiallyExpanded: true,
                          ),
                        const SizedBox(height: 12),
                        if (notActiveCompetitions.isNotEmpty)
                          _buildCategoryExpansionTile(
                            title: 'مسابقات غير نشطة',
                            icon: Icons.cancel_outlined,
                            color: Colors.grey,
                            count: notActiveCompetitions.length,
                            competitions: notActiveCompetitions,
                            cubit: cubit,
                            isExpired: true,
                            initiallyExpanded: false,
                          ),
                      ] else ...[
                        if (newCompetitions.isNotEmpty)
                          _buildCategoryExpansionTile(
                            title: 'مسابقات جديدة',
                            icon: Icons.new_releases,
                            color: Colors.blue,
                            count: newCompetitions.length,
                            competitions: newCompetitions,
                            cubit: cubit,
                            initiallyExpanded: true,
                          ),
                        const SizedBox(height: 12),
                        if (solvedCompetitions.isNotEmpty)
                          _buildCategoryExpansionTile(
                            title: 'المسابقات المحلولة',
                            icon: Icons.check_circle,
                            color: Colors.green,
                            count: solvedCompetitions.length,
                            competitions: solvedCompetitions,
                            cubit: cubit,
                            initiallyExpanded: false,
                          ),
                        const SizedBox(height: 12),
                        if (expiredCompetitions.isNotEmpty)
                          _buildCategoryExpansionTile(
                            title: 'مسابقات منتهية',
                            icon: Icons.access_time,
                            color: Colors.grey,
                            count: expiredCompetitions.length,
                            competitions: expiredCompetitions,
                            cubit: cubit,
                            isExpired: true,
                            initiallyExpanded: false,
                          ),
                      ],
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  void _handleCompetitionTap(
    BuildContext context,
    CompetitionsCubit cubit,
    competition,
    bool isCompleted,
  ) {
    if (_isAdminUser) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: EditCompetitionScreen(
              competition: competition,
              userType: widget.type,
              isAdmin: widget.isAdmin,
            ),
          ),
        ),
      ).then((_) async {
        if (!mounted) return;
        await _refreshCompetitionsAfterAction(cubit);
      });
      return;
    }

    // Regular user path.
    if (!(competition.isActive ?? true)) {
      _showNotAvailableDialog(context);
      return;
    }

    final now = DateTime.now();
    if (competition.endDate != null && competition.endDate.isBefore(now)) {
      _showExpiredDialog(context);
      return;
    }

    if (isCompleted) {
      _showCompletionDialog(context, competition);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => BlocProvider.value(
            value: cubit,
            child: TakeCompetitionCardScreen(
              competition: competition,
              userId: widget.user.id,
              user: widget.user,
            ),
          ),
        ),
      ).then((_) {
        if (!mounted) return;
        _refreshCompetitionsAfterAction(cubit);
      });
    }
  }

  void _showCompletionDialog(BuildContext context, competition) {
    final result = _userResults[competition.id];
    if (result == null) return;

    final score = (result['score'] is int)
        ? (result['score'] as int).toDouble()
        : (result['score'] as double? ?? 0.0);
    final totalQuestions = (result['totalQuestions'] is int)
        ? (result['totalQuestions'] as int).toDouble()
        : (result['totalQuestions'] as double? ?? 0.0);
    final correctAnswers = result['correctAnswers'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
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
                        value: score.toStringAsFixed(2),
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
                        value: totalQuestions.toStringAsFixed(0),
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
              style: TextStyle(fontFamily: 'Alexandria', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showNotAvailableDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.orange[100],
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.info_outline,
                color: Colors.orange[700],
                size: 32,
              ),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'مسابقة غير متاحة',
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
                  colors: [Colors.orange[50]!, Colors.orange[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.lock_outline, size: 48, color: Colors.orange[700]),
                  const SizedBox(height: 16),
                  Text(
                    'هذه المسابقة غير متاحة حالياً',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.orange[900],
                      fontFamily: 'Alexandria',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'سيتم إتاحتها قريباً',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontFamily: 'Alexandria',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(fontFamily: 'Alexandria', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  void _showExpiredDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.red[100],
                shape: BoxShape.circle,
              ),
              child: Icon(Icons.access_time, color: Colors.red[700], size: 32),
            ),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                'مسابقة منتهية',
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
                  colors: [Colors.red[50]!, Colors.red[100]!],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  Icon(Icons.event_busy, size: 48, color: Colors.red[700]),
                  const SizedBox(height: 16),
                  Text(
                    'انتهى وقت هذه المسابقة',
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.red[900],
                      fontFamily: 'Alexandria',
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'لا يمكن المشاركة في هذه المسابقة بعد الآن',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                      fontFamily: 'Alexandria',
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text(
              'حسناً',
              style: TextStyle(fontFamily: 'Alexandria', fontSize: 16),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryExpansionTile({
    required String title,
    required IconData icon,
    required MaterialColor color,
    required int count,
    required List competitions,
    required CompetitionsCubit cubit,
    bool isExpired = false,
    bool initiallyExpanded = true,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color[50]!, color[100]!],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: initiallyExpanded,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          childrenPadding: const EdgeInsets.only(
            bottom: 12,
            left: 12,
            right: 12,
          ),
          backgroundColor: Colors.transparent,
          collapsedBackgroundColor: Colors.transparent,
          iconColor: color[900],
          collapsedIconColor: color[900],
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color[200],
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color[700], size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: color[900],
                    fontFamily: 'Alexandria',
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: color[700],
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$count',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ),
            ],
          ),
          children: competitions.map((competition) {
            final userResult =
                competition.id != null ? _userResults[competition.id] : null;
            final isCompleted = userResult != null;
            return Padding(
              padding: const EdgeInsets.only(top: 8),
              child: buildCompetitionCard(
                competition: competition,
                userResult: userResult,
                isCompleted: isCompleted,
                isExpired: isExpired,
                onTap: () => _handleCompetitionTap(
                  context,
                  cubit,
                  competition,
                  isCompleted,
                ),
              ),
            );
          }).toList(),
        ),
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
          decoration: BoxDecoration(color: color[100], shape: BoxShape.circle),
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
    bool isExpired = false,
    required VoidCallback onTap,
  }) {
    final score = userResult != null
        ? ((userResult['score'] is int)
              ? (userResult['score'] as int).toDouble()
              : (userResult['score'] as double? ?? 0.0))
        : 0.0;
    final totalQuestions = userResult != null
        ? ((userResult['totalQuestions'] is int)
              ? (userResult['totalQuestions'] as int).toDouble()
              : (userResult['totalQuestions'] as double? ?? 0.0))
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isExpired
              ? [Colors.grey[100]!, Colors.grey[200]!]
              : isCompleted
              ? [Colors.green[50]!, Colors.green[100]!]
              : [Colors.white, Colors.green[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: isExpired
            ? Border.all(color: Colors.grey[400]!, width: 2)
            : isCompleted
            ? Border.all(color: Colors.green[600]!, width: 2)
            : null,
        boxShadow: [
          BoxShadow(
            color: isExpired
                ? Colors.grey.withValues(alpha: 0.3)
                : isCompleted
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
              if (isCompleted)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
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
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
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
                )
              else if (isExpired)
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.access_time, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'منتهية',
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
                )
              else
                Positioned(
                  top: 12,
                  right: 12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.blue[600],
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.withValues(alpha: 0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.fiber_new, color: Colors.white, size: 16),
                        SizedBox(width: 4),
                        Text(
                          'جديد',
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 40.0),
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
                                  'نتيجتك: ${score.toStringAsFixed(2)} نقطة',
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
                                  'من ${totalQuestions.toStringAsFixed(0)} سؤال',
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
                                    competition.targetClasses.isEmpty
                                        ? 'متاحة لجميع الصفوف'
                                        : 'متاحة لـ: ${competition.targetClasses.join(", ")}',
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
                                  '${competition.totalPoints?.toStringAsFixed(2) ?? "0"} نقطة',
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
                            // Show target audience for admin users
                            if (_isAdminUser)
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: Colors.purple[100],
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Icon(
                                      Icons.people,
                                      size: 16,
                                      color: Colors.purple[700],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      competition.targetClasses.isEmpty
                                          ? 'متاحة لجميع الصفوف'
                                          : 'الصفوف: ${competition.targetClasses.join(", ")}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Colors.purple[700],
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
                            child: competition.imageUrl != null &&
                                    competition.imageUrl.isNotEmpty
                                ? Image.network(
                                    competition.imageUrl,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) =>
                                        _buildPlaceholderIcon(),
                                    loadingBuilder:
                                        (context, child, loadingProgress) {
                                          if (loadingProgress == null) {
                                            return child;
                                          }
                                          return Center(
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              value: loadingProgress
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
                                  )
                                : _buildPlaceholderIcon(),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: isCompleted
                                ? Colors.green[200]
                                : Colors.green[100],
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isCompleted
                                    ? Icons.remove_red_eye
                                    : Icons.arrow_forward_ios,
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
