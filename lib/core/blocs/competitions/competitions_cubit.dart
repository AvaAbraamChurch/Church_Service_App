import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:church/core/repositories/competitions_repository.dart';
import 'package:church/core/repositories/questions_repository.dart';
import 'package:church/core/models/competitions/competition_model.dart';
import 'package:church/core/services/coupon_points_service.dart';
import 'competitions_states.dart';

class CompetitionsCubit extends Cubit<CompetitionsState> {
  final CompetitionsRepository competitionsRepository;
  final QuestionsRepository questionsRepository;
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final CouponPointsService _pointsService = CouponPointsService();

  // Cached data for UI consumers
  List<CompetitionModel>? allCompetitions;
  List<CompetitionModel>? activeCompetitions;
  List<CompetitionModel>? filteredCompetitions;
  CompetitionModel? currentCompetition;

  // Filter/Search state
  String? currentSearchQuery;
  String? currentAudienceFilter;

  // Pagination
  int currentPage = 0;
  static const int pageSize = 10;
  bool hasMoreData = true;

  CompetitionsCubit({
    CompetitionsRepository? competitionsRepository,
    QuestionsRepository? questionsRepository,
  })  : competitionsRepository = competitionsRepository ?? CompetitionsRepository(),
        questionsRepository = questionsRepository ?? QuestionsRepository(),
        super(CompetitionsInitial());

  static CompetitionsCubit get(context) => BlocProvider.of(context);

  // ==================== Load Competitions ====================

