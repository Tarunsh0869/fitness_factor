import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/entities/auth_status.dart';
import '../../domain/usecases/watch_auth_status.dart';

part 'auth_event.dart';
part 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final WatchAuthStatus _watchAuthStatus;
  StreamSubscription<AuthStatus>? _authSubscription;

  AuthBloc({required WatchAuthStatus watchAuthStatus})
      : _watchAuthStatus = watchAuthStatus,
        super(const AuthState.unknown()) {
    on<AuthStatusChanged>(_onAuthStatusChanged);

    _authSubscription = _watchAuthStatus().listen(
      (status) => add(AuthStatusChanged(status)),
    );
  }

  Future<void> _onAuthStatusChanged(
    AuthStatusChanged event,
    Emitter<AuthState> emit,
  ) async {
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
    _authSubscription?.cancel();
    return super.close();
  }
}