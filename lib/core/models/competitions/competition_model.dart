import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a competition/quiz with questions and answers
class CompetitionModel {
  final String? id;
  final String competitionName;
  final String? description;
  final DateTime createdAt;
  final DateTime? startDate;
  final DateTime? endDate;
  final int numberOfQuestions;
  final List<QuestionModel> questions;
  final bool isActive;
  final String? createdBy; // User ID of creator
  final String? targetAudience; // 'all', 'children', 'servants', etc.
  final String? targetGender; // 'all', 'M', 'F' - Filter by gender
  final int? pointsPerQuestion;
  final int? totalPoints;
  final String? imageUrl;

  CompetitionModel({
    this.id,
    required this.competitionName,
    this.description,
    required this.createdAt,
    this.startDate,
    this.endDate,
    required this.numberOfQuestions,
    required this.questions,
    this.isActive = true,
    this.createdBy,
    this.targetAudience,
    this.targetGender,
    this.pointsPerQuestion,
    this.totalPoints,
    this.imageUrl,
  });

  /// Create CompetitionModel from Firestore document
  factory CompetitionModel.fromJson(Map<String, dynamic> json) {
    return CompetitionModel(
      id: json['id'] as String?,
      competitionName: json['competitionName'] as String? ?? '',
      description: json['description'] as String?,
      createdAt: json['createdAt'] is Timestamp
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.parse(json['createdAt'] as String),
      startDate: json['startDate'] != null
          ? (json['startDate'] is Timestamp
              ? (json['startDate'] as Timestamp).toDate()
              : DateTime.parse(json['startDate'] as String))
          : null,
      endDate: json['endDate'] != null
          ? (json['endDate'] is Timestamp
              ? (json['endDate'] as Timestamp).toDate()
              : DateTime.parse(json['endDate'] as String))
          : null,
      numberOfQuestions: json['numberOfQuestions'] as int? ?? 0,
      questions: (json['questions'] as List<dynamic>?)
              ?.map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
              .toList() ??
          [],
      isActive: json['isActive'] as bool? ?? true,
      createdBy: json['createdBy'] as String?,
      targetAudience: json['targetAudience'] as String?,
      targetGender: json['targetGender'] as String?,
      pointsPerQuestion: json['pointsPerQuestion'] as int?,
      totalPoints: json['totalPoints'] as int?,
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Convert CompetitionModel to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'competitionName': competitionName,
      if (description != null) 'description': description,
      'createdAt': Timestamp.fromDate(createdAt),
      if (startDate != null) 'startDate': Timestamp.fromDate(startDate!),
      if (endDate != null) 'endDate': Timestamp.fromDate(endDate!),
      'numberOfQuestions': numberOfQuestions,
      'questions': questions.map((q) => q.toJson()).toList(),
      'isActive': isActive,
      if (createdBy != null) 'createdBy': createdBy,
      if (targetAudience != null) 'targetAudience': targetAudience,
      if (targetGender != null) 'targetGender': targetGender,
      if (pointsPerQuestion != null) 'pointsPerQuestion': pointsPerQuestion,
      if (totalPoints != null) 'totalPoints': totalPoints,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Create a copy with modified fields
  CompetitionModel copyWith({
    String? id,
    String? competitionName,
    String? description,
    DateTime? createdAt,
    DateTime? startDate,
    DateTime? endDate,
    int? numberOfQuestions,
    List<QuestionModel>? questions,
    bool? isActive,
    String? createdBy,
    String? targetAudience,
    String? targetGender,
    int? pointsPerQuestion,
    int? totalPoints,
    String? imageUrl,
  }) {
    return CompetitionModel(
      id: id ?? this.id,
      competitionName: competitionName ?? this.competitionName,
      description: description ?? this.description,
      createdAt: createdAt ?? this.createdAt,
      startDate: startDate ?? this.startDate,
      endDate: endDate ?? this.endDate,
      numberOfQuestions: numberOfQuestions ?? this.numberOfQuestions,
      questions: questions ?? this.questions,
      isActive: isActive ?? this.isActive,
      createdBy: createdBy ?? this.createdBy,
      targetAudience: targetAudience ?? this.targetAudience,
      targetGender: targetGender ?? this.targetGender,
      pointsPerQuestion: pointsPerQuestion ?? this.pointsPerQuestion,
      totalPoints: totalPoints ?? this.totalPoints,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'CompetitionModel(id: $id, competitionName: $competitionName, numberOfQuestions: $numberOfQuestions, isActive: $isActive)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CompetitionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Model representing a single question in a competition
class QuestionModel {
  final String? id;
  final String questionText;
  final QuestionType type;
  final List<AnswerOptionModel> answerOptions;
  final String? correctAnswerId; // For single choice questions
  final List<String>? correctAnswerIds; // For multiple choice questions
  final String? imageUrl;
  final int? points;
  final int orderIndex;

  QuestionModel({
    this.id,
    required this.questionText,
    required this.type,
    required this.answerOptions,
    this.correctAnswerId,
    this.correctAnswerIds,
    this.imageUrl,
    this.points,
    required this.orderIndex,
  });

  /// Create QuestionModel from JSON
  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String?,
      questionText: json['questionText'] as String? ?? '',
      type: QuestionType.values.firstWhere(
        (e) => e.name == json['type'],
        orElse: () => QuestionType.singleChoice,
      ),
      answerOptions: (json['answerOptions'] as List<dynamic>?)
              ?.map((a) => AnswerOptionModel.fromJson(a as Map<String, dynamic>))
              .toList() ??
          [],
      correctAnswerId: json['correctAnswerId'] as String?,
      correctAnswerIds: (json['correctAnswerIds'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList(),
      imageUrl: json['imageUrl'] as String?,
      points: json['points'] as int?,
      orderIndex: json['orderIndex'] as int? ?? 0,
    );
  }

  /// Convert QuestionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      if (id != null) 'id': id,
      'questionText': questionText,
      'type': type.name,
      'answerOptions': answerOptions.map((a) => a.toJson()).toList(),
      if (correctAnswerId != null) 'correctAnswerId': correctAnswerId,
      if (correctAnswerIds != null) 'correctAnswerIds': correctAnswerIds,
      if (imageUrl != null) 'imageUrl': imageUrl,
      if (points != null) 'points': points,
      'orderIndex': orderIndex,
    };
  }

  /// Check if the provided answer is correct
  bool isCorrectAnswer(List<String> selectedAnswerIds) {
    if (type == QuestionType.singleChoice) {
      return selectedAnswerIds.length == 1 &&
          selectedAnswerIds.first == correctAnswerId;
    } else if (type == QuestionType.multipleChoice) {
      if (correctAnswerIds == null || selectedAnswerIds.isEmpty) return false;
      final selectedSet = selectedAnswerIds.toSet();
      final correctSet = correctAnswerIds!.toSet();
      return selectedSet.length == correctSet.length &&
          selectedSet.containsAll(correctSet);
    } else if (type == QuestionType.trueFalse) {
      return selectedAnswerIds.length == 1 &&
          selectedAnswerIds.first == correctAnswerId;
    } else if (type == QuestionType.images) {
      // Images type can be single or multiple choice
      if (correctAnswerIds != null && correctAnswerIds!.isNotEmpty) {
        // Multiple choice for images
        final selectedSet = selectedAnswerIds.toSet();
        final correctSet = correctAnswerIds!.toSet();
        return selectedSet.length == correctSet.length &&
            selectedSet.containsAll(correctSet);
      } else if (correctAnswerId != null) {
        // Single choice for images
        return selectedAnswerIds.length == 1 &&
            selectedAnswerIds.first == correctAnswerId;
      }
    }
    return false;
  }

  /// Create a copy with modified fields
  QuestionModel copyWith({
    String? id,
    String? questionText,
    QuestionType? type,
    List<AnswerOptionModel>? answerOptions,
    String? correctAnswerId,
    List<String>? correctAnswerIds,
    String? imageUrl,
    int? points,
    int? orderIndex,
  }) {
    return QuestionModel(
      id: id ?? this.id,
      questionText: questionText ?? this.questionText,
      type: type ?? this.type,
      answerOptions: answerOptions ?? this.answerOptions,
      correctAnswerId: correctAnswerId ?? this.correctAnswerId,
      correctAnswerIds: correctAnswerIds ?? this.correctAnswerIds,
      imageUrl: imageUrl ?? this.imageUrl,
      points: points ?? this.points,
      orderIndex: orderIndex ?? this.orderIndex,
    );
  }

  @override
  String toString() {
    return 'QuestionModel(id: $id, questionText: $questionText, type: $type, orderIndex: $orderIndex)';
  }
}

/// Model representing an answer option for a question
class AnswerOptionModel {
  final String id;
  final String answerText;
  final String? imageUrl;

  AnswerOptionModel({
    required this.id,
    required this.answerText,
    this.imageUrl,
  });

  /// Create AnswerOptionModel from JSON
  factory AnswerOptionModel.fromJson(Map<String, dynamic> json) {
    return AnswerOptionModel(
      id: json['id'] as String? ?? '',
      answerText: json['answerText'] as String? ?? '',
      imageUrl: json['imageUrl'] as String?,
    );
  }

  /// Convert AnswerOptionModel to JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'answerText': answerText,
      if (imageUrl != null) 'imageUrl': imageUrl,
    };
  }

  /// Create a copy with modified fields
  AnswerOptionModel copyWith({
    String? id,
    String? answerText,
    String? imageUrl,
  }) {
    return AnswerOptionModel(
      id: id ?? this.id,
      answerText: answerText ?? this.answerText,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }

  @override
  String toString() {
    return 'AnswerOptionModel(id: $id, answerText: $answerText)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AnswerOptionModel && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;
}

/// Enum for different question types
enum QuestionType {
  singleChoice,
  multipleChoice,
  trueFalse,
  images,
}

extension QuestionTypeExtension on QuestionType {
  String get label {
    switch (this) {
      case QuestionType.singleChoice:
        return 'اختيار واحد';
      case QuestionType.multipleChoice:
        return 'اختيار متعدد';
      case QuestionType.trueFalse:
        return 'صح أو خطأ';
      case QuestionType.images:
        return 'سؤال بالصور';
    }
  }

  String get description {
    switch (this) {
      case QuestionType.singleChoice:
        return 'اختر إجابة واحدة صحيحة';
      case QuestionType.multipleChoice:
        return 'اختر جميع الإجابات الصحيحة';
      case QuestionType.trueFalse:
        return 'اختر صح أو خطأ';
      case QuestionType.images:
        return 'سؤال بالصورة مع إجابات نصية أو مصورة';
    }
  }
}

