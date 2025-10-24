import 'package:church/core/constants/strings.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../core/styles/colors.dart';
import '../../core/models/store/order_model.dart';
import '../../core/repositories/order_repository.dart';

class OrderTrackingScreen extends StatelessWidget {
  const OrderTrackingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final orderRepo = OrderRepository();

    return ThemedScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: Text('تتبع الطلبات', style: TextStyle(color: teal100)),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: teal100),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: user == null
          ? _buildNotLoggedIn()
          : StreamBuilder<List<OrderModel>>(
              stream: orderRepo.watchOrdersByUser(user.uid),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(
                    child: CircularProgressIndicator(color: teal100),
                  );
                }

                if (snapshot.hasError) {
                  print('Order tracking error: ${snapshot.error}');
                  return Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.error_outline, size: 80, color: red500),
                          SizedBox(height: 16),
                          Text(
                            'حدث خطأ في تحميل الطلبات',
                            style: TextStyle(color: teal100, fontSize: 18),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 8),
                          Text(
                            snapshot.error.toString(),
                            style: TextStyle(color: teal300, fontSize: 12),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: teal500,
                              foregroundColor: Colors.white,
                            ),
                            child: Text('العودة'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                final orders = snapshot.data ?? [];

                if (orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 80,
                          color: teal300.withValues(alpha: 0.5),
                        ),
                        SizedBox(height: 16),
                        Text(
                          'لا توجد طلبات',
                          style: TextStyle(
                            color: teal100,
                            fontSize: 18,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'لم تقم بإنشاء أي طلبات بعد',
                          style: TextStyle(
                            color: teal300,
                            fontSize: 14,
                          ),
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
                    return _buildOrderCard(context, order);
                  },
                );
              },
            ),
    );
  }

  Widget _buildNotLoggedIn() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.login, size: 80, color: teal300),
          SizedBox(height: 16),
          Text(
            'يرجى تسجيل الدخول أولاً',
            style: TextStyle(
              color: teal100,
              fontSize: 18,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrderCard(BuildContext context, OrderModel order) {
    Color statusColor = _getStatusColor(order.status);

    return Container(
      margin: EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: teal700.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statusColor.withValues(alpha: 0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
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
          child: Icon(
            _getStatusIcon(order.status),
            color: statusColor,
            size: 24,
          ),
        ),
        title: Text(
          'طلبي',
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

          // Order Items
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
          ...order.items.map((item) => Padding(
                padding: EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    if (item.productImageUrl != null)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.network(
                          item.productImageUrl!,
                          width: 40,
                          height: 40,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(
                              width: 40,
                              height: 40,
                              color: teal500.withValues(alpha: 0.2),
                              child: Icon(Icons.image, color: teal300, size: 20),
                            );
                          },
                        ),
                      ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.productTitle,
                            style: TextStyle(color: teal100, fontSize: 14),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'الكمية: ${item.quantity}',
                            style: TextStyle(color: teal300, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '\$${item.totalPrice.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: teal100,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )),

          Divider(color: teal300.withValues(alpha: 0.3)),

          // Admin Notes
          if (order.notes != null && order.notes!.isNotEmpty) ...[
            SizedBox(height: 12),
            Container(
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
                        'ملاحظات من ال$servant:',
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
          ],

          // Order Summary
          SizedBox(height: 16),
          _buildOrderDetailRow('المجموع الفرعي:', '\$${order.subtotal.toStringAsFixed(2)}'),
          if (order.discount > 0)
            _buildOrderDetailRow(
              'الخصم:',
              '-\$${order.discount.toStringAsFixed(2)}',
              valueColor: red300,
            ),
          SizedBox(height: 8),
          _buildOrderDetailRow(
            'الإجمالي:',
            '\$${order.total.toStringAsFixed(2)}',
            valueColor: brown300,
            isBold: true,
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

  Color _getStatusColor(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return brown500;
      case OrderStatus.processing:
        return Colors.blue;
      case OrderStatus.completed:
        return Colors.green;
      case OrderStatus.cancelled:
        return red500;
      case OrderStatus.refunded:
        return Colors.orange;
    }
  }

  IconData _getStatusIcon(OrderStatus status) {
    switch (status) {
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.processing:
        return Icons.refresh;
      case OrderStatus.completed:
        return Icons.check_circle;
      case OrderStatus.cancelled:
        return Icons.cancel;
      case OrderStatus.refunded:
        return Icons.refresh;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return 'غير محدد';
    return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  }
}

