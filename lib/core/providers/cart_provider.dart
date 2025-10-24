import 'package:flutter/material.dart';
import '../models/store/product_model.dart';

/// Cart Provider for managing cart state
class CartProvider extends ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  int get totalQuantity => _items.values.fold(0, (sum, item) => sum + item.quantity);

  double get subtotal {
    return _items.values.fold(0.0, (sum, item) {
      final price = item.discount != null && item.discount! > 0
          ? item.product.price * (1 - item.discount! / 100)
          : item.product.price;
      return sum + (price * item.quantity);
    });
  }

  double get discount {
    double totalDiscount = 0.0;
    for (var item in _items.values) {
      if (item.discount != null && item.discount! > 0) {
        final discountAmount = item.product.price * (item.discount! / 100);
        totalDiscount += discountAmount * item.quantity;
      }
    }
    return totalDiscount;
  }

  double get total => subtotal;

  bool get isEmpty => _items.isEmpty;

  bool get isNotEmpty => _items.isNotEmpty;

  /// Add product to cart
  void addItem(ProductModel product) {
    if (_items.containsKey(product.id)) {
      // Increase quantity if already in cart
      if (_items[product.id]!.quantity < product.stock) {
        _items[product.id]!.quantity++;
        notifyListeners();
      }
    } else {
      // Add new item to cart
      _items[product.id] = CartItem(
        product: product,
        quantity: 1,
        discount: product.discount,
      );
      notifyListeners();
    }
  }

  /// Update quantity of a cart item
  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;

    if (quantity <= 0) {
      removeItem(productId);
    } else if (quantity <= _items[productId]!.product.stock) {
      _items[productId]!.quantity = quantity;
      notifyListeners();
    }
  }

  /// Remove item from cart
  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  /// Clear all items from cart
  void clear() {
    _items.clear();
    notifyListeners();
  }

  /// Check if product is in cart
  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  /// Get quantity of a product in cart
  int getQuantity(String productId) {
    return _items[productId]?.quantity ?? 0;
  }

  /// Get cart items as a list
  List<CartItem> getCartItems() {
    return _items.values.toList();
  }
}

/// Cart Item Model
class CartItem {
  final ProductModel product;
  int quantity;
  final int? discount;

  CartItem({
    required this.product,
    required this.quantity,
    this.discount,
  });

  double get totalPrice {
    final price = discount != null && discount! > 0
        ? product.price * (1 - discount! / 100)
        : product.price;
    return price * quantity;
  }

  double get discountedPrice {
    return discount != null && discount! > 0
        ? product.price * (1 - discount! / 100)
        : product.price;
  }
}

