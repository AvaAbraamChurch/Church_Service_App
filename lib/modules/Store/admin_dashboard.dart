import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/store/order_model.dart';
import 'package:church/core/models/store/product_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/order_repository.dart';
import 'package:church/core/repositories/store_repository.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../core/styles/colors.dart';

class AdminDashboard extends StatefulWidget {
  final UserModel currentUser;

  const AdminDashboard({super.key, required this.currentUser});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final StoreRepository _storeRepo = StoreRepository();
  final OrderRepository _orderRepo = OrderRepository();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ThemedScaffold(
      appBar: AppBar(
        backgroundColor: teal700,
        title: Text('لوحة تحكم المعرض', style: TextStyle(color: teal100)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: teal100),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Admin Info Card
          Container(
            margin: EdgeInsets.all(16),
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [teal700, teal500],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: teal300.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: teal100,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 35,
                    color: teal900,
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.currentUser.fullName,
                        style: TextStyle(
                          color: teal100,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        widget.currentUser.userType.label,
                        style: TextStyle(color: teal300, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Tab Bar
          Container(
            margin: EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: teal700.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(25),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: teal500,
                borderRadius: BorderRadius.circular(25),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              dividerColor: Colors.transparent,
              labelColor: teal100,
              unselectedLabelColor: teal300,
              tabs: [
                Tab(text: 'نظرة عامة'),
                Tab(text: 'المنتجات'),
                Tab(text: 'الطلبات'),
              ],
            ),
          ),

          // Tab Views
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildOverviewTab(),
                _buildProductsTab(),
                _buildOrdersTab(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== OVERVIEW TAB ====================
  Widget _buildOverviewTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.watchAllOrders(),
      builder: (context, ordersSnapshot) {
        return StreamBuilder<List<ProductModel>>(
          stream: _storeRepo.watchAllProductsIncludingInactive(),
          builder: (context, productsSnapshot) {
            final orders = ordersSnapshot.data ?? [];
            final products = productsSnapshot.data ?? [];

            final pendingOrders = orders
                .where((o) => o.status == OrderStatus.pending)
                .length;
            final completedOrders = orders
                .where((o) => o.status == OrderStatus.completed)
                .length;
            final totalRevenue = orders
                .where((o) => o.status == OrderStatus.completed)
                .fold(0.0, (sum, order) => sum + order.total);
            final activeProducts = products.where((p) => p.isActive).length;
            final lowStockProducts = products
                .where((p) => p.stock < 10 && p.stock > 0)
                .length;
            final outOfStockProducts = products
                .where((p) => p.stock == 0)
                .length;

            return SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Statistics Grid
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1.3,
                    children: [
                      _buildStatCard(
                        'إجمالي الطلبات',
                        orders.length.toString(),
                        Icons.shopping_bag_outlined,
                        teal500,
                      ),
                      _buildStatCard(
                        'قيد الانتظار',
                        pendingOrders.toString(),
                        Icons.hourglass_empty,
                        brown500,
                      ),
                      _buildStatCard(
                        'مكتملة',
                        completedOrders.toString(),
                        Icons.check_circle_outline,
                        Colors.green,
                      ),
                      _buildStatCard(
                        'الإيرادات',
                        '\$${totalRevenue.toStringAsFixed(2)}',
                        Icons.attach_money,
                        brown500,
                      ),
                      _buildStatCard(
                        'منتجات نشطة',
                        activeProducts.toString(),
                        Icons.inventory_2_outlined,
                        teal500,
                      ),
                      _buildStatCard(
                        'مخزون منخفض',
                        lowStockProducts.toString(),
                        Icons.warning_amber_outlined,
                        Colors.orange,
                      ),
                    ],
                  ),

                  SizedBox(height: 24),

                  // Out of Stock Alert
                  if (outOfStockProducts > 0)
                    Container(
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: red500.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: red500.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: red500, size: 30),
                          SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'تنبيه مخزون',
                                  style: TextStyle(
                                    color: red300,
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '$outOfStockProducts منتج نفذ من المخزون',
                                  style: TextStyle(color: red300, fontSize: 14),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                  SizedBox(height: 24),

                  // Recent Orders
                  Text(
                    'أحدث الطلبات',
                    style: TextStyle(
                      color: teal100,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 12),
                  if (orders.isEmpty)
                    Center(
                      child: Padding(
                        padding: EdgeInsets.all(32),
                        child: Text(
                          'لا توجد طلبات',
                          style: TextStyle(color: teal300, fontSize: 16),
                        ),
                      ),
                    )
                  else
                    ...orders.take(5).map((order) => _buildOrderCard(order)),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildStatCard(
    String title,
    String value,
    IconData icon,
    Color color,
  ) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal700.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: teal100,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(color: teal300, fontSize: 12),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ==================== PRODUCTS TAB ====================
  Widget _buildProductsTab() {
    return _AdminProductsTab(storeRepo: _storeRepo);
  }

  // ==================== ORDERS TAB ====================
  Widget _buildOrdersTab() {
    return _AdminOrdersTab(
      orderRepo: _orderRepo,
      buildOrderCard: _buildOrderCard,
    );
  }

  Widget _buildOrderCard(OrderModel order) {
    Color statusColor = switch (order.status) {
      OrderStatus.pending => brown500,
      OrderStatus.processing => Colors.blue,
      OrderStatus.completed => Colors.green,
      OrderStatus.cancelled => red500,
      OrderStatus.refunded => Colors.orange,
    };

    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: teal700.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.all(16),
        childrenPadding: EdgeInsets.all(16),
        leading: Container(
          padding: EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: statusColor.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.shopping_bag, color: statusColor, size: 24),
        ),
        title: Text(
          order.userName,
          style: TextStyle(
            color: teal100,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 4),
            Text(
              'المبلغ: \$${order.total.toStringAsFixed(2)}',
              style: TextStyle(color: teal300, fontSize: 14),
            ),
            SizedBox(height: 2),
            Row(
              children: [
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: statusColor,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    order.status.label,
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                SizedBox(width: 8),
                _buildGenderBadge(order.metadata?['userGender'] as String?),
                SizedBox(width: 8),
                Text(
                  _formatDate(order.createdAt),
                  style: TextStyle(color: teal300, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
        trailing: Icon(Icons.expand_more, color: teal100),
        children: [
          Divider(color: teal300.withValues(alpha: 0.3)),
          SizedBox(height: 8),

          // Order Details
          _buildOrderDetailRow('ال$child:', order.userName),
          if (order.userPhone != null)
            _buildOrderDetailRow('الهاتف:', order.userPhone!),

          // Admin Notes
          if (order.notes != null && order.notes!.isNotEmpty)
            Container(
              margin: EdgeInsets.only(top: 12, bottom: 12),
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: brown500.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: brown300.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(Icons.note_alt, color: brown300, size: 16),
                      SizedBox(width: 4),
                      Text(
                        'ملاحظات ال$servant:',
                        style: TextStyle(
                          color: brown300,
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 6),
                  Text(
                    order.notes!,
                    style: TextStyle(color: teal100, fontSize: 13),
                  ),
                ],
              ),
            ),

          SizedBox(height: 12),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              'المنتجات:',
              style: TextStyle(
                color: teal100,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          SizedBox(height: 8),

          // Order Items
          ...order.items.map(
            (item) => Padding(
              padding: EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${item.productTitle} x${item.quantity}',
                      style: TextStyle(color: teal300, fontSize: 13),
                    ),
                  ),
                  Text(
                    '\$${item.totalPrice.toStringAsFixed(2)}',
                    style: TextStyle(
                      color: teal100,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),

          Divider(color: teal300.withValues(alpha: 0.3)),

          // Order Summary
          _buildOrderDetailRow(
            'المجموع الفرعي:',
            '\$${order.subtotal.toStringAsFixed(2)}',
          ),
          if (order.discount > 0)
            _buildOrderDetailRow(
              'الخصم:',
              '-\$${order.discount.toStringAsFixed(2)}',
              valueColor: red300,
            ),
          _buildOrderDetailRow(
            'الإجمالي:',
            '\$${order.total.toStringAsFixed(2)}',
            valueColor: brown300,
            isBold: true,
          ),

          SizedBox(height: 16),

          // Action Buttons
          if (order.status == OrderStatus.pending ||
              order.status == OrderStatus.processing)
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (order.status == OrderStatus.pending)
                  ElevatedButton.icon(
                    onPressed: () => _showUpdateOrderStatusDialog(
                      order,
                      OrderStatus.processing,
                    ),
                    icon: Icon(Icons.hourglass_empty, size: 18),
                    label: Text('معالجة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                if (order.status == OrderStatus.processing)
                  ElevatedButton.icon(
                    onPressed: () => _showUpdateOrderStatusDialog(
                      order,
                      OrderStatus.completed,
                    ),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('إكمال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),
                    ),
                  ),
                ElevatedButton.icon(
                  onPressed: () => _showCancelOrderDialog(order),
                  icon: Icon(Icons.cancel, size: 18),
                  label: Text('إلغاء'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: red500,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  ),
                ),
              ],
            ),
        ],
      ),
    );
  }

  Widget _buildOrderDetailRow(
    String label,
    String value, {
    Color? valueColor,
    bool isBold = false,
  }) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: teal300, fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              color: valueColor ?? teal100,
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ORDER OPERATIONS ====================

  void _showUpdateOrderStatusDialog(OrderModel order, OrderStatus newStatus) {
    final notesController = TextEditingController(text: order.notes ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal700,
        title: Text(
          newStatus == OrderStatus.processing ? 'معالجة الطلب' : 'إكمال الطلب',
          style: TextStyle(color: teal100),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'يمكنك إضافة ملاحظات للعميل (اختياري):',
              style: TextStyle(color: teal300, fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              style: TextStyle(color: teal100),
              maxLines: 4,
              decoration: InputDecoration(
                hintText:
                    'مثال: تم التجهيز وجاهز للاستلام من الكنيسة يوم الأحد',
                hintStyle: TextStyle(
                  color: teal300.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                labelText: 'الملاحظات',
                labelStyle: TextStyle(color: teal300),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: teal300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: teal100),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(
                order.id,
                newStatus,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: newStatus == OrderStatus.processing
                  ? Colors.blue
                  : Colors.green,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد'),
          ),
        ],
      ),
    );
  }

  void _showCancelOrderDialog(OrderModel order) {
    final notesController = TextEditingController(text: order.notes ?? '');

    // Check if order was paid with points
    final paidWithPoints = order.metadata?['paidWithPoints'] as bool? ?? false;
    final pointsDeducted = order.metadata?['pointsDeducted'] as int? ?? 0;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal700,
        title: Text(
          'إلغاء الطلب',
          style: TextStyle(color: red300, fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'هل أنت متأكد من إلغاء هذا الطلب؟',
              style: TextStyle(color: teal300, fontSize: 16),
            ),
            SizedBox(height: 16),

            // Show points refund notice if applicable
            if (paidWithPoints && pointsDeducted > 0) ...[
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: brown500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: brown300.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Icon(Icons.info_outline, color: brown300, size: 20),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'سيتم إرجاع $pointsDeducted نقطة إلى حساب ال$child',
                        style: TextStyle(
                          color: brown300,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 16),
            ],

            Text(
              'يمكنك إضافة ملاحظات للعميل (اختياري):',
              style: TextStyle(color: teal300, fontSize: 14),
            ),
            SizedBox(height: 12),
            TextField(
              controller: notesController,
              style: TextStyle(color: teal100),
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'مثال: تم إلغاء الطلب بسبب نفاد المخزون',
                hintStyle: TextStyle(
                  color: teal300.withValues(alpha: 0.5),
                  fontSize: 12,
                ),
                labelText: 'سبب الإلغاء',
                labelStyle: TextStyle(color: teal300),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: teal300),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: teal100),
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('رجوع', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(context);
              await _updateOrderStatus(
                order.id,
                OrderStatus.cancelled,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
            ),
            child: Text('تأكيد الإلغاء'),
          ),
        ],
      ),
    );
  }

  Future<void> _updateOrderStatus(
    String orderId,
    OrderStatus status, {
    String? notes,
  }) async {
    try {
      await _orderRepo.updateOrderStatus(orderId, status, notes: notes);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('تم تحديث حالة الطلب'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحديث حالة الطلب'),
          backgroundColor: red500,
        ),
      );
    }
  }

  // ==================== UTILITIES ====================

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }

  Widget _buildGenderBadge(String? genderCode) {
    if (genderCode == null || genderCode == 'ALL' || genderCode.isEmpty) {
      return Container(
        padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: teal500.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: teal500.withValues(alpha: 0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined, size: 11, color: teal300),
            SizedBox(width: 3),
            Text('الكل', style: TextStyle(color: teal300, fontSize: 10)),
          ],
        ),
      );
    }
    final isMale = genderCode == 'M';
    final color = isMale ? Colors.blue : Colors.pink;
    final icon = isMale ? Icons.male : Icons.female;
    final label = isMale ? 'ذكر' : 'أنثى';
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 11, color: color),
          SizedBox(width: 3),
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

// =====================================================================
// Isolated Products Tab — has its own setState so typing in the search
// bar never triggers a rebuild of the parent AdminDashboard.
// =====================================================================
class _AdminProductsTab extends StatefulWidget {
  final StoreRepository storeRepo;

  const _AdminProductsTab({required this.storeRepo});

  @override
  State<_AdminProductsTab> createState() => _AdminProductsTabState();
}

class _AdminProductsTabState extends State<_AdminProductsTab> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  String? _selectedCategory;
  // null = all, 'M' = male, 'F' = female
  String? _selectedGender;

  // Cached full list so filtering never triggers a new Firestore read.
  List<ProductModel> _allProducts = [];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<ProductModel> get _filtered => _allProducts.where((p) {
    final q = _searchQuery.toLowerCase();
    final matchesSearch =
        q.isEmpty ||
        p.title.toLowerCase().contains(q) ||
        (p.description?.toLowerCase().contains(q) ?? false) ||
        (p.category?.toLowerCase().contains(q) ?? false);
    final matchesCategory =
        _selectedCategory == null || p.category == _selectedCategory;
    final matchesGender =
        _selectedGender == null ||
        p.userGender == null ||
        p.userGender == 'ALL' ||
        p.userGender == _selectedGender;
    return matchesSearch && matchesCategory && matchesGender;
  }).toList();

  List<String> get _categories =>
      _allProducts
          .map((p) => p.category)
          .where((c) => c != null && c.isNotEmpty)
          .cast<String>()
          .toSet()
          .toList()
        ..sort();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ProductModel>>(
      stream: widget.storeRepo.watchAllProductsIncludingInactive(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _allProducts.isEmpty) {
          return Center(child: CircularProgressIndicator(color: teal100));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
              style: TextStyle(color: red500),
            ),
          );
        }

        // Update cached list without calling setState — the StreamBuilder
        // already schedules a rebuild when new data arrives.
        if (snapshot.hasData) {
          _allProducts = snapshot.data!;
        }

        final filtered = _filtered;
        final categories = _categories;

        return Column(
          children: [
            // ── Add Product Button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: ElevatedButton.icon(
                onPressed: _showAddProductDialog,
                icon: const Icon(Icons.add),
                label: const Text('إضافة منتج جديد'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: teal500,
                  foregroundColor: Colors.white,
                  minimumSize: const Size(double.infinity, 48),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),

            // ── Search bar ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: TextField(
                controller: _searchController,
                style: TextStyle(color: teal100),
                // Only setState here — rebuilds THIS widget only, not the page
                onChanged: (val) => setState(() => _searchQuery = val.trim()),
                decoration: InputDecoration(
                  hintText: 'ابحث عن منتج...',
                  hintStyle: TextStyle(color: teal300.withValues(alpha: 0.7)),
                  prefixIcon: Icon(Icons.search, color: teal300),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear, color: teal300),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  filled: true,
                  fillColor: teal700.withValues(alpha: 0.3),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: teal300.withValues(alpha: 0.4),
                    ),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: teal300),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                ),
              ),
            ),

            // ── Category filter chips ──
            if (categories.isNotEmpty)
              SizedBox(
                height: 46,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 4,
                  ),
                  children: [
                    Padding(
                      padding: const EdgeInsets.only(left: 8),
                      child: FilterChip(
                        label: const Text('الكل'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                        backgroundColor: teal700.withValues(alpha: 0.3),
                        selectedColor: teal500,
                        labelStyle: TextStyle(
                          color: _selectedCategory == null
                              ? Colors.white
                              : teal100,
                          fontWeight: _selectedCategory == null
                              ? FontWeight.bold
                              : FontWeight.normal,
                        ),
                        side: BorderSide(
                          color: _selectedCategory == null
                              ? teal500
                              : teal300.withValues(alpha: 0.4),
                        ),
                        showCheckmark: false,
                      ),
                    ),
                    ...categories.map((cat) {
                      final isSelected = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(left: 8),
                        child: FilterChip(
                          label: Text(cat),
                          selected: isSelected,
                          onSelected: (_) => setState(
                            () => _selectedCategory = isSelected ? null : cat,
                          ),
                          backgroundColor: teal700.withValues(alpha: 0.3),
                          selectedColor: teal500,
                          labelStyle: TextStyle(
                            color: isSelected ? Colors.white : teal100,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.normal,
                          ),
                          side: BorderSide(
                            color: isSelected
                                ? teal500
                                : teal300.withValues(alpha: 0.4),
                          ),
                          showCheckmark: false,
                        ),
                      );
                    }),
                  ],
                ),
              ),

