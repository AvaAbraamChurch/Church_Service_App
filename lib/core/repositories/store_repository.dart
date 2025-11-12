import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/store/product_model.dart';

/// Repository for managing store products with Firestore integration.
/// Provides real-time streams and CRUD operations for products.
class StoreRepository {
  final FirebaseFirestore _firestore;
  final String _collectionPath;

  StoreRepository({
    FirebaseFirestore? firestore,
    String collectionPath = 'products',
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _collectionPath = collectionPath;

  /// Reference to the products collection
  CollectionReference get _productsCollection =>
      _firestore.collection(_collectionPath);

  // ==================== STREAM METHODS ====================

  /// Stream all active products in real-time
  Stream<List<ProductModel>> watchAllProducts() {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream all products (including inactive) in real-time
  Stream<List<ProductModel>> watchAllProductsIncludingInactive() {
    return _productsCollection
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream products by category in real-time
  Stream<List<ProductModel>> watchProductsByCategory(String category) {
    return _productsCollection
        .where('category', isEqualTo: category)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream products with available stock in real-time
  Stream<List<ProductModel>> watchInStockProducts() {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .where('stock', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream products with discounts in real-time
  Stream<List<ProductModel>> watchDiscountedProducts() {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .where('discount', isGreaterThan: 0)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }

  /// Stream a single product by ID in real-time
  Stream<ProductModel?> watchProduct(String productId) {
    return _productsCollection.doc(productId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return ProductModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    });
  }

  /// Stream products by user gender in real-time
  /// Returns products where userGender matches the given gender OR userGender is 'ALL'
  Stream<List<ProductModel>> watchProductsByUserGender(String genderCode) {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .where((product) =>
                product.userGender == null ||
                product.userGender == 'ALL' ||
                product.userGender == genderCode)
            .toList());
  }

  /// Stream products by user gender and category in real-time
  Stream<List<ProductModel>> watchProductsByUserGenderAndCategory(
    String genderCode,
    String category
  ) {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .where('category', isEqualTo: category)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .where((product) =>
                product.userGender == null ||
                product.userGender == 'ALL' ||
                product.userGender == genderCode)
            .toList());
  }

  // ==================== FUTURE METHODS (One-time fetch) ====================

  /// Get all active products (one-time fetch)
  Future<List<ProductModel>> getAllProducts() async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products: $e');
    }
  }

  /// Get a single product by ID (one-time fetch)
  Future<ProductModel?> getProductById(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      if (!doc.exists) return null;

      return ProductModel.fromFirestore(
        doc.data() as Map<String, dynamic>,
        doc.id,
      );
    } catch (e) {
      throw Exception('Failed to fetch product: $e');
    }
  }

  /// Get products by category (one-time fetch)
  Future<List<ProductModel>> getProductsByCategory(String category) async {
    try {
      final snapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by category: $e');
    }
  }

  /// Get products by user gender (one-time fetch)
  /// Returns products where userGender matches the given gender OR userGender is 'ALL'
  Future<List<ProductModel>> getProductsByUserGender(String genderCode) async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((product) =>
              product.userGender == null ||
              product.userGender == 'ALL' ||
              product.userGender == genderCode)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by user gender: $e');
    }
  }

  /// Get products by user gender and category (one-time fetch)
  Future<List<ProductModel>> getProductsByUserGenderAndCategory(
    String genderCode,
    String category
  ) async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('category', isEqualTo: category)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .where((product) =>
              product.userGender == null ||
              product.userGender == 'ALL' ||
              product.userGender == genderCode)
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch products by user gender and category: $e');
    }
  }

  /// Get all unique categories
  Future<List<String?>> getCategories() async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .get();

      final categories = snapshot.docs
          .map((doc) => (doc.data() as Map<String, dynamic>)['category'] as String?)
          .where((category) => category != null && category.isNotEmpty)
          .toSet()
          .toList();

      categories.sort();
      return categories;
    } catch (e) {
      throw Exception('Failed to fetch categories: $e');
    }
  }

  /// Search products by title (one-time fetch)
  Future<List<ProductModel>> searchProducts(String query) async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .startAt([query])
          .endAt(['$query\uf8ff'])
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to search products: $e');
    }
  }

  // ==================== CREATE / UPDATE / DELETE ====================

  /// Create a new product
  /// If userGender is provided, it will override the product's userGender
  /// If userGender is not provided and product has no userGender
  Future<String> createProduct(ProductModel product, String userGender) async {
    try {
      final productData = product.toFirestore(includeId: false);

      // Set userGender: use provided parameter, or product's userGender, or default to 'ALL'
      productData['userGender'] = userGender;

      productData['createdAt'] = FieldValue.serverTimestamp();
      productData['updatedAt'] = FieldValue.serverTimestamp();

      final docRef = await _productsCollection.add(productData);
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create product: $e');
    }
  }

  /// Update an existing product
  Future<void> updateProduct(ProductModel product) async {
    try {
      final productData = product.toFirestore(includeId: false);
      productData['updatedAt'] = FieldValue.serverTimestamp();

      await _productsCollection.doc(product.id).update(productData);
    } catch (e) {
      throw Exception('Failed to update product: $e');
    }
  }

  /// Update specific fields of a product
  Future<void> updateProductFields(
    String productId,
    Map<String, dynamic> fields,
  ) async {
    try {
      fields['updatedAt'] = FieldValue.serverTimestamp();
      await _productsCollection.doc(productId).update(fields);
    } catch (e) {
      throw Exception('Failed to update product fields: $e');
    }
  }

  /// Update product stock
  Future<void> updateStock(String productId, int newStock) async {
    try {
      await _productsCollection.doc(productId).update({
        'stock': newStock,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to update stock: $e');
    }
  }

  /// Decrease product stock (for purchases)
  Future<void> decreaseStock(String productId, int quantity) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final docRef = _productsCollection.doc(productId);
        final snapshot = await transaction.get(docRef);

        if (!snapshot.exists) {
          throw Exception('Product not found');
        }

        final currentStock = (snapshot.data() as Map<String, dynamic>)['stock'] as int;
        if (currentStock < quantity) {
          throw Exception('Insufficient stock');
        }

        transaction.update(docRef, {
          'stock': currentStock - quantity,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      });
    } catch (e) {
      throw Exception('Failed to decrease stock: $e');
    }
  }

  /// Increase product stock (for restocking)
  Future<void> increaseStock(String productId, int quantity) async {
    try {
      await _productsCollection.doc(productId).update({
        'stock': FieldValue.increment(quantity),
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to increase stock: $e');
    }
  }

  /// Toggle product active status
  Future<void> toggleActiveStatus(String productId, bool isActive) async {
    try {
      await _productsCollection.doc(productId).update({
        'isActive': isActive,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to toggle active status: $e');
    }
  }

  /// Delete a product (hard delete)
  Future<void> deleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).delete();
    } catch (e) {
      throw Exception('Failed to delete product: $e');
    }
  }

  /// Soft delete a product (mark as inactive)
  Future<void> softDeleteProduct(String productId) async {
    try {
      await _productsCollection.doc(productId).update({
        'isActive': false,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to soft delete product: $e');
    }
  }

  // ==================== BATCH OPERATIONS ====================

  /// Create multiple products in a batch
  /// If userGender is provided, it will be applied to all products
  Future<void> createProductsBatch(List<ProductModel> products, {String? userGender}) async {
    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final docRef = _productsCollection.doc();
        final productData = product.toFirestore(includeId: false);

        // Set userGender: use provided parameter, or product's userGender, or default to 'ALL'
        productData['userGender'] = userGender ?? product.userGender ?? 'ALL';

        productData['createdAt'] = FieldValue.serverTimestamp();
        productData['updatedAt'] = FieldValue.serverTimestamp();
        batch.set(docRef, productData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to create products batch: $e');
    }
  }

  /// Update multiple products in a batch
  Future<void> updateProductsBatch(List<ProductModel> products) async {
    try {
      final batch = _firestore.batch();

      for (final product in products) {
        final docRef = _productsCollection.doc(product.id);
        final productData = product.toFirestore(includeId: false);
        productData['updatedAt'] = FieldValue.serverTimestamp();
        batch.update(docRef, productData);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to update products batch: $e');
    }
  }

  /// Delete multiple products in a batch
  Future<void> deleteProductsBatch(List<String> productIds) async {
    try {
      final batch = _firestore.batch();

      for (final productId in productIds) {
        final docRef = _productsCollection.doc(productId);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e) {
      throw Exception('Failed to delete products batch: $e');
    }
  }

  // ==================== UTILITY METHODS ====================

  /// Check if a product exists
  Future<bool> productExists(String productId) async {
    try {
      final doc = await _productsCollection.doc(productId).get();
      return doc.exists;
    } catch (e) {
      throw Exception('Failed to check product existence: $e');
    }
  }

  /// Get total product count
  Future<int> getTotalProductCount() async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to get product count: $e');
    }
  }

  /// Get total product count by category
  Future<int> getProductCountByCategory(String category) async {
    try {
      final snapshot = await _productsCollection
          .where('category', isEqualTo: category)
          .where('isActive', isEqualTo: true)
          .get();
      return snapshot.size;
    } catch (e) {
      throw Exception('Failed to get product count by category: $e');
    }
  }

  /// Get products with low stock (below threshold)
  Future<List<ProductModel>> getLowStockProducts(int threshold) async {
    try {
      final snapshot = await _productsCollection
          .where('isActive', isEqualTo: true)
          .where('stock', isLessThanOrEqualTo: threshold)
          .get();

      return snapshot.docs
          .map((doc) => ProductModel.fromFirestore(
                doc.data() as Map<String, dynamic>,
                doc.id,
              ))
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch low stock products: $e');
    }
  }

  /// Stream products with low stock
  Stream<List<ProductModel>> watchLowStockProducts(int threshold) {
    return _productsCollection
        .where('isActive', isEqualTo: true)
        .where('stock', isLessThanOrEqualTo: threshold)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => ProductModel.fromFirestore(
                  doc.data() as Map<String, dynamic>,
                  doc.id,
                ))
            .toList());
  }
}

