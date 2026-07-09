import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../domain/repositories/profile_repository.dart';

part 'profile_event.dart';
part 'profile_state.dart';

class ProfileBloc extends Bloc<ProfileEvent, ProfileState> {
  final ProfileRepository _repository;
  StreamSubscription? _profileSubscription;

  ProfileBloc(this._repository) : super(ProfileInitial()) {
    on<WatchProfileRequested>(_onWatchProfileRequested);
    on<ProfileUpdated>(_onProfileUpdated);
  }

  Future<void> _onWatchProfileRequested(
    WatchProfileRequested event,
    Emitter<ProfileState> emit,
  ) async {
    emit(ProfileLoading());
    await _profileSubscription?.cancel();
    _profileSubscription = _repository.watchProfile().listen(
      (profile) => add(ProfileUpdated(profile)),
    );
  }

  void _onProfileUpdated(
    ProfileUpdated event,
    Emitter<ProfileState> emit,
  ) {
    emit(ProfileLoaded(event.profile));
  }

  @override
  Future<void> close() {
    _profileSubscription?.cancel();
    return super.close();
  }
}