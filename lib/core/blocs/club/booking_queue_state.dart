part of 'booking_queue_cubit.dart';

abstract class BookingQueueState {
  const BookingQueueState();
}

class BookingQueueInitial extends BookingQueueState {}

class BookingQueueLoading extends BookingQueueState {}

class BookingQueueLoaded extends BookingQueueState {
  final List<BookingQueueEntry> bookingQueue;
  final List<PlayedQueueEntry> playedQueue;
  final GameModel game;
  final String viewDate;
  final bool isHistoryMode;

  const BookingQueueLoaded({
    required this.bookingQueue,
    required this.playedQueue,
    required this.game,
    required this.viewDate,
    required this.isHistoryMode,
  });
}

class BookingQueueError extends BookingQueueState {
  final String message;
  const BookingQueueError(this.message);
}

class BookingQueueSuccess extends BookingQueueState {
  final String message;
  const BookingQueueSuccess(this.message);
}
