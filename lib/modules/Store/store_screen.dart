import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/modules/Store/cart_screen.dart';
import 'package:church/modules/Store/order_tracking_screen.dart';
import 'package:church/shared/widgets.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/styles/colors.dart';
import '../../core/models/store/product_model.dart';
import '../../core/models/user/user_model.dart';
import '../../core/utils/gender_enum.dart';
import '../../core/repositories/store_repository.dart';
import '../../core/providers/cart_provider.dart';

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  final StoreRepository _storeRepo = StoreRepository();
  String _selectedCategory = 'الكل';
  List<String> _categories = ['الكل'];
  String? _userGenderCode; // Store the current user's gender code
  bool _isLoadingUser = true;

  @override
  void initState() {
    super.initState();
    _loadCurrentUser();
    _loadCategories();
  }

  Future<void> _loadCurrentUser() async {
    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .get();

        if (userDoc.exists) {
          final userData = UserModel.fromMap(userDoc.data(), id: userId);
          setState(() {
            _userGenderCode = userData.gender.code;
            _isLoadingUser = false;
          });
        } else {
          setState(() => _isLoadingUser = false);
        }
      } else {
        setState(() => _isLoadingUser = false);
      }
    } catch (e) {
      print('Error loading user: $e');
      setState(() => _isLoadingUser = false);
    }
  }

  Future<void> _loadCategories() async {
    try {
      final categories = await _storeRepo.getCategories();
      setState(() {
        _categories = [
          'الكل',
          ...categories.where((c) => c != null && c.isNotEmpty).cast<String>()
        ];
      });
    } catch (e) {
      print('Error loading categories: $e');
    }
  }

  // Helper method to calculate discounted price
  double _getDiscountedPrice(ProductModel product) {
    if (product.discount == null || product.discount! <= 0) {
      return product.price;
    }
    return product.price * (1 - product.discount! / 100);
  }

  // Helper method to check if product has discount
  bool _hasDiscount(ProductModel product) {
    return product.discount != null && product.discount! > 0;
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      body: CustomScrollView(
        slivers: [
          // Modern App Bar
          SliverAppBar(
            expandedHeight: 120,
            floating: false,
            pinned: true,
            backgroundColor: Colors.transparent,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: teal100),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              IconButton(
                icon: Icon(Icons.receipt_long, color: teal100),
                onPressed: () {
                  navigateTo(context, OrderTrackingScreen());
                },
                tooltip: 'تتبع الطلبات',
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              title: Text(
                'المعرض',
                style: TextStyle(
                  color: teal100,
                  fontWeight: FontWeight.bold,
                  fontSize: 24,
                ),
              ),
              centerTitle: true,
            ),
          ),

          // Search Bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Container(
                decoration: BoxDecoration(
                  color: teal700.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: teal300.withValues(alpha: 0.3)),
                ),
                child: TextField(
                  style: TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'ابحث عن منتج...',
                    hintStyle: TextStyle(color: Colors.white60),
                    prefixIcon: Icon(Icons.search, color: teal100),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 15),
                  ),
                  onChanged: (value) {
                    // TODO: Implement search
                  },
                ),
              ),
            ),
          ),

          // Categories
          SliverToBoxAdapter(
            child: Container(
              height: 50,
              margin: EdgeInsets.only(bottom: 16),
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: _categories.length,
                itemBuilder: (context, index) {
                  final category = _categories[index];
                  final isSelected = category == _selectedCategory;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedCategory = category;
                      });
                    },
                    child: AnimatedContainer(
                      duration: Duration(milliseconds: 300),
                      margin: EdgeInsets.only(right: 12),
                      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      decoration: BoxDecoration(
                        color: isSelected ? teal100 : teal700.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(25),
                        border: Border.all(
                          color: isSelected ? teal100 : teal300.withValues(alpha: 0.3),
                          width: 1.5,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: teal100.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: Offset(0, 4),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: Text(
                          category,
                          style: TextStyle(
                            color: isSelected ? teal900 : teal100,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // Products Grid with StreamBuilder
          StreamBuilder<List<ProductModel>>(
            stream: _isLoadingUser || _userGenderCode == null
                ? const Stream.empty()
                : (_selectedCategory == 'الكل'
                    ? _storeRepo.watchProductsByUserGender(_userGenderCode!)
                    : _storeRepo.watchProductsByUserGenderAndCategory(_userGenderCode!, _selectedCategory)),
            builder: (context, snapshot) {
              // Show loading while user data is loading
              if (_isLoadingUser) {
                return SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildLoadingCard(),
                      childCount: 6,
                    ),
                  ),
                );
              }

              // Loading state
              if (snapshot.connectionState == ConnectionState.waiting) {
                return SliverPadding(
                  padding: EdgeInsets.all(16),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.7,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                    ),
                    delegate: SliverChildBuilderDelegate(
                      (context, index) => _buildLoadingCard(),
                      childCount: 6,
                    ),
                  ),
                );
              }

              // Error state
              if (snapshot.hasError) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.error_outline, size: 80, color: red500),
                        SizedBox(height: 16),
                        Text(
                          'حدث خطأ في تحميل المنتجات',
                          style: TextStyle(color: teal100, fontSize: 18),
                        ),
                        SizedBox(height: 8),
                        Text(
                          snapshot.error.toString(),
                          style: TextStyle(color: teal300, fontSize: 12),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }

              final products = snapshot.data ?? [];

              // Empty state
              if (products.isEmpty) {
                return SliverFillRemaining(
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_bag_outlined,
                          size: 80,
                          color: teal300.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد منتجات',
                          style: TextStyle(
                            color: teal100,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          _selectedCategory == 'الكل'
                              ? 'لم يتم إضافة أي منتجات بعد'
                              : 'لا توجد منتجات في هذه الفئة',
                          style: TextStyle(
                            color: teal300,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }

              // Products loaded successfully
              return SliverPadding(
                padding: EdgeInsets.all(16),
                sliver: SliverGrid(
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.7,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) => _buildProductCard(products[index]),
                    childCount: products.length,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      floatingActionButton: _buildModernCartButton(),
    );
  }

  Widget _buildLoadingCard() {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 800),
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Container(
            decoration: BoxDecoration(
              color: teal700.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: teal300.withValues(alpha: 0.2)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Image placeholder
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: teal500.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Center(
                      child: _buildShimmer(
                        child: Container(
                          width: 60,
                          height: 60,
                          decoration: BoxDecoration(
                            color: teal300.withValues(alpha: 0.3),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
                // Text placeholders
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        _buildShimmer(
                          child: Container(
                            width: double.infinity,
                            height: 16,
                            decoration: BoxDecoration(
                              color: teal300.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildShimmer(
                          child: Container(
                            width: 80,
                            height: 14,
                            decoration: BoxDecoration(
                              color: teal300.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                        Spacer(),
                        _buildShimmer(
                          child: Container(
                            width: 60,
                            height: 20,
                            decoration: BoxDecoration(
                              color: teal100.withValues(alpha: 0.3),
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildShimmer({required Widget child}) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.3, end: 1.0),
      duration: Duration(milliseconds: 1000),
      builder: (context, value, _) {
        return Opacity(
          opacity: 0.3 + (value * 0.4),
          child: child,
        );
      },
      onEnd: () {
        // Loop the animation
        if (mounted) {
          setState(() {});
        }
      },
    );
  }

  Widget _buildProductCard(ProductModel product) {
    final bool isOutOfStock = product.stock == 0;

    return GestureDetector(
      onTap: isOutOfStock ? null : () {
        // Navigate to product details only if in stock
        _showProductDetails(product);
      },
      child: Hero(
        tag: 'product_${product.id}',
        child: Opacity(
          opacity: isOutOfStock ? 0.5 : 1.0,
          child: Container(
            decoration: BoxDecoration(
              color: isOutOfStock
                  ? teal700.withValues(alpha: 0.15)
                  : teal700.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isOutOfStock
                    ? teal300.withValues(alpha: 0.15)
                    : teal300.withValues(alpha: 0.3),
              ),
              boxShadow: isOutOfStock ? [] : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  blurRadius: 10,
                  offset: Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      color: teal500.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    child: Stack(
                      children: [
                        if (product.imageUrls.isNotEmpty)
                          ClipRRect(
                            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                            child: Image.network(
                              product.imageUrls.first,
                              fit: BoxFit.cover,
                              width: double.infinity,
                              height: double.infinity,
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Center(
                                  child: CircularProgressIndicator(
                                    valueColor: AlwaysStoppedAnimation<Color>(teal100),
                                    value: loadingProgress.expectedTotalBytes != null
                                        ? loadingProgress.cumulativeBytesLoaded /
                                            loadingProgress.expectedTotalBytes!
                                        : null,
                                  ),
                                );
                              },
                              errorBuilder: (context, error, stackTrace) {
                                return Center(
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 60,
                                    color: teal300.withValues(alpha: 0.5),
                                  ),
                                );
                              },
                            ),
                          ),
                        // Discount badge
                        if (_hasDiscount(product))
                          Positioned(
                            top: 8,
                            left: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [red500, red700],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: [
                                  BoxShadow(
                                    color: red500.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: Text(
                                '-${product.discount}%',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Stock badge
                        if (product.stock < 10)
                          Positioned(
                            top: 8,
                            right: 8,
                            child: Container(
                              padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: product.stock == 0 ? red500 : brown500,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: product.stock == 0 ? [
                                  BoxShadow(
                                    color: red500.withValues(alpha: 0.5),
                                    blurRadius: 8,
                                    offset: Offset(0, 2),
                                  ),
                                ] : [],
                              ),
                              child: Text(
                                product.stock == 0 ? 'نفذ' : 'محدود',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        // Out of stock overlay
                        if (isOutOfStock)
                          Positioned.fill(
                            child: Container(
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.6),
                                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                              ),
                              child: Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.remove_shopping_cart_outlined,
                                      color: Colors.white,
                                      size: 40,
                                    ),
                                    SizedBox(height: 8),
                                    Text(
                                      'غير متوفر',
                                      style: TextStyle(
                                        color: Colors.white,
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Product Info
                Expanded(
                  flex: 2,
                  child: Padding(
                    padding: EdgeInsets.all(10),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Flexible(
                              child: Text(
                                product.title,
                                style: TextStyle(
                                  color: teal100,
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                            if (product.category != null) ...[
                              SizedBox(height: 3),
                              Text(
                                product.category!,
                                style: TextStyle(
                                  color: teal300,
                                  fontSize: 10,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                            Spacer(flex: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (_hasDiscount(product)) ...[
                                        Text(
                                          '\$${product.price.toStringAsFixed(2)}',
                                          style: TextStyle(
                                            color: teal300.withValues(alpha: 0.6),
                                            fontSize: 11,
                                            decoration: TextDecoration.lineThrough,
                                            decorationColor: teal300.withValues(alpha: 0.6),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        SizedBox(height: 2),
                                      ],
                                      Text(
                                        '\$${_getDiscountedPrice(product).toStringAsFixed(2)}',
                                        style: TextStyle(
                                          color: _hasDiscount(product) ? red300 : teal100,
                                          fontSize: 15,
                                          fontWeight: FontWeight.bold,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ],
                                  ),
                                ),
                                SizedBox(width: 6),
                                GestureDetector(
                                  onTap: isOutOfStock ? null : () {
                                    final cart = Provider.of<CartProvider>(context, listen: false);
                                    cart.addItem(product);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تمت الإضافة إلى السلة'),
                                        backgroundColor: teal500,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 1),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  },
                                  child: Container(
                                    padding: EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: isOutOfStock ? teal300.withValues(alpha: 0.3) : teal100,
                                      shape: BoxShape.circle,
                                    ),
                                    child: Icon(
                                      Icons.add_shopping_cart,
                                      size: 14,
                                      color: isOutOfStock ? teal500 : teal900,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showProductDetails(ProductModel product) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => Container(
        height: MediaQuery.of(context).size.height * 0.7,
        decoration: BoxDecoration(
          color: teal700,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
          border: Border.all(color: teal300.withValues(alpha: 0.3), width: 2),
        ),
        child: Column(
          children: [
            // Handle bar
            Container(
              margin: EdgeInsets.only(top: 12),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: teal300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Image
                    Container(
                      height: 200,
                      decoration: BoxDecoration(
                        color: teal500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: product.imageUrls.isNotEmpty
                            ? Image.network(
                                product.imageUrls.first,
                                fit: BoxFit.cover,
                                // width: double.infinity,
                                // height: double.infinity,
                                loadingBuilder: (context, child, loadingProgress) {
                                  if (loadingProgress == null) return child;
                                  return Center(
                                    child: CircularProgressIndicator(
                                      valueColor: AlwaysStoppedAnimation<Color>(teal100),
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  );
                                },
                                errorBuilder: (context, error, stackTrace) {
                                  return Center(
                                    child: Icon(
                                      Icons.broken_image,
                                      size: 60,
                                      color: teal300.withValues(alpha: 0.5),
                                    ),
                                  );
                                },
                              )
                            : Center(
                                child: Icon(
                                  Icons.image_not_supported,
                                  size: 60,
                                  color: teal300.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    ),
                    SizedBox(height: 24),
                    // Title
                    Text(
                      product.title,
                      style: TextStyle(
                        color: teal100,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    // Category
                    if (product.category != null)
                      Container(
                        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: teal500.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          product.category!,
                          style: TextStyle(color: teal100, fontSize: 12),
                        ),
                      ),
                    SizedBox(height: 16),
                    // Description
                    if (product.description != null)
                      Text(
                        product.description!,
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 16,
                          height: 1.5,
                        ),
                      ),
                    SizedBox(height: 24),
                    // Discount info (if applicable)
                    if (_hasDiscount(product))
                      Container(
                        padding: EdgeInsets.all(12),
                        margin: EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [red500.withValues(alpha: 0.2), red700.withValues(alpha: 0.2)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: red300.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.local_offer, color: red300, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'خصم ${product.discount}% - وفر \$${(product.price - _getDiscountedPrice(product)).toStringAsFixed(2)}',
                              style: TextStyle(
                                color: red300,
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    // Stock info
                    Row(
                      children: [
                        Icon(Icons.inventory_2_outlined, color: teal100, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'متوفر: ${product.stock} قطعة',
                          style: TextStyle(color: teal100, fontSize: 14),
                        ),
                      ],
                    ),
                    SizedBox(height: 32),
                    // Price and Add to Cart
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'السعر',
                                style: TextStyle(
                                  color: teal300,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 4),
                              if (_hasDiscount(product)) ...[
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    '\$${product.price.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: teal300.withValues(alpha: 0.6),
                                      fontSize: 16,
                                      decoration: TextDecoration.lineThrough,
                                      decorationColor: teal300.withValues(alpha: 0.6),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 4),
                              ],
                              FittedBox(
                                fit: BoxFit.scaleDown,
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  '\$${_getDiscountedPrice(product).toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: _hasDiscount(product) ? red300 : teal100,
                                    fontSize: 28,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: ElevatedButton(
                            onPressed: product.stock > 0
                                ? () {
                                    final cart = Provider.of<CartProvider>(context, listen: false);
                                    cart.addItem(product);
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: Text('تمت الإضافة إلى السلة'),
                                        backgroundColor: teal500,
                                        behavior: SnackBarBehavior.floating,
                                        duration: Duration(seconds: 2),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(10),
                                        ),
                                      ),
                                    );
                                  }
                                : null,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal100,
                              foregroundColor: teal900,
                              padding: EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(15),
                              ),
                            ),
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                product.stock > 0 ? 'أضف للسلة' : 'نفذ',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildModernCartButton() {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        final int cartItemCount = cart.totalQuantity;

        return Container(
          margin: EdgeInsets.symmetric(horizontal: 20),
          height: 60,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [teal100, teal300],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(30),
            boxShadow: [
              BoxShadow(
                color: teal100.withValues(alpha: 0.4),
                blurRadius: 20,
                offset: Offset(0, 8),
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.2),
                blurRadius: 15,
                offset: Offset(0, 5),
              ),
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                navigateTo(context, CartScreen());
              },
              borderRadius: BorderRadius.circular(30),
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Cart Icon with Badge
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        Icon(
                          Icons.shopping_cart_rounded,
                          color: teal900,
                          size: 28,
                        ),
                        if (cartItemCount > 0)
                          Positioned(
                            right: -8,
                            top: -8,
                            child: Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: red500,
                                shape: BoxShape.circle,
                                border: Border.all(color: teal100, width: 2),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 20,
                                minHeight: 20,
                              ),
                              child: Center(
                                child: Text(
                                  cartItemCount > 99 ? '99+' : cartItemCount.toString(),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    SizedBox(width: 12),
                    // Text
                    Text(
                      'عرض السلة',
                      style: TextStyle(
                        color: teal900,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                    SizedBox(width: 8),
                    // Arrow Icon
                    Icon(
                      Icons.arrow_forward_rounded,
                      color: teal900,
                      size: 20,
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
