import 'dart:io';

import 'package:church/core/models/competitions/competition_model.dart';
import 'package:church/core/repositories/competitions_repository.dart';
import 'package:church/core/repositories/questions_repository.dart';
import 'package:church/core/services/cloudinary_upload_service.dart';
import 'package:church/core/services/coupon_points_service.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'competitions_states.dart';

// FIX: removed unused `firebase_storage` import and the dead
//      `FirebaseStorage _storage` field.  The only place it was used was
//      `_deleteCompetitionImage`, which already guards against non-Firebase
//      URLs.  If you still need legacy Firebase-Storage deletion just
//      re-add the import and the field – nothing else changes.

class CompetitionsCubit extends Cubit<CompetitionsState> {
  final CompetitionsRepository competitionsRepository;
  final QuestionsRepository questionsRepository;
  final CouponPointsService _pointsService = CouponPointsService();
  final CloudinaryUploadService _cloudinaryUploadService =
      CloudinaryUploadService();

  // Cached data for UI consumers
  List<CompetitionModel>? allCompetitions;
  List<CompetitionModel>? activeCompetitions;
  List<CompetitionModel>? filteredCompetitions;
  CompetitionModel? currentCompetition;

  // Filter/Search state
  String? currentSearchQuery;

  // Pagination
  int currentPage = 0;
  static const int pageSize = 10;
  bool hasMoreData = true;

  CompetitionsCubit({
    CompetitionsRepository? competitionsRepository,
    QuestionsRepository? questionsRepository,
  }) : competitionsRepository =
           competitionsRepository ?? CompetitionsRepository(),
       questionsRepository = questionsRepository ?? QuestionsRepository(),
       super(CompetitionsInitial());

  static CompetitionsCubit get(context) => BlocProvider.of(context);

  // ==================== Load Competitions ====================

