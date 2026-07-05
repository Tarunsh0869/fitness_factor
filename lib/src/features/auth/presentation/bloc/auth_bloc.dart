import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final GetUserUseCase _getUserUseCase;
  StreamSubscription? _userSubscription;

  AuthBloc({required GetUserUseCase getUserUseCase})
      : _getUserUseCase = getUserUseCase,
        super(AuthInitial()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);

    _userSubscription = _getUserUseCase.watchUser().listen(
          (user) => add(AuthStatusChanged(user)),
        );
  }

  void _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) {
    if (event.user != null) {
      emit(AuthAuthenticated(event.user!));
    } else {
      emit(AuthUnauthenticated());
    }
  }

  @override
  Future<void> close() {
    _userSubscription?.cancel();
    return super.close();
  }
}