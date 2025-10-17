import 'package:church/core/models/user/user_model.dart';
import 'package:church/core/repositories/users_reopsitory.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'home_states.dart';

class HomeCubit extends Cubit<HomeState> {
  final UsersRepository _usersRepository;

  HomeCubit({UsersRepository? usersRepository})
      : _usersRepository = usersRepository ?? UsersRepository(),
        super(HomeInitialState());

  static HomeCubit get(context) => BlocProvider.of(context);

  UserModel ? currentUser;

  // Fetch user data
  Future<UserModel?> getUserById(String userId) async {
    try {
      emit(getUserLoadingState());
      final userData = await _usersRepository.getUserById(userId);
      if (userData != null) {
        currentUser = userData;
        emit(getUserSuccessState());
        return currentUser;
      } else {
        emit(getUserErrorState('User not found'));
        return null;
      }
    } catch (e) {
      emit(getUserErrorState(e.toString()));
      print(e.toString());
      return null;
    }
  }

}