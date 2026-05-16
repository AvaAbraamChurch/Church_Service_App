part of 'club_cubit.dart';

abstract class ClubState {}

class ClubInitial extends ClubState {}

class ClubLoading extends ClubState {}

class ClubError extends ClubState {
  final String message;
  ClubError(this.message);
}

// Child states
class ClubChildLoaded extends ClubState {
  final List<GameModel> games;
  final List<CoinTransaction> transactions;
  final int clubCoins;
  final String cardStatus;

  ClubChildLoaded({
    required this.games,
    required this.transactions,
    required this.clubCoins,
    required this.cardStatus,
  });
}

// Servant / Super Servant / Priest states
class ClubServantLoaded extends ClubState {
  final List<GameModel> games;
  final List<AttendanceService> attendanceServices;

  ClubServantLoaded({
    required this.games,
    required this.attendanceServices,
  });
}

class ClubActionSuccess extends ClubState {
  final String message;
  ClubActionSuccess(this.message);
}
