abstract class HomeState {}

class HomeInitialState extends HomeState {}

class getUserLoadingState extends HomeState {}

class getUserSuccessState extends HomeState {}

class getUserErrorState extends HomeState {
  final String error;

  getUserErrorState(this.error);
}

