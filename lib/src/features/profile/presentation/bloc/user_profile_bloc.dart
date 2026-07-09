import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';

abstract class UserProfileEvent extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserProfileLoadRequested extends UserProfileEvent {}

abstract class UserProfileState extends Equatable {
  @override
  List<Object?> get props => [];
}

class UserProfileInitial extends UserProfileState {}
class UserProfileLoading extends UserProfileState {}
class UserProfileLoaded extends UserProfileState {}

class UserProfileBloc extends Bloc<UserProfileEvent, UserProfileState> {
  final Stream<bool> _authStatusStream;
  late final StreamSubscription<bool> _authSubscription;

  UserProfileBloc(this._authStatusStream) : super(UserProfileInitial()) {
    _authSubscription = _authStatusStream.listen((isAuthenticated) {
      if (isAuthenticated) {
        add(UserProfileLoadRequested());
      }
    });
  }

  @override
  Future<void> close() {
    _authSubscription.cancel();
    return super.close();
  }
}