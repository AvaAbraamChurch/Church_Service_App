import 'package:church/core/constants/strings.dart';
import 'package:church/core/models/store/order_model.dart';
import 'package:church/core/models/store/product_model.dart';
import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/order_repository.dart';
import 'package:church/core/repositories/store_repository.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/gender_enum.dart';
import 'package:church/core/utils/userType_enum.dart';
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
                  child: Icon(Icons.admin_panel_settings,
                      size: 35, color: teal900),
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

            final pendingOrders =
                orders.where((o) => o.status == OrderStatus.pending).length;
            final completedOrders =
                orders.where((o) => o.status == OrderStatus.completed).length;
            final totalRevenue = orders
                .where((o) => o.status == OrderStatus.completed)
                .fold(0.0, (sum, order) => sum + order.total);
            final activeProducts =
                products.where((p) => p.isActive).length;
            final lowStockProducts =
                products.where((p) => p.stock < 10 && p.stock > 0).length;
            final outOfStockProducts =
                products.where((p) => p.stock == 0).length;

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
                        border: Border.all(color: red500.withValues(alpha: 0.3)),
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
      String title, String value, IconData icon, Color color) {
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
    return Column(
      children: [
        // Add Product Button
        Padding(
          padding: EdgeInsets.all(16),
          child: ElevatedButton.icon(
            onPressed: () => _showAddProductDialog(),
            icon: Icon(Icons.add),
            label: Text('إضافة منتج جديد'),
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
              padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ),

        // Products List
        Expanded(
          child: StreamBuilder<List<ProductModel>>(
            stream: _storeRepo.watchAllProductsIncludingInactive(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return Center(
                  child: CircularProgressIndicator(color: teal100),
                );
              }

              if (snapshot.hasError) {
                return Center(
                  child: Text(
                    'حدث خطأ: ${snapshot.error}',
                    style: TextStyle(color: red500),
                  ),
                );
              }

              final products = snapshot.data ?? [];

              if (products.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.inventory_2_outlined,
                          size: 80, color: teal300),
                      SizedBox(height: 16),
                      Text(
                        'لا توجد منتجات',
                        style: TextStyle(color: teal300, fontSize: 18),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                padding: EdgeInsets.symmetric(horizontal: 16),
                itemCount: products.length,
                itemBuilder: (context, index) {
                  final product = products[index];
                  return _buildProductManagementCard(product);
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildProductManagementCard(ProductModel product) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: teal700.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: product.isActive
              ? teal300.withValues(alpha: 0.3)
              : red300.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          ListTile(
            contentPadding: EdgeInsets.all(12),
            leading: product.imageUrls.isNotEmpty
                ? ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      product.imageUrls.first,
                      width: 60,
                      height: 60,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) {
                        return Container(
                          width: 60,
                          height: 60,
                          color: teal500.withValues(alpha: 0.2),
                          child: Icon(Icons.broken_image, color: teal300),
                        );
                      },
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
                SizedBox(height: 4),
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
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: red500,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'غير نشط',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                SizedBox(width: 8),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: teal100),
                  color: teal700,
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, color: teal100, size: 20),
                          SizedBox(width: 8),
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
                          SizedBox(width: 8),
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
                          SizedBox(width: 8),
                          Text('حذف', style: TextStyle(color: red500)),
                        ],
                      ),
                    ),
                  ],
                  onSelected: (value) {
                    if (value == 'edit') {
                      _showEditProductDialog(product);
                    } else if (value == 'toggle') {
                      _toggleProductStatus(product);
                    } else if (value == 'delete') {
                      _deleteProduct(product);
                    }
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ==================== ORDERS TAB ====================
  Widget _buildOrdersTab() {
    return StreamBuilder<List<OrderModel>>(
      stream: _orderRepo.watchAllOrders(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(
            child: CircularProgressIndicator(color: teal100),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text(
              'حدث خطأ: ${snapshot.error}',
              style: TextStyle(color: red500),
            ),
          );
        }

        final orders = snapshot.data ?? [];

        if (orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_cart_outlined, size: 80, color: teal300),
                SizedBox(height: 16),
                Text(
                  'لا توجد طلبات',
                  style: TextStyle(color: teal300, fontSize: 18),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          padding: EdgeInsets.all(16),
          itemCount: orders.length,
          itemBuilder: (context, index) {
            final order = orders[index];
            return _buildOrderCard(order);
          },
        );
      },
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
          ...order.items.map((item) => Padding(
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
              )),

          Divider(color: teal300.withValues(alpha: 0.3)),

          // Order Summary
          _buildOrderDetailRow('المجموع الفرعي:',
              '\$${order.subtotal.toStringAsFixed(2)}'),
          if (order.discount > 0)
            _buildOrderDetailRow(
                'الخصم:', '-\$${order.discount.toStringAsFixed(2)}',
                valueColor: red300),
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
                        order, OrderStatus.processing),
                    icon: Icon(Icons.hourglass_empty, size: 18),
                    label: Text('معالجة'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    ),
                  ),
                if (order.status == OrderStatus.processing)
                  ElevatedButton.icon(
                    onPressed: () => _showUpdateOrderStatusDialog(
                        order, OrderStatus.completed),
                    icon: Icon(Icons.check_circle, size: 18),
                    label: Text('إكمال'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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

  Widget _buildOrderDetailRow(String label, String value,
      {Color? valueColor, bool isBold = false}) {
    return Padding(
      padding: EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(color: teal300, fontSize: 13),
          ),
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

  // ==================== PRODUCT CRUD OPERATIONS ====================

  void _showAddProductDialog() {
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    final priceController = TextEditingController();
    final stockController = TextEditingController();
    final discountController = TextEditingController();
    final categoryController = TextEditingController();
    final imageUrlController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal700,
        title: Text('إضافة منتج جديد', style: TextStyle(color: teal100)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: teal100),
                decoration: InputDecoration(
                  labelText: 'اسم المنتج',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: TextStyle(color: teal100),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: priceController,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: stockController,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية المتوفرة',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: discountController,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'نسبة الخصم (اختياري)',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: TextStyle(color: teal100),
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                style: TextStyle(color: teal100),
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            onPressed: () async {
              if (titleController.text.isEmpty ||
                  priceController.text.isEmpty ||
                  stockController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('يرجى ملء الحقول المطلوبة'),
                    backgroundColor: red500,
                  ),
                );
                return;
              }

              try {
                final product = ProductModel(
                  id: '', // Will be set by Firestore
                  title: titleController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  price: double.parse(priceController.text),
                  stock: int.parse(stockController.text),
                  discount: discountController.text.isEmpty
                      ? null
                      : int.parse(discountController.text),
                  category: categoryController.text.isEmpty
                      ? null
                      : categoryController.text,
                  imageUrls: imageUrlController.text.isEmpty
                      ? []
                      : [imageUrlController.text],
                  isActive: true,
                  createdAt: DateTime.now(),
                );

                await _storeRepo.createProduct(product, widget.currentUser.gender.code);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
            ),
            child: Text('إضافة'),
          ),
        ],
      ),
    );
  }

  void _showEditProductDialog(ProductModel product) {
    final titleController = TextEditingController(text: product.title);
    final descriptionController =
        TextEditingController(text: product.description ?? '');
    final priceController =
        TextEditingController(text: product.price.toString());
    final stockController =
        TextEditingController(text: product.stock.toString());
    final discountController =
        TextEditingController(text: product.discount?.toString() ?? '');
    final categoryController =
        TextEditingController(text: product.category ?? '');
    final imageUrlController = TextEditingController(
        text: product.imageUrls.isNotEmpty ? product.imageUrls.first : '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal700,
        title: Text('تعديل المنتج', style: TextStyle(color: teal100)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: titleController,
                style: TextStyle(color: teal100),
                decoration: InputDecoration(
                  labelText: 'اسم المنتج',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: descriptionController,
                style: TextStyle(color: teal100),
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'الوصف',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: priceController,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'السعر',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: stockController,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'الكمية المتوفرة',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: discountController,
                style: TextStyle(color: teal100),
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: 'نسبة الخصم (اختياري)',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: categoryController,
                style: TextStyle(color: teal100),
                decoration: InputDecoration(
                  labelText: 'الفئة',
                  labelStyle: TextStyle(color: teal300),
                  enabledBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal300),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderSide: BorderSide(color: teal100),
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: imageUrlController,
                style: TextStyle(color: teal100),
                decoration: InputDecoration(
                  labelText: 'رابط الصورة',
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
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                final updatedProduct = product.copyWith(
                  title: titleController.text,
                  description: descriptionController.text.isEmpty
                      ? null
                      : descriptionController.text,
                  price: double.parse(priceController.text),
                  stock: int.parse(stockController.text),
                  discount: discountController.text.isEmpty
                      ? null
                      : int.parse(discountController.text),
                  category: categoryController.text.isEmpty
                      ? null
                      : categoryController.text,
                  imageUrls: imageUrlController.text.isEmpty
                      ? []
                      : [imageUrlController.text],
                  updatedAt: DateTime.now(),
                );

                await _storeRepo.updateProduct(updatedProduct);
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
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
            style: ElevatedButton.styleFrom(
              backgroundColor: teal500,
              foregroundColor: Colors.white,
            ),
            child: Text('حفظ'),
          ),
        ],
      ),
    );
  }

  Future<void> _toggleProductStatus(ProductModel product) async {
    try {
      await _storeRepo.toggleActiveStatus(product.id, !product.isActive);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
              product.isActive ? 'تم إخفاء المنتج' : 'تم إظهار المنتج'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('فشل في تحديث حالة المنتج'),
          backgroundColor: red500,
        ),
      );
    }
  }

  Future<void> _deleteProduct(ProductModel product) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: teal700,
        title: Text('تأكيد الحذف', style: TextStyle(color: teal100)),
        content: Text(
          'هل أنت متأكد من حذف "${product.title}"؟',
          style: TextStyle(color: teal300),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('إلغاء', style: TextStyle(color: teal300)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: red500,
              foregroundColor: Colors.white,
            ),
            child: Text('حذف'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _storeRepo.deleteProduct(product.id);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('تم حذف المنتج بنجاح'),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('فشل في حذف المنتج'),
            backgroundColor: red500,
          ),
        );
      }
    }
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
                hintText: 'مثال: تم التجهيز وجاهز للاستلام من الكنيسة يوم الأحد',
                hintStyle: TextStyle(color: teal300.withValues(alpha: 0.5), fontSize: 12),
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
                hintStyle: TextStyle(color: teal300.withValues(alpha: 0.5), fontSize: 12),
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

  Future<void> _updateOrderStatus(String orderId, OrderStatus status, {String? notes}) async {
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
}

