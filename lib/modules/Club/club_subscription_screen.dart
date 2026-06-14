import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/club_subscription_info_model.dart';
import '../../core/models/club/club_subscription_request_model.dart';
import '../../core/models/user/user_model.dart';

class ClubSubscriptionScreen extends StatelessWidget {
  final UserModel user;

  const ClubSubscriptionScreen({super.key, required this.user});

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClubCubit>();
    final colorScheme = Theme.of(context).colorScheme;

    return ThemedScaffold(
      appBar: AppBar(
        title: const Text('اشتراك النادي'),
      ),
      body: StreamBuilder<ClubSubscriptionInfo?>(
        stream: cubit.clubSubscriptionInfoStream(),
        builder: (context, infoSnapshot) {
          final info = infoSnapshot.data;
          return StreamBuilder<ClubSubscriptionRequest?>(
            stream: cubit.mySubscriptionRequestStream(),
            builder: (context, requestSnapshot) {
              final request = requestSnapshot.data;
              final isPending = request?.status == SubscriptionRequestStatus.pending;
              final isApproved = request?.status == SubscriptionRequestStatus.approved;
              final statusText = request?.status.labelAr ?? 'لم يتم إرسال طلب بعد';
              final statusColor = isApproved
                  ? colorScheme.tertiary
                  : (isPending ? colorScheme.primary : colorScheme.outline);

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _InfoCard(info: info),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'حالة الطلب',
                          style: Theme.of(context)
                              .textTheme
                              .titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: statusColor, size: 20),
                            const SizedBox(width: 8),
                            Text(
                              statusText,
                              style: TextStyle(color: statusColor, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                        if (request?.requestedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'تاريخ الطلب: ${DateFormat('dd/MM/yyyy').format(request!.requestedAt!)}',
                            style: TextStyle(color: colorScheme.onSurface.withAlpha(153)),
                          ),
                        ],
                        if (request?.approvedAt != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'تاريخ الموافقة: ${DateFormat('dd/MM/yyyy').format(request!.approvedAt!)}',
                            style: TextStyle(color: colorScheme.onSurface.withAlpha(153)),
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: (request == null)
                          ? () async {
                              final created = await cubit.submitClubSubscriptionRequest(
                                child: user,
                              );
                              if (!context.mounted) return;
                              if (!created) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: const Text('تم إرسال طلب الاشتراك'),
                                  backgroundColor: Colors.green.shade700,
                                  behavior: SnackBarBehavior.floating,
                                ),
                              );
                            }
                          : null,
                      icon: const Icon(Icons.how_to_reg_rounded),
                      label: Text(
                        style: TextStyle(color: Colors.white),
                        request == null
                            ? 'احجز اشتراك النادي'
                            : (isApproved ? 'تمت الموافقة' : 'طلبك قيد المراجعة'),
                      ),
                    ),
                  ),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final ClubSubscriptionInfo? info;

  const _InfoCard({this.info});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final title = info?.title.isNotEmpty == true ? info!.title : 'معلومات الاشتراك';
    final description = info?.description.isNotEmpty == true
        ? info!.description
        : 'سيتم إضافة تفاصيل الاشتراك قريباً.';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            colorScheme.primary.withAlpha(26),
            colorScheme.secondary.withAlpha(26),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorScheme.outlineVariant.withAlpha(128)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            description,
            style: TextStyle(
                color: Colors.white60,
              fontSize: 16
            )
          ),
        ],
      ),
    );
  }
}

