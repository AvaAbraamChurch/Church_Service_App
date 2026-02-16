import 'package:cloud_firestore/cloud_firestore.dart';

/// Model representing a hymn with its details
class HymnModel {
  final String id;
  final String title;
  final String arabicTitle;
  final String copticTitle;
  final String? copticArlyrics;
  final String? arabicLyrics;
  final String? copticLyrics;
  final String? audioUrl;
  final String? videoUrl;
  final String? occasion; // e.g., 'Sunday', 'Feast', 'Lent', etc.
  final List<String> userClasses; // User classes that can access this hymn
  final int order; // for ordering hymns
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const HymnModel({
    required this.id,
    required this.title,
    required this.arabicTitle,
    required this.copticTitle,
    this.copticArlyrics,
    this.arabicLyrics,
    this.copticLyrics,
    this.audioUrl,
    this.videoUrl,
    this.occasion,
    this.userClasses = const [],
    this.order = 0,
    this.createdAt,
    this.updatedAt,
  });

  /// Create HymnModel from Firestore document
  factory HymnModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return HymnModel(
      id: doc.id,
      title: data['title'] ?? '',
      arabicTitle: data['arabicTitle'] ?? '',
      copticTitle: data['copticTitle'] ?? '',
      copticArlyrics: data['copticArlyrics'],
      arabicLyrics: data['arabicLyrics'],
      copticLyrics: data['copticLyrics'],
      audioUrl: data['audioUrl'],
      videoUrl: data['videoUrl'],
      occasion: data['occasion'],
      userClasses: data['userClasses'] != null
          ? List<String>.from(data['userClasses'] as List)
          : [],
      order: data['order'] ?? 0,
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      updatedAt: data['updatedAt'] != null
          ? (data['updatedAt'] as Timestamp).toDate()
          : null,
    );
  }

  /// Convert HymnModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'arabicTitle': arabicTitle,
      'copticTitle': copticTitle,
      'copticArlyrics': copticArlyrics,
      'arabicLyrics': arabicLyrics,
      'copticLyrics': copticLyrics,
      'audioUrl': audioUrl,
      'videoUrl': videoUrl,
      'occasion': occasion,
      'userClasses': userClasses,
      'order': order,
      'createdAt': createdAt != null
          ? Timestamp.fromDate(createdAt!)
          : FieldValue.serverTimestamp(),
      'updatedAt': updatedAt != null
          ? Timestamp.fromDate(updatedAt!)
          : FieldValue.serverTimestamp(),
    };
  }

  /// Create a copy with updated fields
  HymnModel copyWith({
    String? id,
    String? title,
    String? arabicTitle,
    String? copticTitle,
    String? copticArlyrics,
    String? arabicLyrics,
    String? copticLyrics,
    String? audioUrl,
    String? videoUrl,
    String? occasion,
    List<String>? userClasses,
    int? order,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HymnModel(
      id: id ?? this.id,
      title: title ?? this.title,
      arabicTitle: arabicTitle ?? this.arabicTitle,
      copticTitle: copticTitle ?? this.copticTitle,
      copticArlyrics: copticArlyrics ?? this.copticArlyrics,
      arabicLyrics: arabicLyrics ?? this.arabicLyrics,
      copticLyrics: copticLyrics ?? this.copticLyrics,
      audioUrl: audioUrl ?? this.audioUrl,
      videoUrl: videoUrl ?? this.videoUrl,
      occasion: occasion ?? this.occasion,
      userClasses: userClasses ?? this.userClasses,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