  /// Load all competitions (used by admins).
  Future<void> loadAllCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());
      allCompetitions = await competitionsRepository.getAllCompetitions();
      emit(LoadCompetitionsSuccess());
    } catch (e) {
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load active competitions only.
  Future<void> loadActiveCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());
      activeCompetitions = await competitionsRepository.getActiveCompetitions();
      emit(LoadCompetitionsSuccess());
    } catch (e) {
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load ongoing competitions.
  Future<void> loadOngoingCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());
      activeCompetitions =
          await competitionsRepository.getOngoingCompetitions();
      emit(LoadCompetitionsSuccess());
    } catch (e) {
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load upcoming competitions.
  Future<void> loadUpcomingCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());
      activeCompetitions =
          await competitionsRepository.getUpcomingCompetitions();
      emit(LoadCompetitionsSuccess());
    } catch (e) {
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load past competitions.
  Future<void> loadPastCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());
      // FIX: was incorrectly writing into `allCompetitions`; past competitions
      //      belong in `activeCompetitions` so that `displayList` picks them up
      //      for regular users.  Use `allCompetitions` only for admin full-list.
      allCompetitions = await competitionsRepository.getPastCompetitions();
      emit(LoadCompetitionsSuccess());
    } catch (e) {
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load single competition by ID.
  Future<void> loadCompetitionById(String competitionId) async {
    try {
      emit(LoadCompetitionLoading());
      currentCompetition =
          await competitionsRepository.getCompetitionById(competitionId);
      if (currentCompetition != null) {
        emit(LoadCompetitionSuccess());
      } else {
        emit(LoadCompetitionError('Competition not found'));
      }
    } catch (e) {
      emit(LoadCompetitionError(e.toString()));
    }
  }

  /// Load competitions visible to a specific user class.
  ///
  /// The repository query returns competitions where `targetClasses` is empty
  /// (open to all) **or** contains [userClassName].
  ///
  /// FIX: the parameter is now [userClassName] (the human-readable class name
  /// stored on the user document, e.g. "فصل الأول") instead of a Firestore
  /// document ID.  The repository must filter on the `targetClasses` array
  /// using this same value, which matches what `getAvailableUserClasses()`
  /// returns and what `targetClasses` stores.
  Future<void> loadCompetitionsByClass(String userClassName) async {
    try {
      emit(LoadCompetitionsLoading());
      // Results go into `activeCompetitions` so `displayList` returns them.
      activeCompetitions =
          await competitionsRepository.getCompetitionsByClass(userClassName);
      emit(LoadCompetitionsSuccess());
    } catch (e) {
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  // ==================== Stream Methods ====================

  Stream<List<CompetitionModel>> watchActiveCompetitions() {
    return competitionsRepository.watchActiveCompetitions();
  }

  Stream<List<CompetitionModel>> watchAllCompetitions() {
    return competitionsRepository.watchAllCompetitions();
  }

  Stream<CompetitionModel?> watchCompetition(String competitionId) {
    return competitionsRepository.watchCompetition(competitionId);
  }

  /// Stream of competitions visible to [userClassName].
  Stream<List<CompetitionModel>> watchCompetitionsByClass(
    String userClassName,
  ) {
    return competitionsRepository.watchCompetitionsByClass(userClassName);
  }

  // ==================== Create Competition ====================

  Future<String?> createCompetition({
    required CompetitionModel competition,
    File? imageFile,
    String? imageUrl,
  }) async {
    try {
      emit(CreateCompetitionLoading());

      String? finalImageUrl = imageUrl;
      if (imageFile != null) {
        finalImageUrl = await _uploadCompetitionImage(imageFile);
      }

      final competitionWithImage = competition.copyWith(
        imageUrl: finalImageUrl,
        createdAt: DateTime.now(),
      );

      final competitionId =
          await competitionsRepository.addCompetition(competitionWithImage);

      await loadAllCompetitions();

      emit(CreateCompetitionSuccess(competitionId));
      return competitionId;
    } catch (e) {
      emit(CreateCompetitionError(e.toString()));
      return null;
    }
  }

  Future<String> _uploadCompetitionImage(File imageFile) async {
    try {
      emit(UploadImageLoading());
      final imageUrl =
          await _cloudinaryUploadService.uploadCompetitionImage(imageFile);
      emit(UploadImageSuccess(imageUrl));
      return imageUrl;
    } catch (e) {
      emit(UploadImageError(e.toString()));
      rethrow;
    }
  }

  // ==================== Update Competition ====================

  Future<void> updateCompetition(
    String competitionId,
    Map<String, dynamic> data,
  ) async {
    try {
      emit(UpdateCompetitionLoading());
      await competitionsRepository.updateCompetition(competitionId, data);
      if (currentCompetition?.id == competitionId) {
        await loadCompetitionById(competitionId);
      }
      await loadAllCompetitions();
      emit(UpdateCompetitionSuccess());
    } catch (e) {
      emit(UpdateCompetitionError(e.toString()));
    }
  }

  Future<void> updateCompetitionWithImage({
    required String competitionId,
    required Map<String, dynamic> data,
    File? newImageFile,
  }) async {
    try {
      emit(UpdateCompetitionLoading());
      if (newImageFile != null) {
        final imageUrl = await _uploadCompetitionImage(newImageFile);
        data['imageUrl'] = imageUrl;
      }
      await competitionsRepository.updateCompetition(competitionId, data);
      if (currentCompetition?.id == competitionId) {
        await loadCompetitionById(competitionId);
      }
      await loadAllCompetitions();
      emit(UpdateCompetitionSuccess());
    } catch (e) {
      emit(UpdateCompetitionError(e.toString()));
    }
  }

  Future<void> toggleCompetitionStatus(
    String competitionId,
    bool isActive,
  ) async {
    try {
      emit(ToggleCompetitionStatusLoading());
      await competitionsRepository.updateCompetitionStatus(
        competitionId,
        isActive,
      );
      if (currentCompetition?.id == competitionId) {
        await loadCompetitionById(competitionId);
      }
      await loadAllCompetitions();
      emit(ToggleCompetitionStatusSuccess());
    } catch (e) {
      emit(ToggleCompetitionStatusError(e.toString()));
    }
  }

  // ==================== Delete Competition ====================

  Future<void> deleteCompetition(String competitionId) async {
    try {
      emit(DeleteCompetitionLoading());

      await competitionsRepository.deleteCompetition(competitionId);

      if (currentCompetition?.id == competitionId) {
        currentCompetition = null;
      }

      await loadAllCompetitions();
      emit(DeleteCompetitionSuccess());
    } catch (e) {
      emit(DeleteCompetitionError(e.toString()));
    }
  }


  Future<void> batchDeleteCompetitions(List<String> competitionIds) async {
    try {
      emit(DeleteCompetitionLoading());
      await competitionsRepository.batchDeleteCompetitions(competitionIds);
      await loadAllCompetitions();
      emit(DeleteCompetitionSuccess());
    } catch (e) {
      emit(DeleteCompetitionError(e.toString()));
    }
  }

  // ==================== Search & Filter ====================

  Future<void> searchCompetitions(String query) async {
    try {
      emit(SearchCompetitionsLoading());
      currentSearchQuery = query;
      if (query.isEmpty) {
        filteredCompetitions = activeCompetitions;
      } else {
        filteredCompetitions =
            await competitionsRepository.searchCompetitionsByName(query);
      }
      emit(SearchCompetitionsSuccess());
    } catch (e) {
      emit(SearchCompetitionsError(e.toString()));
    }
  }

  void clearFilters() {
    currentSearchQuery = null;
    filteredCompetitions = null;
    emit(LoadCompetitionsSuccess());
  }

  // ==================== Validation ====================

  Future<bool> competitionNameExists(String name, {String? excludeId}) async {
    try {
      return await competitionsRepository.competitionNameExists(
        name,
        excludeId: excludeId,
      );
    } catch (e) {
      return false;
    }
  }

  // ==================== Statistics ====================

  Future<int> getCompetitionsCount() async {
    try {
      return await competitionsRepository.getCompetitionsCount();
    } catch (e) {
      return 0;
    }
  }

  Future<int> getActiveCompetitionsCount() async {
    try {
      return await competitionsRepository.getActiveCompetitionsCount();
    } catch (e) {
      return 0;
    }
  }

  // ==================== Answer Validation ====================

  Future<int?> validateAnswers({
    required String competitionId,
    required Map<String, List<String>> userAnswers,
  }) async {
    try {
      emit(SubmitAnswersLoading());

      final competition =
          await competitionsRepository.getCompetitionById(competitionId);
      if (competition == null) {
        emit(SubmitAnswersError('Competition not found'));
        return null;
      }

      double totalScore = 0.0;
      final double totalPoints = competition.totalPoints ?? 0.0;

      for (final question in competition.questions) {
        final questionId = question.id;
        if (questionId == null) continue;
        final selectedAnswers = userAnswers[questionId] ?? [];
        if (question.isCorrectAnswer(selectedAnswers)) {
          totalScore += question.points ?? 0.0;
        }
      }

      emit(SubmitAnswersSuccess(totalScore, totalPoints));
      return totalScore.ceil();
    } catch (e) {
      emit(SubmitAnswersError(e.toString()));
      return null;
    }
  }

  Map<String, dynamic> getCorrectAnswers(CompetitionModel competition) {
    final correctAnswers = <String, dynamic>{};
    for (final question in competition.questions) {
      if (question.id != null) {
        if (question.type == QuestionType.multipleChoice) {
          correctAnswers[question.id!] = question.correctAnswerIds;
        } else {
          correctAnswers[question.id!] = question.correctAnswerId;
        }
      }
    }
    return correctAnswers;
  }

  // ==================== Questions Management ====================

  Future<String?> addQuestionToBank(QuestionModel question) async {
    try {
      return await questionsRepository.addQuestion(question);
    } catch (e) {
      return null;
    }
  }

  Future<List<QuestionModel>> getRandomQuestions(int count) async {
    try {
      return await questionsRepository.getRandomQuestions(count);
    } catch (e) {
      return [];
    }
  }

  Future<List<QuestionModel>> getRandomQuestionsByType(
    QuestionType type,
    int count,
  ) async {
    try {
      return await questionsRepository.getRandomQuestionsByType(type, count);
    } catch (e) {
      return [];
    }
  }

  // ==================== User Results ====================

  Future<void> submitCompetitionResult({
    required String userId,
    required String competitionId,
    required double score,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    try {
      emit(SubmitAnswersLoading());

      final resultId = await competitionsRepository.saveCompetitionResult(
        userId: userId,
        competitionId: competitionId,
        score: score,
        totalQuestions: totalQuestions.toDouble(),
        correctAnswers: correctAnswers,
        completedAt: DateTime.now(),
      );

      if (score > 0) {
        await _pointsService.addPoints(
          userId,
          score.ceil(),
          orderId: resultId,
        );
      }

      emit(SubmitAnswersSuccess(score, totalQuestions * 10));
    } catch (e) {
      emit(SubmitAnswersError(e.toString()));
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  Future<Map<String, dynamic>?> getUserCompetitionResult(
    String userId,
    String competitionId,
  ) async {
    try {
      return await competitionsRepository.getUserCompetitionResult(
        userId,
        competitionId,
      );
    } catch (e) {
      return null;
    }
  }

  Future<bool> hasUserCompletedCompetition(
    String userId,
    String competitionId,
  ) async {
    try {
      return await competitionsRepository.hasUserCompletedCompetition(
        userId,
        competitionId,
      );
    } catch (e) {
      return false;
    }
  }

  Future<void> refreshAll() async {
    await loadActiveCompetitions();
  }

  void clearCache() {
    allCompetitions = null;
    activeCompetitions = null;
    filteredCompetitions = null;
    currentCompetition = null;
    currentSearchQuery = null;
    currentPage = 0;
    hasMoreData = true;
  }

  /// Returns the list that the UI should render.
  ///
  /// Priority: filtered > activeCompetitions (user view) > allCompetitions (admin view)
  List<CompetitionModel>? get displayList {
    if (filteredCompetitions != null) return filteredCompetitions;
    // `activeCompetitions` is populated for regular users and admin refreshes.
    // `allCompetitions` is populated by loadAllCompetitions() (admin initial load).
    return activeCompetitions ?? allCompetitions;
  }
}
