import 'package:flutter/material.dart';
import 'package:church/core/services/points_sync_service.dart';
import 'package:church/core/repositories/local_points_repository.dart';
import 'package:church/core/styles/colors.dart';

/// Widget to show pending points sync status and trigger manual sync
class PointsSyncStatusWidget extends StatefulWidget {
  const PointsSyncStatusWidget({super.key});

  @override
  State<PointsSyncStatusWidget> createState() => _PointsSyncStatusWidgetState();
}

class _PointsSyncStatusWidgetState extends State<PointsSyncStatusWidget> {
  final PointsSyncService _syncService = PointsSyncService();
  final LocalPointsRepository _localRepo = LocalPointsRepository();
  bool _syncing = false;

  Future<void> _syncNow() async {
    setState(() => _syncing = true);

    try {
      final result = await _syncService.syncPendingTransactions();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${result['message']}\nتم المزامنة: ${result['synced']}, فشل: ${result['failed']}',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: result['success'] ? Colors.green : Colors.orange,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشلت المزامنة: $e',
              style: const TextStyle(fontFamily: 'Alexandria'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _syncing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final pendingCount = _localRepo.getPendingCount();

    if (pendingCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.orange[400]!, Colors.orange[600]!],
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sync_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'نقاط معلقة: $pendingCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Alexandria',
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'اضغط لمزامنة النقاط',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.9),
                    fontSize: 13,
                    fontFamily: 'Alexandria',
                  ),
                ),
              ],
            ),
          ),
          if (_syncing)
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
              ),
            )
          else
            IconButton(
              onPressed: _syncNow,
              icon: const Icon(
                Icons.sync_rounded,
                color: Colors.white,
              ),
              tooltip: 'مزامنة الآن',
            ),
        ],
      ),
    );
  }
}

/// Show points sync status dialog
Future<void> showPointsSyncDialog(BuildContext context) async {
  final syncService = PointsSyncService();

  // Get sync status
  final status = await syncService.getSyncStatus();
  final pendingCount = status['pendingCount'] as int;
  final isOnline = status['isOnline'] as bool;
  final stats = status['statistics'] as Map<String, dynamic>;

  if (!context.mounted) return;

  showDialog(
    context: context,
    builder: (ctx) => Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [teal700, teal500],
          ),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    isOnline ? Icons.cloud_done : Icons.cloud_off,
                    color: Colors.white,
                    size: 32,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'حالة المزامنة',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          fontFamily: 'Alexandria',
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isOnline ? 'متصل بالإنترنت' : 'غير متصل',
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.9),
                          fontFamily: 'Alexandria',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Stats
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  _buildStatRow('النقاط المعلقة', '$pendingCount', Icons.pending_actions),
                  if (stats['totalPoints'] != null) ...[
                    const Divider(),
                    _buildStatRow('مجموع النقاط', '${stats['totalPoints']}', Icons.stars),
                  ],
                  if (stats['additionCount'] != null) ...[
                    const Divider(),
                    _buildStatRow('إضافات', '${stats['additionCount']}', Icons.add_circle),
                  ],
                  if (stats['deductionCount'] != null) ...[
                    const Divider(),
                    _buildStatRow('خصومات', '${stats['deductionCount']}', Icons.remove_circle),
                  ],
                  if (stats['failedCount'] != null && stats['failedCount'] > 0) ...[
                    const Divider(),
                    _buildStatRow('فشل', '${stats['failedCount']}', Icons.error, Colors.red),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Actions
            Row(
              children: [
                Expanded(
                  child: TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      'إغلاق',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Alexandria',
                      ),
                    ),
                  ),
                ),
                if (pendingCount > 0 && isOnline) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () async {
                        Navigator.of(ctx).pop();
                        final result = await syncService.syncPendingTransactions();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                '${result['message']}\nتم: ${result['synced']}, فشل: ${result['failed']}',
                                style: const TextStyle(fontFamily: 'Alexandria'),
                              ),
                              backgroundColor: result['success'] ? Colors.green : Colors.orange,
                            ),
                          );
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: teal700,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.sync_rounded, size: 18),
                          SizedBox(width: 8),
                          Text(
                            'مزامنة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontFamily: 'Alexandria',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _buildStatRow(String label, String value, IconData icon, [Color? color]) {
  return Row(
    children: [
      Icon(icon, color: color ?? teal700, size: 20),
      const SizedBox(width: 12),
      Expanded(
        child: Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            fontFamily: 'Alexandria',
          ),
        ),
      ),
      Text(
        value,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: color ?? Colors.black87,
          fontFamily: 'Alexandria',
        ),
      ),
    ],
  );
}

