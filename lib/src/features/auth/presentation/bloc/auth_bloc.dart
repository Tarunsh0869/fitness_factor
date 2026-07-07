import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:my_app/src/features/auth/domain/repository/auth_repository.dart';
import 'package:my_app/src/features/auth/presentation/bloc/auth_event.dart';
import 'package:my_app/src/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({required AuthRepository authRepository}) 
      : _authRepository = authRepository,
        super(const AuthState.unknown()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);
    _authStatusSubscription = _authRepository.status.listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  final AuthRepository _authRepository;
  late StreamSubscription<AuthStatus> _authStatusSubscription;

  void _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) {
    switch (event.status) {
      case AuthStatus.unauthenticated:
        return emit(const AuthState.unauthenticated());
      case AuthStatus.authenticated:
        return emit(const AuthState.authenticated());
      case AuthStatus.unknown:
        return emit(const AuthState.unknown());
    }
  }

  @override
  Future<void> close() {
    _authStatusSubscription.cancel();
    return super.close();
  }
}