            // ── Results count ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Row(
                children: [
                  // Gender filter chips
                  _genderChip(null, 'الكل', Icons.people_alt_outlined, teal500),
                  const SizedBox(width: 8),
                  _genderChip('M', 'ذكر', Icons.male, Colors.blue),
                  const SizedBox(width: 8),
                  _genderChip('F', 'أنثى', Icons.female, Colors.pink),
                  const Spacer(),
                  Text(
                    '${filtered.length} منتج',
                    style: TextStyle(color: teal300, fontSize: 13),
                  ),
                ],
              ),
            ),

            // ── Products list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.search_off, size: 64, color: teal300),
                          const SizedBox(height: 12),
                          Text(
                            'لا توجد منتجات مطابقة',
                            style: TextStyle(color: teal300, fontSize: 16),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          _buildProductCard(filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _genderChip(String? code, String label, IconData icon, Color color) {
    final isSelected = _selectedGender == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.25)
              : teal700.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : teal300.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : teal300),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : teal300,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _productGenderBadge(String? genderCode) {
    if (genderCode == null || genderCode == 'ALL' || genderCode.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        decoration: BoxDecoration(
          color: teal500.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(6),
          border: Border.all(color: teal500.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.people_alt_outlined, size: 11, color: teal300),
            const SizedBox(width: 3),
            Text('للجميع', style: TextStyle(color: teal300, fontSize: 10)),
          ],
        ),
      );
    }
    final isMale = genderCode == 'M';
    final color = isMale ? Colors.blue : Colors.pink;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isMale ? Icons.male : Icons.female, size: 11, color: color),
          const SizedBox(width: 3),
          Text(
            isMale ? 'ذكر' : 'أنثى',
            style: TextStyle(
              color: color,
              fontSize: 10,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }

  // ── Product card ──
  Widget _buildProductCard(ProductModel product) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: teal700.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isActive
              ? teal300.withValues(alpha: 0.3)
              : red300.withValues(alpha: 0.3),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: product.imageUrls.isNotEmpty
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: product.imageUrls.first,
                  width: 60,
                  height: 60,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => SizedBox(
                    width: 60,
                    height: 60,
                    child: Center(
                      child: SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: teal100,
                        ),
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    width: 60,
                    height: 60,
                    color: teal500.withValues(alpha: 0.2),
                    child: Icon(Icons.broken_image, color: teal300),
                  ),
                ),
              )
            : Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  color: teal500.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(Icons.image, color: teal300),
              ),
        title: Text(
          product.title,
          style: TextStyle(
            color: teal100,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                _productGenderBadge(product.userGender),
                if (product.category != null) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 6,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: teal700.withValues(alpha: 0.4),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: teal300.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      product.category!,
                      style: TextStyle(color: teal300, fontSize: 10),
                    ),
                  ),
                ],
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'السعر: \$${product.price.toStringAsFixed(2)}',
              style: TextStyle(color: teal300, fontSize: 14),
            ),
            Text(
              'المخزون: ${product.stock}',
              style: TextStyle(
                color: product.stock == 0
                    ? red300
                    : product.stock < 10
                    ? Colors.orange
                    : teal300,
                fontSize: 14,
              ),
            ),
            if (product.discount != null && product.discount! > 0)
              Text(
                'خصم: ${product.discount}%',
                style: TextStyle(color: red300, fontSize: 14),
              ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!product.isActive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: red500,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'غير نشط',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            const SizedBox(width: 8),
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert, color: teal100),
              color: teal700,
              itemBuilder: (_) => [
                PopupMenuItem(
                  value: 'edit',
                  child: Row(
                    children: [
                      Icon(Icons.edit, color: teal100, size: 20),
                      const SizedBox(width: 8),
                      Text('تعديل', style: TextStyle(color: teal100)),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'toggle',
                  child: Row(
                    children: [
                      Icon(
                        product.isActive
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: teal100,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        product.isActive ? 'إخفاء' : 'إظهار',
                        style: TextStyle(color: teal100),
                      ),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'delete',
                  child: Row(
                    children: [
                      Icon(Icons.delete, color: red500, size: 20),
                      const SizedBox(width: 8),
                      Text('حذف', style: TextStyle(color: red500)),
                    ],
                  ),
                ),
              ],
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditProductDialog(product);
                } else if (value == 'toggle') {
                  _toggleStatus(product);
                } else if (value == 'delete') {
                  _deleteProduct(product);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  // ── CRUD helpers ──

  InputDecoration _fieldDecoration(String label) => InputDecoration(
    labelText: label,
    labelStyle: TextStyle(color: teal300),
    enabledBorder: OutlineInputBorder(borderSide: BorderSide(color: teal300)),
    focusedBorder: OutlineInputBorder(borderSide: BorderSide(color: teal100)),
  );

  void _showAddProductDialog() {
    final titleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController();
    final discountCtrl = TextEditingController();
    final categoryCtrl = TextEditingController();
    final imageCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: teal700,
        title: Text('إضافة منتج جديد', style: TextStyle(color: teal100)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: teal100),
                decoration: _fieldDecoration('اسم المنتج'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: teal100),
                maxLines: 3,
                decoration: _fieldDecoration('الوصف'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('السعر'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockCtrl,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('الكمية المتوفرة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('نسبة الخصم (اختياري)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: TextStyle(color: teal100),
                decoration: _fieldDecoration('الفئة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                style: TextStyle(color: teal100),
                decoration: _fieldDecoration('رابط الصورة'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              if (titleCtrl.text.isEmpty ||
                  priceCtrl.text.isEmpty ||
                  stockCtrl.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('يرجى ملء الحقول المطلوبة'),
                    backgroundColor: red500,
                  ),
                );
                return;
              }
              try {
                final product = ProductModel(
                  id: '',
                  title: titleCtrl.text,
                  description: descCtrl.text.isEmpty ? null : descCtrl.text,
                  price: double.parse(priceCtrl.text),
                  stock: int.parse(stockCtrl.text),
                  discount: discountCtrl.text.isEmpty
                      ? null
                      : int.parse(discountCtrl.text),
                  category: categoryCtrl.text.isEmpty
                      ? null
                      : categoryCtrl.text,
                  imageUrls: imageCtrl.text.isEmpty ? [] : [imageCtrl.text],
                  isActive: true,
                  createdAt: DateTime.now(),
                );
                await widget.storeRepo.createProduct(product, 'ALL');
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم إضافة المنتج بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل في إضافة المنتج: $e'),
                    backgroundColor: red500,
                  ),
                );
              }
            },
            child: const Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    final titleCtrl = TextEditingController(text: product.title);
    final descCtrl = TextEditingController(text: product.description ?? '');
    final priceCtrl = TextEditingController(text: product.price.toString());
    final stockCtrl = TextEditingController(text: product.stock.toString());
    final discountCtrl = TextEditingController(
      text: product.discount?.toString() ?? '',
    );
    final categoryCtrl = TextEditingController(text: product.category ?? '');
    final imageCtrl = TextEditingController(
      text: product.imageUrls.isNotEmpty ? product.imageUrls.first : '',
    );

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: teal700,
        title: Text('تعديل المنتج', style: TextStyle(color: teal100)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleCtrl,
                style: TextStyle(color: teal100),
                decoration: _fieldDecoration('اسم المنتج'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: descCtrl,
                style: TextStyle(color: teal100),
                maxLines: 3,
                decoration: _fieldDecoration('الوصف'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: priceCtrl,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('السعر'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: stockCtrl,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('الكمية المتوفرة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: discountCtrl,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: _fieldDecoration('نسبة الخصم (اختياري)'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: categoryCtrl,
                style: TextStyle(color: teal100),
                decoration: _fieldDecoration('الفئة'),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: imageCtrl,
                style: TextStyle(color: teal100),
                decoration: _fieldDecoration('رابط الصورة'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              try {
                final updated = product.copyWith(
                  title: titleCtrl.text,
                  description: descCtrl.text.isEmpty ? null : descCtrl.text,
                  price: double.parse(priceCtrl.text),
                  stock: int.parse(stockCtrl.text),
                  discount: discountCtrl.text.isEmpty
                      ? null
                      : int.parse(discountCtrl.text),
                  category: categoryCtrl.text.isEmpty
                      ? null
                      : categoryCtrl.text,
                  imageUrls: imageCtrl.text.isEmpty ? [] : [imageCtrl.text],
                  updatedAt: DateTime.now(),
                );
                await widget.storeRepo.updateProduct(updated);
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('تم تحديث المنتج بنجاح'),
                    backgroundColor: Colors.green,
                  ),
                );
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('فشل في تحديث المنتج: $e'),
                    backgroundColor: red500,
                  ),
                );
              }
            },
            child: const Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleStatus(ProductModel product) async {
    try {
      await widget.storeRepo.toggleActiveStatus(product.id, !product.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            product.isActive ? 'تم إخفاء المنتج' : 'تم إظهار المنتج',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (_) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('فشل في تحديث حالة المنتج'),
          backgroundColor: red500,
        ),
      );
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: teal700,
        title: Text('تأكيد الحذف', style: TextStyle(color: teal100)),
        content: Text(
          'هل أنت متأكد من حذف "${product.title}"؟',
          style: TextStyle(color: teal300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('حذف'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      try {
        await widget.storeRepo.deleteProduct(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('تم حذف المنتج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('فشل في حذف المنتج'),
            backgroundColor: red500,
          ),
        );
      }
    }
  }
}

// =====================================================================
// Isolated Orders Tab — has its own setState for gender filter so it
// never triggers a rebuild of the parent AdminDashboard.
// =====================================================================
class _AdminOrdersTab extends StatefulWidget {
  final OrderRepository orderRepo;
  final Widget Function(OrderModel order) buildOrderCard;

  const _AdminOrdersTab({
    required this.orderRepo,
    required this.buildOrderCard,
  });

  @override
  State<_AdminOrdersTab> createState() => _AdminOrdersTabState();
}

class _AdminOrdersTabState extends State<_AdminOrdersTab> {
  // null = all, 'M' = male, 'F' = female
  String? _selectedGender;
  List<OrderModel> _allOrders = [];

  List<OrderModel> get _filtered => _allOrders.where((o) {
    if (_selectedGender == null) return true;
    final g = o.metadata?['userGender'] as String?;
    return g == _selectedGender;
  }).toList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<OrderModel>>(
      stream: widget.orderRepo.watchAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting &&
            _allOrders.isEmpty) {
          return Center(child: CircularProgressIndicator(color: teal100));
        }
        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
              style: TextStyle(color: red500),
            ),
          );
        }
        if (snapshot.hasData) _allOrders = snapshot.data!;

        final filtered = _filtered;

        return Column(
          children: [
            // ── Gender filter bar ──
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Row(
                children: [
                  Text(
                    'فلترة:',
                    style: TextStyle(color: teal300, fontSize: 13),
                  ),
                  const SizedBox(width: 10),
                  _genderChip(null, 'الكل', Icons.people_alt_outlined, teal500),
                  const SizedBox(width: 8),
                  _genderChip('M', 'ذكر', Icons.male, Colors.blue),
                  const SizedBox(width: 8),
                  _genderChip('F', 'أنثى', Icons.female, Colors.pink),
                  const Spacer(),
                  Text(
                    '${filtered.length} طلب',
                    style: TextStyle(color: teal300, fontSize: 13),
                  ),
                ],
              ),
            ),

            // ── Orders list ──
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.shopping_cart_outlined,
                            size: 80,
                            color: teal300,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'لا توجد طلبات',
                            style: TextStyle(color: teal300, fontSize: 18),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: filtered.length,
                      itemBuilder: (context, index) =>
                          widget.buildOrderCard(filtered[index]),
                    ),
            ),
          ],
        );
      },
    );
  }

  Widget _genderChip(String? code, String label, IconData icon, Color color) {
    final isSelected = _selectedGender == code;
    return GestureDetector(
      onTap: () => setState(() => _selectedGender = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: isSelected
              ? color.withValues(alpha: 0.25)
              : teal700.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? color : teal300.withValues(alpha: 0.3),
            width: isSelected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: isSelected ? color : teal300),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? color : teal300,
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
