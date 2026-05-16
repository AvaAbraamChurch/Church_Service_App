import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../core/models/club/coin_transaction_model.dart';
import '../../core/styles/colors.dart';

class CoinHistoryScreen extends StatelessWidget {
  final List<CoinTransaction> transactions;
  final String userName;

  const CoinHistoryScreen({
    super.key,
    required this.transactions,
    required this.userName,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('سجل العملات'),
        centerTitle: true,
      ),
      body: transactions.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.receipt_long_outlined,
                      size: 64,
                      color: colorScheme.onSurface.withValues(alpha: 0.3)),
                  const SizedBox(height: 16),
                  Text('لا يوجد سجل بعد',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: colorScheme.onSurface.withValues(alpha: 0.5),
                      )),
                ],
              ),
            )
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
              itemCount: transactions.length,
              itemBuilder: (context, index) {
                final tx = transactions[index];
                final isAdded = tx.type == TransactionType.added;
                final isFirst = index == 0;
                final isLast = index == transactions.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Timeline line + dot
                      SizedBox(
                        width: 40,
                        child: Column(
                          children: [
                            // Top line
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: isFirst
                                      ? Colors.transparent
                                      : colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                            // Dot
                            Container(
                              width: 16,
                              height: 16,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: isAdded
                                    ? Colors.green.shade400
                                    : Colors.red.shade400,
                                boxShadow: [
                                  BoxShadow(
                                    color: (isAdded
                                            ? Colors.green
                                            : Colors.red)
                                        .withValues(alpha: 0.4),
                                    blurRadius: 6,
                                    spreadRadius: 1,
                                  ),
                                ],
                              ),
                            ),
                            // Bottom line
                            Expanded(
                              child: Center(
                                child: Container(
                                  width: 2,
                                  color: isLast
                                      ? Colors.transparent
                                      : colorScheme.outlineVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      // Card
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: colorScheme.outlineVariant
                                    .withValues(alpha: 0.5),
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.04),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            padding: const EdgeInsets.all(14),
                            child: Row(
                              children: [
                                // Icon
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    color: isAdded
                                        ? Colors.green.withValues(alpha: 0.12)
                                        : Colors.red.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    isAdded
                                        ? Icons.add_circle_outline
                                        : Icons.remove_circle_outline,
                                    color: isAdded
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                    size: 22,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                // Text
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        tx.reason,
                                        style: TextStyle(
                                          color: teal900,
                                          fontSize: 14,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Text(
                                        DateFormat('d MMM y • hh:mm a', 'ar')
                                            .format(tx.timestamp),
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          color: colorScheme.onSurface
                                              .withValues(alpha: 0.5),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Amount
                                Text(
                                  '${isAdded ? '+' : '-'}${tx.amount} 🪙',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: isAdded
                                        ? Colors.green.shade600
                                        : Colors.red.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
    );
  }
}
