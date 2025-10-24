import 'dart:convert';

/// ProductModel represents a product/item in the app store module.
///
/// Fields are kept generic and Firestore-friendly. Use `fromMap` when
/// reading from Firestore or other Map<String, dynamic> sources.
class ProductModel {
  final String id;
  final String title;
  final String? description;
  final double price;
  final List<String> imageUrls;
  final String? category;
  final int stock;
  final bool isActive;
  final int? discount;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? metadata;

  const ProductModel({
    required this.id,
    required this.title,
    this.description,
    required this.price,
    this.imageUrls = const [],
    this.category,
    this.stock = 0,
    this.isActive = true,
    this.discount,
    this.createdAt,
    this.updatedAt,
    this.metadata,
  });

  /// Create a copy of this ProductModel with optional changes.
  ProductModel copyWith({
    String? id,
    String? title,
    String? description,
    double? price,
    List<String>? imageUrls,
    String? category,
    int? stock,
    bool? isActive,
    int? discount,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? metadata,
  }) {
    return ProductModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrls: imageUrls ?? this.imageUrls,
      category: category ?? this.category,
      stock: stock ?? this.stock,
      isActive: isActive ?? this.isActive,
      discount: discount ?? this.discount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  /// Convert ProductModel to a Map suitable for JSON or Firestore.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'imageUrls': imageUrls,
      'category': category,
      'stock': stock,
      'isActive': isActive,
      'discount': discount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  /// Create a ProductModel from a Map. Accepts both ISO date strings and
  /// integer milliseconds since epoch for `createdAt`/`updatedAt`.
  factory ProductModel.fromMap(Map<String, dynamic> map) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return ProductModel(
      id: map['id']?.toString() ?? '',
      title: map['title']?.toString() ?? '',
      description: map['description']?.toString(),
      price: (map['price'] is num) ? (map['price'] as num).toDouble() : double.tryParse(map['price']?.toString() ?? '0') ?? 0.0,
      imageUrls: (map['imageUrls'] is Iterable) ? List<String>.from(map['imageUrls'].whereType<String>()) : <String>[],
      category: map['category']?.toString(),
      stock: (map['stock'] is int) ? map['stock'] as int : int.tryParse(map['stock']?.toString() ?? '0') ?? 0,
      isActive: map['isActive'] is bool ? map['isActive'] as bool : (map['isActive'] == null ? true : (map['isActive'].toString().toLowerCase() == 'true')),
      discount: (map['discount'] is int) ? map['discount'] as int : int.tryParse(map['discount']?.toString() ?? ''),
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      metadata: (map['metadata'] is Map) ? Map<String, dynamic>.from(map['metadata']) : null,
    );
  }

  String toJson() => json.encode(toMap());

  factory ProductModel.fromJson(String source) => ProductModel.fromMap(json.decode(source) as Map<String, dynamic>);

  /// Helpers for Firestore interop where timestamps are sometimes stored as
  /// Timestamp or DateTime. By default `toFirestore()` will omit the `id`
  /// field so the document ID can be used as the product ID in Firestore.
  /// Pass `includeId: true` to keep the `id` field in the returned map.
  Map<String, dynamic> toFirestore({bool includeId = false}) {
    final map = toMap();
    if (!includeId) {
      map.remove('id');
    }
    return map;
  }

  factory ProductModel.fromFirestore(Map<String, dynamic> map, String documentId) {
    final merged = Map<String, dynamic>.from(map);
    merged['id'] = documentId;
    return ProductModel.fromMap(merged);
  }

  @override
  String toString() {
    return 'ProductModel(id: $id, title: $title, price: $price, images: ${imageUrls.length}, category: $category, stock: $stock, isActive: $isActive, discount: $discount, createdAt: $createdAt, updatedAt: $updatedAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProductModel &&
        other.id == id &&
        other.title == title &&
        other.description == description &&
        other.price == price &&
        _listEquals(other.imageUrls, imageUrls) &&
        other.category == category &&
        other.stock == stock &&
        other.isActive == isActive &&
        other.discount == discount &&
        other.createdAt == createdAt &&
        other.updatedAt == updatedAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        title.hashCode ^
        (description?.hashCode ?? 0) ^
        price.hashCode ^
        imageUrls.fold(0, (p, e) => p ^ e.hashCode) ^
        (category?.hashCode ?? 0) ^
        stock.hashCode ^
        isActive.hashCode ^
        (discount?.hashCode ?? 0) ^
        (createdAt?.hashCode ?? 0) ^
        (updatedAt?.hashCode ?? 0);
  }

  static bool _listEquals(List? a, List? b) {
    if (identical(a, b)) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
