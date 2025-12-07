import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/competitions/competition_model.dart';

/// Repository for managing questions and answers with Firestore integration.
/// This repository handles individual questions that can be used across multiple competitions.
class QuestionsRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath;

  QuestionsRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'questions',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  CollectionReference get _questionsCollection =>
      _firestore.collection(_collectionPath);

  // ==================== STREAM METHODS ====================

  /// Stream all questions in real-time
  Stream<List<QuestionModel>> watchAllQuestions() {
    return _questionsCollection
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  /// Stream questions by type
  Stream<List<QuestionModel>> watchQuestionsByType(QuestionType type) {
    return _questionsCollection
        .where('type', isEqualTo: type.name)
        .orderBy('orderIndex')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => QuestionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
  }

  /// Stream a single question
  Stream<QuestionModel?> watchQuestion(String questionId) {
    return _questionsCollection.doc(questionId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return QuestionModel.fromJson(
        {...doc.data() as Map<String, dynamic>, 'id': doc.id},
      );
    });
  }

  /// Stream questions by points range
  Stream<List<QuestionModel>> watchQuestionsByPointsRange({
    int? minPoints,
    int? maxPoints,
  }) {
    Query query = _questionsCollection;

    if (minPoints != null) {
      query = query.where('points', isGreaterThanOrEqualTo: minPoints);
    }
    if (maxPoints != null) {
      query = query.where('points', isLessThanOrEqualTo: maxPoints);
    }

    return query.orderBy('points').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => QuestionModel.fromJson(
              {...doc.data() as Map<String, dynamic>, 'id': doc.id},
            ))
        .toList());
  }

  // ==================== FUTURE METHODS ====================

  /// Get all questions
  Future<List<QuestionModel>> getAllQuestions() async {
    try {
      final snapshot = await _questionsCollection.orderBy('orderIndex').get();

      return snapshot.docs
          .map((doc) => QuestionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching questions: $e');
    }
  }

  /// Get a single question by ID
  Future<QuestionModel?> getQuestionById(String questionId) async {
    try {
      final doc = await _questionsCollection.doc(questionId).get();

      if (!doc.exists) return null;

      return QuestionModel.fromJson(
        {...doc.data() as Map<String, dynamic>, 'id': doc.id},
      );
    } catch (e) {
      throw Exception('Error fetching question: $e');
    }
  }

  /// Get questions by type
  Future<List<QuestionModel>> getQuestionsByType(QuestionType type) async {
    try {
      final snapshot = await _questionsCollection
          .where('type', isEqualTo: type.name)
          .orderBy('orderIndex')
          .get();

      return snapshot.docs
          .map((doc) => QuestionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error fetching questions by type: $e');
    }
  }

  /// Get questions by IDs
  Future<List<QuestionModel>> getQuestionsByIds(List<String> questionIds) async {
    try {
      if (questionIds.isEmpty) return [];

      // Firestore 'in' query supports max 10 items, so batch if needed
      final List<QuestionModel> allQuestions = [];

      for (int i = 0; i < questionIds.length; i += 10) {
        final batch = questionIds.skip(i).take(10).toList();
        final snapshot = await _questionsCollection
            .where(FieldPath.documentId, whereIn: batch)
            .get();

        allQuestions.addAll(snapshot.docs
            .map((doc) => QuestionModel.fromJson(
                  {...doc.data() as Map<String, dynamic>, 'id': doc.id},
                ))
            .toList());
      }

      return allQuestions;
    } catch (e) {
      throw Exception('Error fetching questions by IDs: $e');
    }
  }

  // ==================== CREATE/UPDATE/DELETE METHODS ====================

  /// Add a new question
  Future<String> addQuestion(QuestionModel question) async {
    try {
      final docRef = await _questionsCollection.add(question.toJson());
      return docRef.id;
    } catch (e) {
      throw Exception('Error adding question: $e');
    }
  }

  /// Add question with custom ID
  Future<void> setQuestion(String id, QuestionModel question) async {
    try {
      await _questionsCollection.doc(id).set(question.toJson());
    } catch (e) {
      throw Exception('Error setting question: $e');
    }
  }

  /// Add multiple questions at once
  Future<List<String>> addQuestions(List<QuestionModel> questions) async {
    try {
      final List<String> questionIds = [];

      for (final question in questions) {
        final docRef = await _questionsCollection.add(question.toJson());
        questionIds.add(docRef.id);
      }

      return questionIds;
    } catch (e) {
      throw Exception('Error adding questions: $e');
    }
  }

  /// Update an existing question
  Future<void> updateQuestion(String questionId, Map<String, dynamic> data) async {
    try {
      await _questionsCollection.doc(questionId).update(data);
    } catch (e) {
      throw Exception('Error updating question: $e');
    }
  }

  /// Update question text
  Future<void> updateQuestionText(String questionId, String questionText) async {
    try {
      await _questionsCollection.doc(questionId).update({
        'questionText': questionText,
      });
    } catch (e) {
      throw Exception('Error updating question text: $e');
    }
  }

  /// Update question points
  Future<void> updateQuestionPoints(String questionId, int points) async {
    try {
      await _questionsCollection.doc(questionId).update({
        'points': points,
      });
    } catch (e) {
      throw Exception('Error updating question points: $e');
    }
  }

  /// Delete a question
  Future<void> deleteQuestion(String questionId) async {
    try {
      await _questionsCollection.doc(questionId).delete();
    } catch (e) {
      throw Exception('Error deleting question: $e');
    }
  }

  /// Delete multiple questions
  Future<void> deleteQuestions(List<String> questionIds) async {
    try {
      final batch = _firestore.batch();

      for (final id in questionIds) {
        final docRef = _questionsCollection.doc(id);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error deleting questions: $e');
    }
  }

  // ==================== ANSWER MANAGEMENT ====================

  /// Add an answer option to a question
  Future<void> addAnswerOption(String questionId, AnswerOptionModel answer) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      final updatedAnswers = [...question.answerOptions, answer];

      await _questionsCollection.doc(questionId).update({
        'answerOptions': updatedAnswers.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Error adding answer option: $e');
    }
  }

  /// Update an answer option
  Future<void> updateAnswerOption(
    String questionId,
    String answerId,
    AnswerOptionModel updatedAnswer,
  ) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      final updatedAnswers = question.answerOptions.map((answer) {
        return answer.id == answerId ? updatedAnswer : answer;
      }).toList();

      await _questionsCollection.doc(questionId).update({
        'answerOptions': updatedAnswers.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Error updating answer option: $e');
    }
  }

  /// Remove an answer option from a question
  Future<void> removeAnswerOption(String questionId, String answerId) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      final updatedAnswers =
          question.answerOptions.where((answer) => answer.id != answerId).toList();

      await _questionsCollection.doc(questionId).update({
        'answerOptions': updatedAnswers.map((a) => a.toJson()).toList(),
      });
    } catch (e) {
      throw Exception('Error removing answer option: $e');
    }
  }

  /// Update correct answer for single choice/true-false questions
  Future<void> updateCorrectAnswer(String questionId, String correctAnswerId) async {
    try {
      await _questionsCollection.doc(questionId).update({
        'correctAnswerId': correctAnswerId,
      });
    } catch (e) {
      throw Exception('Error updating correct answer: $e');
    }
  }

  /// Update correct answers for multiple choice questions
  Future<void> updateCorrectAnswers(String questionId, List<String> correctAnswerIds) async {
    try {
      await _questionsCollection.doc(questionId).update({
        'correctAnswerIds': correctAnswerIds,
      });
    } catch (e) {
      throw Exception('Error updating correct answers: $e');
    }
  }

  /// Get all answers for a question
  Future<List<AnswerOptionModel>> getAnswersForQuestion(String questionId) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      return question.answerOptions;
    } catch (e) {
      throw Exception('Error fetching answers: $e');
    }
  }

  /// Get correct answer(s) for a question
  Future<dynamic> getCorrectAnswer(String questionId) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      if (question.type == QuestionType.multipleChoice) {
        return question.correctAnswerIds;
      } else {
        return question.correctAnswerId;
      }
    } catch (e) {
      throw Exception('Error fetching correct answer: $e');
    }
  }

  // ==================== VALIDATION METHODS ====================

  /// Validate if an answer is correct
  Future<bool> validateAnswer(String questionId, List<String> selectedAnswerIds) async {
    try {
      final question = await getQuestionById(questionId);
      if (question == null) {
        throw Exception('Question not found');
      }

      return question.isCorrectAnswer(selectedAnswerIds);
    } catch (e) {
      throw Exception('Error validating answer: $e');
    }
  }

  /// Validate multiple answers
  Future<Map<String, bool>> validateAnswers(
    Map<String, List<String>> questionAnswers,
  ) async {
    try {
      final Map<String, bool> results = {};

      for (final entry in questionAnswers.entries) {
        final questionId = entry.key;
        final selectedAnswers = entry.value;

        final isCorrect = await validateAnswer(questionId, selectedAnswers);
        results[questionId] = isCorrect;
      }

      return results;
    } catch (e) {
      throw Exception('Error validating answers: $e');
    }
  }

  // ==================== QUERY METHODS ====================

  /// Get questions count
  Future<int> getQuestionsCount() async {
    try {
      final snapshot = await _questionsCollection.get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting questions count: $e');
    }
  }

  /// Get questions count by type
  Future<int> getQuestionsCountByType(QuestionType type) async {
    try {
      final snapshot = await _questionsCollection
          .where('type', isEqualTo: type.name)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      throw Exception('Error getting questions count by type: $e');
    }
  }

  /// Search questions by text
  Future<List<QuestionModel>> searchQuestions(String searchQuery) async {
    try {
      final snapshot = await _questionsCollection
          .orderBy('questionText')
          .startAt([searchQuery])
          .endAt([searchQuery + '\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => QuestionModel.fromJson(
                {...doc.data() as Map<String, dynamic>, 'id': doc.id},
              ))
          .toList();
    } catch (e) {
      throw Exception('Error searching questions: $e');
    }
  }

  /// Get random questions
  Future<List<QuestionModel>> getRandomQuestions(int count) async {
    try {
      final allQuestions = await getAllQuestions();

      if (allQuestions.length <= count) {
        return allQuestions;
      }

      allQuestions.shuffle();
      return allQuestions.take(count).toList();
    } catch (e) {
      throw Exception('Error getting random questions: $e');
    }
  }

  /// Get random questions by type
  Future<List<QuestionModel>> getRandomQuestionsByType(
    QuestionType type,
    int count,
  ) async {
    try {
      final questions = await getQuestionsByType(type);

      if (questions.length <= count) {
        return questions;
      }

      questions.shuffle();
      return questions.take(count).toList();
    } catch (e) {
      throw Exception('Error getting random questions by type: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Batch update multiple questions
  Future<void> batchUpdateQuestions(Map<String, Map<String, dynamic>> updates) async {
    try {
      final batch = _firestore.batch();

      updates.forEach((questionId, data) {
        final docRef = _questionsCollection.doc(questionId);
        batch.update(docRef, data);
      });

      await batch.commit();
    } catch (e) {
      throw Exception('Error batch updating questions: $e');
    }
  }

  /// Reorder questions
  Future<void> reorderQuestions(List<String> questionIds) async {
    try {
      final batch = _firestore.batch();

      for (int i = 0; i < questionIds.length; i++) {
        final docRef = _questionsCollection.doc(questionIds[i]);
        batch.update(docRef, {'orderIndex': i});
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Error reordering questions: $e');
    }
  }

  /// Initialize the questions collection
  Future<void> initializeCollection() async {
    try {
      final snapshot = await _questionsCollection.limit(1).get();

      if (snapshot.docs.isEmpty) {
        // Create a dummy document to initialize the collection
        await _questionsCollection.doc('_init').set({
          'initialized': true,
          'createdAt': FieldValue.serverTimestamp(),
        });

        // Delete the dummy document
        await _questionsCollection.doc('_init').delete();
      }
    } catch (e) {
      throw Exception('Error initializing questions collection: $e');
    }
  }
}

