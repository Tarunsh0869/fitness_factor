import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/guest_session_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class GuestOnboardingEvent {}

class GuestOnboardingNext extends GuestOnboardingEvent {}

class GuestOnboardingBack extends GuestOnboardingEvent {}

class GuestOnboardingSkipStep extends GuestOnboardingEvent {}

class GuestOnboardingComplete extends GuestOnboardingEvent {
  final bool skipped;
  GuestOnboardingComplete({required this.skipped});
}

// ── State ─────────────────────────────────────────────────────────────────────
class GuestOnboardingState {
  final int step;
  final bool navigating;

  static const totalSteps = 11;

  const GuestOnboardingState({this.step = 0, this.navigating = false});

  bool get isLastStep => step == totalSteps - 1;
  bool get isOptionalStep => step >= 7;

  GuestOnboardingState copyWith({int? step, bool? navigating}) =>
      GuestOnboardingState(
        step: step ?? this.step,
        navigating: navigating ?? this.navigating,
      );
}

class GuestOnboardingDone extends GuestOnboardingState {
  const GuestOnboardingDone() : super(step: 0, navigating: false);
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

/// Manages step progression and completion for GuestOnboardingFlowScreen.
/// [GuestOnboardingDone] is the one-shot navigation signal handled in a
/// [BlocListener].
class GuestOnboardingBloc
    extends Bloc<GuestOnboardingEvent, GuestOnboardingState> {
  GuestOnboardingBloc() : super(const GuestOnboardingState()) {
    on<GuestOnboardingNext>(_onNext);
    on<GuestOnboardingBack>(_onBack);
    on<GuestOnboardingSkipStep>(_onSkipStep);
    on<GuestOnboardingComplete>(_onComplete);
  }

  void _onNext(GuestOnboardingNext e, Emitter<GuestOnboardingState> emit) {
    if (state.navigating) return;
    if (state.isLastStep) {
      add(GuestOnboardingComplete(skipped: false));
      return;
    }
    emit(state.copyWith(step: state.step + 1));
  }

  void _onBack(GuestOnboardingBack e, Emitter<GuestOnboardingState> emit) {
    if (state.step == 0 || state.navigating) return;
    emit(state.copyWith(step: state.step - 1));
  }

  void _onSkipStep(
    GuestOnboardingSkipStep e,
    Emitter<GuestOnboardingState> emit,
  ) {
    if (!state.isOptionalStep || state.isLastStep || state.navigating) return;
    emit(state.copyWith(step: state.step + 1));
  }

  Future<void> _onComplete(
    GuestOnboardingComplete e,
    Emitter<GuestOnboardingState> emit,
  ) async {
    emit(state.copyWith(navigating: true));
    await GuestSessionService.recordMeaningfulAction(
      e.skipped ? 'guest_onboarding_skipped' : 'guest_onboarding_completed',
    );
    emit(const GuestOnboardingDone());
  }
}
