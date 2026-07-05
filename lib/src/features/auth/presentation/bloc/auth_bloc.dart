import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthLogoutRequested extends AuthEvent {}
class AuthUserUpdated extends AuthEvent {}

abstract class AuthState extends Equatable {
  @override
  List<Object?> get props => [];
}

class AuthInitial extends AuthState {}
class AuthAuthenticated extends AuthState {}
class AuthUnauthenticated extends AuthState {}

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(AuthInitial()) {
    on<AuthLogoutRequested>(_onLogoutRequested);
    on<AuthUserUpdated>(_onUserUpdated);
  }

  void _onLogoutRequested(AuthLogoutRequested event, Emitter<AuthState> emit) {
    emit(AuthUnauthenticated());
  }

  void _onUserUpdated(AuthUserUpdated event, Emitter<AuthState> emit) {
    if (state is AuthUnauthenticated) return;
    emit(AuthAuthenticated());
  }
}