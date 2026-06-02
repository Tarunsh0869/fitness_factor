import 'package:flutter_bloc/flutter_bloc.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class OnboardingEvent {}

class OnboardingPageChanged extends OnboardingEvent {
  final int index;
  OnboardingPageChanged(this.index);
}

class OnboardingNavigateToGuest extends OnboardingEvent {}

class OnboardingNavigateToSignIn extends OnboardingEvent {}

// ── State ─────────────────────────────────────────────────────────────────────
class OnboardingState {
  final int index;
  final bool navigating;

  const OnboardingState({this.index = 0, this.navigating = false});

  OnboardingState copyWith({int? index, bool? navigating}) => OnboardingState(
    index: index ?? this.index,
    navigating: navigating ?? this.navigating,
  );
}

// ── Sealed navigation side-effects (emitted once via BlocListener) ────────────
sealed class OnboardingNavigated extends OnboardingState {
  const OnboardingNavigated() : super(index: 0, navigating: false);
}

class OnboardingGoToGuest extends OnboardingNavigated {
  const OnboardingGoToGuest();
}

class OnboardingGoToSignIn extends OnboardingNavigated {
  const OnboardingGoToSignIn();
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

/// Manages the slide index and navigation triggers for OnboardingFlowScreen.
/// Navigation side-effects are emitted as one-shot subclasses of
/// [OnboardingNavigated] and handled in a [BlocListener].
class OnboardingBloc extends Bloc<OnboardingEvent, OnboardingState> {
  final Future<void> Function()? onComplete;

  OnboardingBloc({this.onComplete}) : super(const OnboardingState()) {
    on<OnboardingPageChanged>((e, emit) => emit(state.copyWith(index: e.index)));

    on<OnboardingNavigateToGuest>((e, emit) async {
      emit(state.copyWith(navigating: true));
      await onComplete?.call();
      emit(const OnboardingGoToGuest());
    });

    on<OnboardingNavigateToSignIn>((e, emit) async {
      emit(state.copyWith(navigating: true));
      await onComplete?.call();
      emit(const OnboardingGoToSignIn());
    });
  }
}
