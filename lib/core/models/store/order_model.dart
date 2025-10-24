import 'package:cloud_firestore/cloud_firestore.dart';

/// Order status enum
enum OrderStatus {
  pending,
  processing,
  completed,
  cancelled,
  refunded,
}

extension OrderStatusX on OrderStatus {
  String get code => switch (this) {
    OrderStatus.pending => 'PENDING',
    OrderStatus.processing => 'PROCESSING',
    OrderStatus.completed => 'COMPLETED',
    OrderStatus.cancelled => 'CANCELLED',
    OrderStatus.refunded => 'REFUNDED',
  };

  String get label => switch (this) {
    OrderStatus.pending => 'قيد الانتظار',
    OrderStatus.processing => 'قيد المعالجة',
    OrderStatus.completed => 'مكتمل',
    OrderStatus.cancelled => 'ملغي',
    OrderStatus.refunded => 'مسترد',
  };

  static OrderStatus fromCode(String code) {
    return OrderStatus.values.firstWhere(
      (status) => status.code == code,
      orElse: () => OrderStatus.pending,
    );
  }
}

/// Order item representing a product in an order
class OrderItem {
  final String productId;
  final String productTitle;
  final String? productImageUrl;
  final double price;
  final double discountedPrice;
  final int quantity;
  final int? discount;

  const OrderItem({
    required this.productId,
    required this.productTitle,
    this.productImageUrl,
    required this.price,
    required this.discountedPrice,
    required this.quantity,
    this.discount,
  });

  double get totalPrice => discountedPrice * quantity;

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productTitle': productTitle,
      'productImageUrl': productImageUrl,
      'price': price,
      'discountedPrice': discountedPrice,
      'quantity': quantity,
      'discount': discount,
    };
  }

  factory OrderItem.fromMap(Map<String, dynamic> map) {
    return OrderItem(
      productId: map['productId'] as String,
      productTitle: map['productTitle'] as String,
      productImageUrl: map['productImageUrl'] as String?,
      price: (map['price'] as num).toDouble(),
      discountedPrice: (map['discountedPrice'] as num).toDouble(),
      quantity: map['quantity'] as int,
      discount: map['discount'] as int?,
    );
  }

  OrderItem copyWith({
    String? productId,
    String? productTitle,
    String? productImageUrl,
    double? price,
    double? discountedPrice,
    int? quantity,
    int? discount,
  }) {
    return OrderItem(
      productId: productId ?? this.productId,
      productTitle: productTitle ?? this.productTitle,
      productImageUrl: productImageUrl ?? this.productImageUrl,
      price: price ?? this.price,
      discountedPrice: discountedPrice ?? this.discountedPrice,
      quantity: quantity ?? this.quantity,
      discount: discount ?? this.discount,
    );
  }
}

/// Order model representing a customer order
class OrderModel {
  final String id;
  final String userId;
  final String userName;
  final String? userEmail;
  final String? userPhone;
  final String? deliveryAddress;
  final List<OrderItem> items;
  final double subtotal;
  final double discount;
  final double total;
  final OrderStatus status;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;
  final DateTime? completedAt;
  final Map<String, dynamic>? metadata;

  const OrderModel({
    required this.id,
    required this.userId,
    required this.userName,
    this.userEmail,
    this.userPhone,
    this.deliveryAddress,
    required this.items,
    required this.subtotal,
    this.discount = 0.0,
    required this.total,
    this.status = OrderStatus.pending,
    this.notes,
    this.createdAt,
    this.updatedAt,
    this.completedAt,
    this.metadata,
  });
  OrderModel copyWith({
    String? id,
    String? userId,
    String? userName,
    String? userEmail,
    String? userPhone,
    String? deliveryAddress,
    List<OrderItem>? items,
    double? subtotal,
    double? discount,
    double? total,
    OrderStatus? status,
    String? notes,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? completedAt,
    Map<String, dynamic>? metadata,
  }) {
    return OrderModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      userEmail: userEmail ?? this.userEmail,
      userPhone: userPhone ?? this.userPhone,
      deliveryAddress: deliveryAddress ?? this.deliveryAddress,
      items: items ?? this.items,
      subtotal: subtotal ?? this.subtotal,
      discount: discount ?? this.discount,
      total: total ?? this.total,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      completedAt: completedAt ?? this.completedAt,
      metadata: metadata ?? this.metadata,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status.code,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
      'metadata': metadata,
    };
  }

  factory OrderModel.fromMap(Map<String, dynamic> map, String id) {
    DateTime? parseDate(dynamic value) {
      if (value == null) return null;
      if (value is DateTime) return value;
      if (value is Timestamp) return value.toDate();
      if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (_) {
          return null;
        }
      }
      return null;
    }

    return OrderModel(
      id: id,
      userId: map['userId'] as String,
      userName: map['userName'] as String,
      userEmail: map['userEmail'] as String?,
      userPhone: map['userPhone'] as String?,
      deliveryAddress: map['deliveryAddress'] as String?,
      items: (map['items'] as List<dynamic>)
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      subtotal: (map['subtotal'] as num).toDouble(),
      discount: (map['discount'] as num?)?.toDouble() ?? 0.0,
      total: (map['total'] as num).toDouble(),
      status: OrderStatusX.fromCode(map['status'] as String),
      notes: map['notes'] as String?,
      createdAt: parseDate(map['createdAt']),
      updatedAt: parseDate(map['updatedAt']),
      completedAt: parseDate(map['completedAt']),
      metadata: map['metadata'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toFirestore({bool includeId = true}) {
    final data = {
      'userId': userId,
      'userName': userName,
      'userEmail': userEmail,
      'userPhone': userPhone,
      'deliveryAddress': deliveryAddress,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discount': discount,
      'total': total,
      'status': status.code,
      'notes': notes,
      'createdAt': createdAt != null ? Timestamp.fromDate(createdAt!) : null,
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
      'metadata': metadata,
    };
    if (includeId) {
      data['id'] = id;
    }

    return data;
  }

  factory OrderModel.fromFirestore(Map<String, dynamic> data, String id) {
    return OrderModel.fromMap(data, id);
  }
}

