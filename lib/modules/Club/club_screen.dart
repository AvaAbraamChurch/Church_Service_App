import 'package:church/core/styles/themeScaffold.dart';
import 'package:church/core/utils/userType_enum.dart';
import 'package:church/modules/Club/servant_club_view.dart';
import 'package:church/modules/Club/child_club_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../core/blocs/club/club_cubit.dart';
import '../../core/models/user/user_model.dart';
import '../../core/repositories/club_repository.dart';


class ClubScreen extends StatefulWidget {
  final UserModel user;
  const ClubScreen({super.key, required this.user});

  @override
  State<ClubScreen> createState() => _ClubScreenState();
}

class _ClubScreenState extends State<ClubScreen> {
  @override
  Widget build(BuildContext context) {
    final isChild = widget.user.userType == UserType.child;

    return BlocProvider(
      create: (_) => ClubCubit(
        repository: ClubRepository(),
        userId: widget.user.id,
        userGender: widget.user.gender,
        initialCoins: widget.user.clubCoins,
        initialCardStatus: widget.user.cardStatus,
        isChild: isChild,
      )..init(),
      child: Builder(
        builder: (context) {
          final cubit = context.read<ClubCubit>();
          return StreamBuilder<ClubState>(
            stream: cubit.stream,
            initialData: cubit.state,
            builder: (context, snapshot) {
              return ThemedScaffold(
                appBar: AppBar(
                  title: const Text('نادي صيف 2026'),
                  centerTitle: true,
                ),
                body: switch (widget.user.userType) {
                  UserType.child => ChildClubView(user: widget.user),
                  UserType.servant => ServantClubView(user: widget.user),
                  UserType.superServant => ServantClubView(user: widget.user),
                  UserType.priest => ServantClubView(user: widget.user),
                },
              );
            },
          );
        },
      ),
    );
  }
}
