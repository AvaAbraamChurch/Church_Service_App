import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../core/styles/colors.dart';
import '../../core/models/store/order_model.dart';
import '../../core/providers/cart_provider.dart';
import '../../core/repositories/order_repository.dart';
import '../../core/repositories/store_repository.dart';
import '../../core/services/coupon_points_service.dart';
import '../../core/utils/userType_enum.dart';

class CartScreen extends StatefulWidget {
  const CartScreen({super.key});

  @override
  State<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends State<CartScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  final OrderRepository _orderRepo = OrderRepository();
  final StoreRepository _storeRepo = StoreRepository();
  final CouponPointsService _pointsService = CouponPointsService();
  bool _isProcessingOrder = false;

  // Form controllers for checkout
  final _notesController = TextEditingController();

  // User data for child payment system
  UserType? _userType;
  int _availablePoints = 0;
  bool _isChild = false;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(_animationController);
    _animationController.forward();
    _loadUserInfo();
  }

  @override
  void dispose() {
    _animationController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _loadUserInfo() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        final userDoc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();

        if (userDoc.exists) {
          final userData = userDoc.data() as Map<String, dynamic>;

          // Detect if user is a child
          final userTypeCode = userData['userType'] as String?;
          if (userTypeCode != null) {
            _userType = UserType.values.firstWhere(
              (type) => type.code == userTypeCode,
              orElse: () => UserType.child,
            );
            _isChild = _userType == UserType.child;
          }

          // Load coupon points for children
          if (_isChild) {
            _availablePoints = userData['couponPoints'] as int? ?? 0;
          }

          setState(() {});
        }
      }
    } catch (e) {
      print('Error loading user info: $e');
    }
  }

  void _clearCart() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal700,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          'تفريغ السلة',
          style: TextStyle(color: teal100, fontWeight: FontWeight.bold),
        ),
        content: Text(
          'هل أنت متأكد من تفريغ السلة؟',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(context);
              _showSnackBar('تم تفريغ السلة');
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _checkout() {
    final cart = Provider.of<CartProvider>(context, listen: false);
    if (cart.isEmpty) {
      _showSnackBar('السلة فارغة');
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _buildCheckoutSheet(),
    );
  }

  Future<void> _createOrder() async {
    final cart = Provider.of<CartProvider>(context, listen: false);


    setState(() => _isProcessingOrder = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        _showSnackBar('يرجى تسجيل الدخول أولاً');
        setState(() => _isProcessingOrder = false);
        return;
      }

      // Get user data
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();
      final userData = userDoc.data() as Map<String, dynamic>;

      // Calculate totals
      final subtotal = cart.subtotal;
      final discount = cart.discount;
      final total = cart.total;

      // For child users: Check if they have enough points to pay
      if (_isChild) {
        final requiredPoints = total.ceil(); // Points needed = order total
        if (_availablePoints < requiredPoints) {
          setState(() => _isProcessingOrder = false);
          _showSnackBar('ليس لديك نقاط كافية. تحتاج إلى $requiredPoints نقطة ولديك $_availablePoints نقطة');
          return;
        }
      }

      // Create order items
      final orderItems = cart.getCartItems().map((cartItem) {
        return OrderItem(
          productId: cartItem.product.id,
          productTitle: cartItem.product.title,
          productImageUrl: cartItem.product.imageUrls.isNotEmpty
              ? cartItem.product.imageUrls.first
              : null,
          price: cartItem.product.price,
          discountedPrice: cartItem.discountedPrice,
          quantity: cartItem.quantity,
          discount: cartItem.discount,
        );
      }).toList();


      // Create order
      final order = OrderModel(
        id: '', // Will be set by Firestore
        userId: user.uid,
        userName: userData['fullName'] ?? user.displayName ?? 'مستخدم',
        userPhone: userData['phoneNumber'] ?? '',
        items: orderItems,
        subtotal: subtotal,
        discount: discount,
        total: total,
        status: OrderStatus.pending,
        notes: _notesController.text.isEmpty ? null : _notesController.text,
        createdAt: DateTime.now(),
        metadata: _isChild ? {
          'paidWithPoints': true,
          'pointsDeducted': total.ceil(),
        } : null,
      );

      // Save order to Firestore
      final orderId = await _orderRepo.createOrder(order);

      // Deduct points from child user (order total = points to deduct)
      if (_isChild) {
        await _pointsService.deductPoints(user.uid, total.ceil(), orderId: orderId);
      }

      // Decrease stock for each product
      for (var cartItem in cart.getCartItems()) {
        await _storeRepo.decreaseStock(cartItem.product.id, cartItem.quantity);
      }

      setState(() => _isProcessingOrder = false);

      // Clear cart
      cart.clear();

      // Show success
      Navigator.pop(context); // Close checkout sheet
      _showSuccessDialog(orderId);
    } catch (e) {
      setState(() => _isProcessingOrder = false);
      _showSnackBar('فشل في إنشاء الطلب: ${e.toString()}');
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: teal500,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        duration: Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return ThemedScaffold(
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: IconButton(
              icon: Icon(Icons.arrow_back_ios, color: teal100),
              onPressed: () => Navigator.pop(context),
            ),
            title: Text(
              'السلة',
              style: TextStyle(
                color: teal100,
                fontWeight: FontWeight.bold,
                fontSize: 24,
              ),
            ),
            centerTitle: true,
            actions: [
              if (cart.isNotEmpty)
                IconButton(
                  icon: Icon(Icons.delete_outline, color: red500),
                  onPressed: _clearCart,
                  tooltip: 'تفريغ السلة',
                ),
            ],
          ),
          body: FadeTransition(
            opacity: _fadeAnimation,
            child: cart.isEmpty ? _buildEmptyCart() : _buildCartContent(cart),
          ),
        );
      },
    );
  }

  Widget _buildEmptyCart() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(40),
            decoration: BoxDecoration(
              color: teal700.withValues(alpha: 0.3),
              shape: BoxShape.circle,
              border: Border.all(color: teal300.withValues(alpha: 0.3), width: 2),
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 100,
              color: teal300.withValues(alpha: 0.5),
            ),
          ),
          SizedBox(height: 24),
          Text(
            'السلة فارغة',
            style: TextStyle(
              color: teal100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'لم تقم بإضافة أي منتجات بعد',
            style: TextStyle(
              color: Colors.white60,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.pop(context),
            icon: Icon(Icons.shopping_bag),
            label: Text('تصفح المنتجات'),
            style: ElevatedButton.styleFrom(
              backgroundColor: teal100,
              foregroundColor: teal900,
              padding: EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCartContent(CartProvider cart) {
    return Column(
      children: [
        // Cart Items List
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.all(16),
            itemCount: cart.itemCount,
            itemBuilder: (context, index) {
              final item = cart.getCartItems()[index];
              return _buildCartItem(item, cart);
            },
          ),
        ),
        // Summary Section
        _buildSummarySection(cart),
      ],
    );
  }

  Widget _buildCartItem(CartItem item, CartProvider cart) {
    return Dismissible(
      key: Key(item.product.id),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) {
        cart.removeItem(item.product.id);
        _showSnackBar('تمت إزالة ${item.product.title} من السلة');
      },
      background: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: red500,
          borderRadius: BorderRadius.circular(20),
        ),
        alignment: Alignment.centerLeft,
        padding: EdgeInsets.only(left: 20),
        child: Icon(Icons.delete_outline, color: Colors.white, size: 32),
      ),
      child: Container(
        margin: EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: teal700.withValues(alpha: 0.3),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: teal300.withValues(alpha: 0.3)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(12),
          child: Row(
            children: [
              // Product Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: teal500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: item.product.imageUrls.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(15),
                        child: Image.network(
                          item.product.imageUrls.first,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Center(
                              child: Icon(
                                Icons.shopping_bag_outlined,
                                size: 40,
                                color: teal100.withValues(alpha: 0.5),
                              ),
                            );
                          },
                        ),
                      )
                    : Center(
                        child: Icon(
                          Icons.shopping_bag_outlined,
                          size: 40,
                          color: teal100.withValues(alpha: 0.5),
                        ),
                      ),
              ),
              SizedBox(width: 12),
              // Product Info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      item.product.title,
                      style: TextStyle(
                        color: teal100,
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4),
                    if (item.product.category != null)
                      Text(
                        item.product.category!,
                        style: TextStyle(
                          color: teal300,
                          fontSize: 12,
                        ),
                      ),
                    SizedBox(height: 8),
                    Row(
                      children: [
                        if (item.discount != null && item.discount! > 0) ...[
                          Text(
                            '\$${item.product.price.toStringAsFixed(2)}',
                            style: TextStyle(
                              color: teal300.withValues(alpha: 0.6),
                              fontSize: 14,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                          SizedBox(width: 8),
                        ],
                        Text(
                          '\$${item.discountedPrice.toStringAsFixed(2)}',
                          style: TextStyle(
                            color: item.discount != null && item.discount! > 0
                                ? red300
                                : teal100,
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Spacer(),
                        // Quantity Controls
                        _buildQuantityControls(item, cart),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuantityControls(CartItem item, CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: teal500.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: teal300.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildQuantityButton(
            icon: Icons.remove,
            onPressed: () => cart.updateQuantity(item.product.id, item.quantity - 1),
          ),
          Container(
            constraints: BoxConstraints(minWidth: 32),
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              '${item.quantity}',
              style: TextStyle(
                color: teal100,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          _buildQuantityButton(
            icon: Icons.add,
            onPressed: item.quantity < item.product.stock
                ? () => cart.updateQuantity(item.product.id, item.quantity + 1)
                : null,
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityButton({required IconData icon, VoidCallback? onPressed}) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: EdgeInsets.all(8),
          child: Icon(
            icon,
            color: onPressed != null ? teal100 : Colors.white30,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildSummarySection(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: teal700,
        borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.3),
            blurRadius: 20,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Child user points balance
              if (_isChild) ...[
                Container(
                  padding: EdgeInsets.all(12),
                  margin: EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: brown500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: brown300.withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.stars, color: brown300, size: 24),
                          SizedBox(width: 8),
                          Text(
                            'نقاطك المتوفرة',
                            style: TextStyle(color: teal100, fontSize: 14),
                          ),
                        ],
                      ),
                      Text(
                        '$_availablePoints نقطة',
                        style: TextStyle(
                          color: brown300,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              // Subtotal
              _buildSummaryRow('المجموع الفرعي', cart.subtotal),
              if (cart.discount > 0) ...[
                SizedBox(height: 12),
                _buildSummaryRow('الخصم', -cart.discount, isDiscount: true),
              ],
              SizedBox(height: 16),
              Divider(color: teal300.withValues(alpha: 0.3), thickness: 1),
              SizedBox(height: 16),
              // Total
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _isChild ? 'المطلوب (نقاط)' : 'الإجمالي',
                    style: TextStyle(
                      color: teal100,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    _isChild
                        ? '${cart.total.ceil()} نقطة'
                        : '\$${cart.total.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: _isChild && _availablePoints < cart.total.ceil()
                          ? red500
                          : teal100,
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              if (_isChild && _availablePoints < cart.total.ceil()) ...[
                SizedBox(height: 12),
                Container(
                  padding: EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: red500.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: red500.withValues(alpha: 0.5), width: 2),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: red300, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'نقاط غير كافية!',
                              style: TextStyle(
                                color: red300,
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'تحتاج إلى ${cart.total.ceil() - _availablePoints} نقطة إضافية',
                              style: TextStyle(
                                color: red300,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              SizedBox(height: 24),
              // Checkout Button
              Container(
                width: double.infinity,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: (_isChild && _availablePoints < cart.total.ceil())
                        ? [Colors.grey.shade600, Colors.grey.shade700]
                        : [teal100, teal300],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: (_isChild && _availablePoints < cart.total.ceil())
                      ? []
                      : [
                          BoxShadow(
                            color: teal100.withValues(alpha: 0.4),
                            blurRadius: 20,
                            offset: Offset(0, 8),
                            spreadRadius: 2,
                          ),
                        ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: (_isChild && _availablePoints < cart.total.ceil())
                        ? null
                        : _checkout,
                    borderRadius: BorderRadius.circular(30),
                    child: Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            (_isChild && _availablePoints < cart.total.ceil())
                                ? Icons.lock
                                : Icons.payment,
                            color: (_isChild && _availablePoints < cart.total.ceil())
                                ? Colors.grey.shade400
                                : teal900,
                            size: 28,
                          ),
                          SizedBox(width: 12),
                          Text(
                            (_isChild && _availablePoints < cart.total.ceil())
                                ? 'نقاط غير كافية'
                                : 'إتمام الشراء',
                            style: TextStyle(
                              color: (_isChild && _availablePoints < cart.total.ceil())
                                  ? Colors.grey.shade400
                                  : teal900,
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryRow(String label, double amount, {bool isDiscount = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.white70,
            fontSize: 16,
          ),
        ),
        Text(
          '\$${amount.toStringAsFixed(2)}',
          style: TextStyle(
            color: isDiscount ? red300 : teal100,
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildCheckoutSheet() {
    final cart = Provider.of<CartProvider>(context, listen: false);

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
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
          SizedBox(height: 24),
          // Title
          Text(
            'إتمام الشراء',
            style: TextStyle(
              color: teal100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 24),
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Order Summary
                  _buildCheckoutSection(
                    'ملخص الطلب',
                    Icons.receipt_long,
                    Column(
                      children: [
                        ...cart.getCartItems().map((item) => Padding(
                              padding: EdgeInsets.only(bottom: 8),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(
                                      '${item.quantity}x ${item.product.title}',
                                      style: TextStyle(color: Colors.white70),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                                  Text(
                                    '\$${item.totalPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      color: teal100,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            )),
                        Divider(color: teal300.withValues(alpha: 0.3)),
                        SizedBox(height: 8),
                        if (cart.discount > 0) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'المجموع',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '\$${(cart.subtotal + cart.discount).toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: teal100,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'الخصم',
                                style: TextStyle(color: Colors.white70),
                              ),
                              Text(
                                '-\$${cart.discount.toStringAsFixed(2)}',
                                style: TextStyle(
                                  color: red300,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          SizedBox(height: 8),
                        ],
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'الإجمالي',
                              style: TextStyle(
                                color: teal100,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '\$${cart.total.toStringAsFixed(2)}',
                              style: TextStyle(
                                color: teal100,
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  SizedBox(height: 24),
                  // Notes section (optional)
                  _buildCheckoutSection(
                    'ملاحظات',
                    Icons.note,
                    TextField(
                      controller: _notesController,
                      style: TextStyle(color: Colors.white),
                      maxLines: 3,
                      decoration: InputDecoration(
                        hintText: 'ملاحظات إضافية (اختياري)',
                        hintStyle: TextStyle(color: Colors.white60),
                        prefixIcon: Padding(
                          padding: EdgeInsets.only(bottom: 48),
                          child: Icon(Icons.note, color: teal300),
                        ),
                        filled: true,
                        fillColor: teal500.withValues(alpha: 0.1),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: teal300.withValues(alpha: 0.3)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: teal300.withValues(alpha: 0.3)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(15),
                          borderSide: BorderSide(color: teal100, width: 2),
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 24),
                  // Insufficient points warning in checkout sheet
                  if (_isChild && _availablePoints < cart.total.ceil())
                    Container(
                      padding: EdgeInsets.all(12),
                      margin: EdgeInsets.only(bottom: 16),
                      decoration: BoxDecoration(
                        color: red500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: red500.withValues(alpha: 0.5), width: 2),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.warning_amber_rounded, color: red300, size: 24),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'نقاط غير كافية!',
                                  style: TextStyle(
                                    color: red300,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                SizedBox(height: 4),
                            Text(
                              'تحتاج إلى ${cart.total.ceil() - _availablePoints} نقطة إضافية',
                              style: TextStyle(
                                color: red300,
                                fontSize: 13,
                              ),
                            ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  // Confirm Button
                  Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: _isProcessingOrder
                            ? [teal300, teal300]
                            : (_isChild && _availablePoints < cart.total.ceil())
                                ? [Colors.grey.shade600, Colors.grey.shade700]
                                : [teal100, teal300],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: (_isChild && _availablePoints < cart.total.ceil())
                          ? []
                          : [
                              BoxShadow(
                                color: teal100.withValues(alpha: 0.4),
                                blurRadius: 15,
                                offset: Offset(0, 5),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: (_isProcessingOrder || (_isChild && _availablePoints < cart.total.ceil()))
                            ? null
                            : _createOrder,
                        borderRadius: BorderRadius.circular(28),
                        child: Center(
                          child: _isProcessingOrder
                              ? SizedBox(
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    color: teal900,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    if (_isChild && _availablePoints < cart.total.ceil())
                                      Icon(Icons.lock, color: Colors.grey.shade400, size: 20),
                                    if (_isChild && _availablePoints < cart.total.ceil())
                                      SizedBox(width: 8),
                                    Text(
                                      (_isChild && _availablePoints < cart.total.ceil())
                                          ? 'نقاط غير كافية'
                                          : 'تأكيد الطلب',
                                      style: TextStyle(
                                        color: (_isChild && _availablePoints < cart.total.ceil())
                                            ? Colors.grey.shade400
                                            : teal900,
                                        fontSize: 18,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutSection(String title, IconData icon, Widget content) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal500.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: teal300.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: teal100, size: 24),
              SizedBox(width: 12),
              Text(
                title,
                style: TextStyle(
                  color: teal100,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          content,
        ],
      ),
    );
  }

  void _showSuccessDialog(String orderId) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          padding: EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: teal700,
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: teal300.withValues(alpha: 0.3), width: 2),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: teal100.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.check_circle_outline,
                  size: 80,
                  color: teal100,
                ),
              ),
              SizedBox(height: 24),
              Text(
                'تم الطلب بنجاح!',
                style: TextStyle(
                  color: teal100,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 16),
              Text(
                'سيتم التواصل معك قريباً',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 16,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 32),
              ElevatedButton(
                onPressed: () {
                  Navigator.pop(context); // Close dialog
                  Navigator.pop(context); // Go back to store
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal100,
                  foregroundColor: teal900,
                  padding: EdgeInsets.symmetric(horizontal: 40, vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(30),
                  ),
                ),
                child: Text(
                  'حسناً',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