  /// Load all competitions
  Future<void> loadAllCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());

      allCompetitions = await competitionsRepository.getAllCompetitions();

      emit(LoadCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error loading competitions: $e');
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load active competitions only
  Future<void> loadActiveCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());

      activeCompetitions = await competitionsRepository.getActiveCompetitions();

      emit(LoadCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error loading active competitions: $e');
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load ongoing competitions
  Future<void> loadOngoingCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());

      activeCompetitions = await competitionsRepository.getOngoingCompetitions();

      emit(LoadCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error loading ongoing competitions: $e');
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load upcoming competitions
  Future<void> loadUpcomingCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());

      activeCompetitions = await competitionsRepository.getUpcomingCompetitions();

      emit(LoadCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error loading upcoming competitions: $e');
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load past competitions
  Future<void> loadPastCompetitions() async {
    try {
      emit(LoadCompetitionsLoading());

      allCompetitions = await competitionsRepository.getPastCompetitions();

      emit(LoadCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error loading past competitions: $e');
      emit(LoadCompetitionsError(e.toString()));
    }
  }

  /// Load single competition by ID
  Future<void> loadCompetitionById(String competitionId) async {
    try {
      emit(LoadCompetitionLoading());

      currentCompetition = await competitionsRepository.getCompetitionById(competitionId);

      if (currentCompetition != null) {
        emit(LoadCompetitionSuccess());
      } else {
        emit(LoadCompetitionError('Competition not found'));
      }
    } catch (e) {
      debugPrint('Error loading competition: $e');
      emit(LoadCompetitionError(e.toString()));
    }
  }

  /// Load competitions by target audience
  Future<void> loadCompetitionsByAudience(String audience) async {
    try {
      emit(FilterCompetitionsLoading());

      currentAudienceFilter = audience;
      filteredCompetitions = await competitionsRepository.getCompetitionsByAudience(audience);

      emit(FilterCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error filtering competitions by audience: $e');
      emit(FilterCompetitionsError(e.toString()));
    }
  }

  // ==================== Stream Methods ====================

  /// Get stream of active competitions
  Stream<List<CompetitionModel>> watchActiveCompetitions() {
    return competitionsRepository.watchActiveCompetitions();
  }

  /// Get stream of all competitions
  Stream<List<CompetitionModel>> watchAllCompetitions() {
    return competitionsRepository.watchAllCompetitions();
  }

  /// Get stream of single competition
  Stream<CompetitionModel?> watchCompetition(String competitionId) {
    return competitionsRepository.watchCompetition(competitionId);
  }

  /// Get stream of competitions by audience
  Stream<List<CompetitionModel>> watchCompetitionsByAudience(String audience) {
    return competitionsRepository.watchCompetitionsByAudience(audience);
  }

  // ==================== Create Competition ====================

  /// Create a new competition with optional image
  Future<String?> createCompetition({
    required CompetitionModel competition,
    File? imageFile,
  }) async {
    try {
      emit(CreateCompetitionLoading());

      String? imageUrl;

      // Upload image if provided
      if (imageFile != null) {
        imageUrl = await _uploadCompetitionImage(imageFile);
      }

      // Create competition with image URL
      final competitionWithImage = competition.copyWith(
        imageUrl: imageUrl,
        createdAt: DateTime.now(),
      );

      final competitionId = await competitionsRepository.addCompetition(competitionWithImage);

      // Refresh competitions list
      await loadActiveCompetitions();

      emit(CreateCompetitionSuccess(competitionId));
      return competitionId;
    } catch (e) {
      debugPrint('Error creating competition: $e');
      emit(CreateCompetitionError(e.toString()));
      return null;
    }
  }

  /// Upload competition image to Firebase Storage
  Future<String> _uploadCompetitionImage(File imageFile) async {
    try {
      emit(UploadImageLoading());

      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final ref = _storage.ref().child('competitions/images/$timestamp.jpg');

      final uploadTask = ref.putFile(imageFile);
      final snapshot = await uploadTask;
      final imageUrl = await snapshot.ref.getDownloadURL();

      emit(UploadImageSuccess(imageUrl));
      return imageUrl;
    } catch (e) {
      debugPrint('Error uploading image: $e');
      emit(UploadImageError(e.toString()));
      rethrow;
    }
  }

  // ==================== Update Competition ====================

  /// Update competition
  Future<void> updateCompetition(String competitionId, Map<String, dynamic> data) async {
    try {
      emit(UpdateCompetitionLoading());

      await competitionsRepository.updateCompetition(competitionId, data);

      // Refresh current competition if it's the one being updated
      if (currentCompetition?.id == competitionId) {
        await loadCompetitionById(competitionId);
      }

      // Refresh competitions list
      await loadActiveCompetitions();

      emit(UpdateCompetitionSuccess());
    } catch (e) {
      debugPrint('Error updating competition: $e');
      emit(UpdateCompetitionError(e.toString()));
    }
  }

  /// Update competition with new image
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

      // Refresh current competition if it's the one being updated
      if (currentCompetition?.id == competitionId) {
        await loadCompetitionById(competitionId);
      }

      // Refresh competitions list
      await loadActiveCompetitions();

      emit(UpdateCompetitionSuccess());
    } catch (e) {
      debugPrint('Error updating competition with image: $e');
      emit(UpdateCompetitionError(e.toString()));
    }
  }

  /// Toggle competition active status
  Future<void> toggleCompetitionStatus(String competitionId, bool isActive) async {
    try {
      emit(ToggleCompetitionStatusLoading());

      await competitionsRepository.updateCompetitionStatus(competitionId, isActive);

      // Refresh current competition if it's the one being updated
      if (currentCompetition?.id == competitionId) {
        await loadCompetitionById(competitionId);
      }

      // Refresh competitions list
      await loadActiveCompetitions();

      emit(ToggleCompetitionStatusSuccess());
    } catch (e) {
      debugPrint('Error toggling competition status: $e');
      emit(ToggleCompetitionStatusError(e.toString()));
    }
  }

  // ==================== Delete Competition ====================

  /// Delete competition
  Future<void> deleteCompetition(String competitionId) async {
    try {
      emit(DeleteCompetitionLoading());

      // Delete associated image if exists
      final competition = await competitionsRepository.getCompetitionById(competitionId);
      if (competition?.imageUrl != null) {
        await _deleteCompetitionImage(competition!.imageUrl!);
      }

      await competitionsRepository.deleteCompetition(competitionId);

      // Clear current competition if it's the one being deleted
      if (currentCompetition?.id == competitionId) {
        currentCompetition = null;
      }

      // Refresh competitions list
      await loadActiveCompetitions();

      emit(DeleteCompetitionSuccess());
    } catch (e) {
      debugPrint('Error deleting competition: $e');
      emit(DeleteCompetitionError(e.toString()));
    }
  }

  /// Delete competition image from Firebase Storage
  Future<void> _deleteCompetitionImage(String imageUrl) async {
    try {
      final ref = _storage.refFromURL(imageUrl);
      await ref.delete();
    } catch (e) {
      debugPrint('Error deleting competition image: $e');
      // Don't throw - image deletion is not critical
    }
  }

  /// Batch delete competitions
  Future<void> batchDeleteCompetitions(List<String> competitionIds) async {
    try {
      emit(DeleteCompetitionLoading());

      await competitionsRepository.batchDeleteCompetitions(competitionIds);

      // Refresh competitions list
      await loadActiveCompetitions();

      emit(DeleteCompetitionSuccess());
    } catch (e) {
      debugPrint('Error batch deleting competitions: $e');
      emit(DeleteCompetitionError(e.toString()));
    }
  }

  // ==================== Search & Filter ====================

  /// Search competitions by name
  Future<void> searchCompetitions(String query) async {
    try {
      emit(SearchCompetitionsLoading());

      currentSearchQuery = query;

      if (query.isEmpty) {
        filteredCompetitions = activeCompetitions;
      } else {
        filteredCompetitions = await competitionsRepository.searchCompetitionsByName(query);
      }

      emit(SearchCompetitionsSuccess());
    } catch (e) {
      debugPrint('Error searching competitions: $e');
      emit(SearchCompetitionsError(e.toString()));
    }
  }

  /// Clear search/filter
  void clearFilters() {
    currentSearchQuery = null;
    currentAudienceFilter = null;
    filteredCompetitions = null;
    emit(LoadCompetitionsSuccess());
  }

  // ==================== Validation ====================

  /// Check if competition name already exists
  Future<bool> competitionNameExists(String name, {String? excludeId}) async {
    try {
      return await competitionsRepository.competitionNameExists(name, excludeId: excludeId);
    } catch (e) {
      debugPrint('Error checking competition name: $e');
      return false;
    }
  }

  // ==================== Statistics ====================

  /// Get competitions count
  Future<int> getCompetitionsCount() async {
    try {
      return await competitionsRepository.getCompetitionsCount();
    } catch (e) {
      debugPrint('Error getting competitions count: $e');
      return 0;
    }
  }

  /// Get active competitions count
  Future<int> getActiveCompetitionsCount() async {
    try {
      return await competitionsRepository.getActiveCompetitionsCount();
    } catch (e) {
      debugPrint('Error getting active competitions count: $e');
      return 0;
    }
  }

  // ==================== Answer Validation ====================

  /// Validate user answers for a competition
  Future<int?> validateAnswers({
    required String competitionId,
    required Map<String, List<String>> userAnswers,
  }) async {
    try {
      emit(SubmitAnswersLoading());

      final competition = await competitionsRepository.getCompetitionById(competitionId);

      if (competition == null) {
        emit(SubmitAnswersError('Competition not found'));
        return null;
      }

      int totalScore = 0;
      int totalPoints = competition.totalPoints ?? 0;

      // Validate each answer
      for (final question in competition.questions) {
        final questionId = question.id;
        if (questionId == null) continue;

        final selectedAnswers = userAnswers[questionId] ?? [];
        final isCorrect = question.isCorrectAnswer(selectedAnswers);

        if (isCorrect) {
          totalScore += question.points ?? 0;
        }
      }

      emit(SubmitAnswersSuccess(totalScore, totalPoints));
      return totalScore;
    } catch (e) {
      debugPrint('Error validating answers: $e');
      emit(SubmitAnswersError(e.toString()));
      return null;
    }
  }

  /// Get correct answers for a competition (for review)
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

  /// Add question to question bank
  Future<String?> addQuestionToBank(QuestionModel question) async {
    try {
      final questionId = await questionsRepository.addQuestion(question);
      return questionId;
    } catch (e) {
      debugPrint('Error adding question to bank: $e');
      return null;
    }
  }

  /// Get random questions from bank
  Future<List<QuestionModel>> getRandomQuestions(int count) async {
    try {
      return await questionsRepository.getRandomQuestions(count);
    } catch (e) {
      debugPrint('Error getting random questions: $e');
      return [];
    }
  }

  /// Get random questions by type
  Future<List<QuestionModel>> getRandomQuestionsByType(QuestionType type, int count) async {
    try {
      return await questionsRepository.getRandomQuestionsByType(type, count);
    } catch (e) {
      debugPrint('Error getting random questions by type: $e');
      return [];
    }
  }

  // ==================== User Results ====================

  /// Submit competition result and add points to user account
  Future<void> submitCompetitionResult({
    required String userId,
    required String competitionId,
    required int score,
    required int totalQuestions,
    required int correctAnswers,
  }) async {
    try {
      emit(SubmitAnswersLoading());

      // Save the result to the database
      final resultId = await competitionsRepository.saveCompetitionResult(
        userId: userId,
        competitionId: competitionId,
        score: score,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        completedAt: DateTime.now(),
      );

      // Add points to user account if score > 0
      if (score > 0) {
        await _pointsService.addPoints(
          userId,
          score,
          orderId: resultId,
        );
      }

      emit(SubmitAnswersSuccess(score, totalQuestions * 10));
    } catch (e) {
      debugPrint('Error submitting competition result: $e');
      emit(SubmitAnswersError(e.toString()));
      rethrow;
    }
  }

  // ==================== Utility Methods ====================

  /// Get user's result for a specific competition
  Future<Map<String, dynamic>?> getUserCompetitionResult(String userId, String competitionId) async {
    try {
      return await competitionsRepository.getUserCompetitionResult(userId, competitionId);
    } catch (e) {
      debugPrint('Error getting user competition result: $e');
      return null;
    }
  }

  /// Check if user has completed a competition
  Future<bool> hasUserCompletedCompetition(String userId, String competitionId) async {
    try {
      return await competitionsRepository.hasUserCompletedCompetition(userId, competitionId);
    } catch (e) {
      debugPrint('Error checking competition completion: $e');
      return false;
    }
  }

  /// Refresh all data
  Future<void> refreshAll() async {
    await loadActiveCompetitions();
  }

  /// Clear cached data
  void clearCache() {
    allCompetitions = null;
    activeCompetitions = null;
    filteredCompetitions = null;
    currentCompetition = null;
    currentSearchQuery = null;
    currentAudienceFilter = null;
    currentPage = 0;
    hasMoreData = true;
  }

  /// Get display list (filtered or active)
  List<CompetitionModel>? get displayList {
    if (filteredCompetitions != null) {
      return filteredCompetitions;
    }
    return activeCompetitions ?? allCompetitions;
  }
}

