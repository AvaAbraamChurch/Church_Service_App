import 'package:church/core/styles/colors.dart';
import 'package:church/core/styles/themeScaffold.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/club/club_subscription_info_model.dart';
import '../../core/models/club/club_subscription_request_model.dart';

class ClubSubscriptionAdminScreen extends StatefulWidget {
  const ClubSubscriptionAdminScreen({super.key});

  @override
  State<ClubSubscriptionAdminScreen> createState() => _ClubSubscriptionAdminScreenState();
}

class _ClubSubscriptionAdminScreenState extends State<ClubSubscriptionAdminScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  SubscriptionRequestStatus? _filter;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cubit = context.read<ClubCubit>();

    return DefaultTabController(
      length: 2,
      child: ThemedScaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          title: const Text('إدارة اشتراك النادي', style: TextStyle(color: Colors.white),),
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.info_outline), text: 'المعلومات'),
              Tab(icon: Icon(Icons.how_to_reg_outlined), text: 'الطلبات'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            _InfoTab(
              cubit: cubit,
              titleController: _titleController,
              descriptionController: _descriptionController,
            ),
            _RequestsTab(
              cubit: cubit,
              filter: _filter,
              onFilterChanged: (val) => setState(() => _filter = val),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoTab extends StatefulWidget {
  final ClubCubit cubit;
  final TextEditingController titleController;
  final TextEditingController descriptionController;

  const _InfoTab({
    required this.cubit,
    required this.titleController,
    required this.descriptionController,
  });

  @override
  State<_InfoTab> createState() => _InfoTabState();
}

class _InfoTabState extends State<_InfoTab> {
  bool _didLoadInfo = false;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<ClubSubscriptionInfo?>(
      stream: widget.cubit.clubSubscriptionInfoStream(),
      builder: (context, snapshot) {
        final info = snapshot.data;
        if (!_didLoadInfo && info != null) {
          widget.titleController.text = info.title;
          widget.descriptionController.text = info.description;
          _didLoadInfo = true;
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextField(
              controller: widget.titleController,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                labelText: 'عنوان الاشتراك',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: widget.descriptionController,
              style: const TextStyle(color: Colors.white),
              maxLines: 6,
              decoration: const InputDecoration(
                labelText: 'تفاصيل الاشتراك',
                border: OutlineInputBorder(),
                fillColor: Colors.white,
                alignLabelWithHint: true,
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  final title = widget.titleController.text.trim();
                  final description = widget.descriptionController.text.trim();
                  if (title.isEmpty || description.isEmpty) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text('اكتب العنوان والتفاصيل أولاً'),
                        backgroundColor: Colors.orange.shade700,
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                    return;
                  }
                  widget.cubit.updateClubSubscriptionInfo(
                    title: title,
                    description: description,
                  );
                },
                icon: const Icon(Icons.save_outlined),
                label: const Text('حفظ المعلومات'),
              ),
            ),
            if (info?.updatedAt != null) ...[
              const SizedBox(height: 12),
              Text(
                'آخر تحديث: ${DateFormat('dd/MM/yyyy - hh:mm a').format(info!.updatedAt!)}',
                style: TextStyle(color: Colors.white60),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _RequestsTab extends StatelessWidget {
  final ClubCubit cubit;
  final SubscriptionRequestStatus? filter;
  final ValueChanged<SubscriptionRequestStatus?> onFilterChanged;

  const _RequestsTab({
    required this.cubit,
    required this.filter,
    required this.onFilterChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Wrap(
            spacing: 8,
            children: [
              ChoiceChip(
                label: const Text('الكل'),
                selected: filter == null,
                onSelected: (_) => onFilterChanged(null),
              ),
              ChoiceChip(
                label: const Text('قيد المراجعة'),
                selected: filter == SubscriptionRequestStatus.pending,
                onSelected: (_) => onFilterChanged(SubscriptionRequestStatus.pending),
              ),
              ChoiceChip(
                label: const Text('تمت الموافقة'),
                selected: filter == SubscriptionRequestStatus.approved,
                onSelected: (_) => onFilterChanged(SubscriptionRequestStatus.approved),
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<ClubSubscriptionRequest>>(
            stream: cubit.subscriptionRequestsStream(status: filter),
            builder: (context, snapshot) {
              final requests = snapshot.data ?? [];
              if (requests.isEmpty) {
                return Center(
                  child: Text(
                    'لا توجد طلبات حالياً',
                    style: TextStyle(color: Colors.white60),
                  ),
                );
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: requests.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final request = requests[index];
                  final isPending = request.status == SubscriptionRequestStatus.pending;
                  return Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: colorScheme.surface,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: colorScheme.outlineVariant),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              backgroundColor: colorScheme.primary.withAlpha(26),
                              child: Icon(Icons.person_outline, color: colorScheme.primary),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    request.childName,
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: teal700),
                                  ),
                                  Text(
                                    'الفصل: ${request.childClass} • ${request.childShortId}',
                                    style: TextStyle(color: colorScheme.onSurface.withAlpha(153)),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: isPending
                                    ? colorScheme.primary.withAlpha(20)
                                    : colorScheme.tertiary.withAlpha(20),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                request.status.labelAr,
                                style: TextStyle(
                                  color: isPending ? colorScheme.primary : colorScheme.tertiary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        if (request.requestedAt != null) ...[
                          const SizedBox(height: 8),
                          Text(
                            'تاريخ الطلب: ${DateFormat('dd/MM/yyyy').format(request.requestedAt!)}',
                            style: TextStyle(color: colorScheme.onSurface.withAlpha(153)),
                          ),
                        ],
                        if (isPending) ...[
                          const SizedBox(height: 12),
                          SizedBox(
                            width: double.infinity,
                            child: FilledButton.icon(
                              onPressed: () => cubit.approveClubSubscriptionRequest(
                                request: request,
                              ),
                              icon: const Icon(Icons.check_circle_outline),
                              label: const Text('موافقة'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
