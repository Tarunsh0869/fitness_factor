import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/attendance_service.dart';
import '../../services/auth_prefs.dart';
import '../../services/firebase_service.dart';
import '../../services/guest_session_service.dart';

// ── Events ────────────────────────────────────────────────────────────────────
sealed class AuthEvent {}

class AuthLoginWithEmail extends AuthEvent {
  final String email;
  final String password;
  AuthLoginWithEmail(this.email, this.password);
}

class AuthLoginWithGoogle extends AuthEvent {}

class AuthTogglePasswordVisibility extends AuthEvent {}

// ── State ─────────────────────────────────────────────────────────────────────
class AuthState {
  final bool loading;
  final bool googleLoading;
  final bool passwordObscured;
  final String? error;

  const AuthState({
    this.loading = false,
    this.googleLoading = false,
    this.passwordObscured = true,
    this.error,
  });

  AuthState copyWith({
    bool? loading,
    bool? googleLoading,
    bool? passwordObscured,
    String? error,
    bool clearError = false,
  }) => AuthState(
    loading: loading ?? this.loading,
    googleLoading: googleLoading ?? this.googleLoading,
    passwordObscured: passwordObscured ?? this.passwordObscured,
    error: clearError ? null : (error ?? this.error),
  );
}

/// Emitted once when login succeeds — handled by BlocListener.
class AuthSuccess extends AuthState {
  final Map<String, dynamic> result;
  const AuthSuccess(this.result)
    : super(loading: false, googleLoading: false, passwordObscured: true);
}

/// Emitted once when Google sign-in needs new registration.
class AuthNeedsRegistration extends AuthState {
  final String email;
  final String name;
  const AuthNeedsRegistration({required this.email, required this.name})
    : super(loading: false, googleLoading: false, passwordObscured: true);
}

// ── Bloc ──────────────────────────────────────────────────────────────────────

/// Manages email/Google login flow for LoginScreen.
/// [AuthSuccess] and [AuthNeedsRegistration] are one-shot navigation states
/// handled in a [BlocListener].
class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc() : super(const AuthState()) {
    on<AuthTogglePasswordVisibility>(
      (e, emit) =>
          emit(state.copyWith(passwordObscured: !state.passwordObscured)),
    );

    on<AuthLoginWithEmail>(_onEmailLogin);
    on<AuthLoginWithGoogle>(_onGoogleLogin);
  }

  Future<void> _onEmailLogin(
    AuthLoginWithEmail e,
    Emitter<AuthState> emit,
  ) async {
    if (e.email.isEmpty || e.password.isEmpty) {
      emit(state.copyWith(error: 'Enter email and password.'));
      return;
    }
    emit(state.copyWith(loading: true, clearError: true));
    final result = await AttendanceService.loginWithEmail(
      email: e.email,
      password: e.password,
    );
    if (result != null && result.containsKey('error')) {
      emit(state.copyWith(loading: false, error: result['error'] as String));
      return;
    }
    if (result == null) {
      emit(
        state.copyWith(loading: false, error: 'Login failed. Please try again.'),
      );
      return;
    }
    emit(state.copyWith(loading: false, clearError: true));
    await _persistSession(result);
    emit(AuthSuccess(result));
  }

  Future<void> _onGoogleLogin(
    AuthLoginWithGoogle e,
    Emitter<AuthState> emit,
  ) async {
    emit(state.copyWith(googleLoading: true, clearError: true));
    final result = await AttendanceService.signInWithGoogle();
    emit(state.copyWith(googleLoading: false));

    if (result?['needsRegistration'] == true) {
      emit(AuthNeedsRegistration(
        email: result?['email'] as String? ?? '',
        name: result?['name'] as String? ?? '',
      ));
      return;
    }
    if (result != null && result.containsKey('error')) {
      emit(state.copyWith(error: result['error'] as String));
      return;
    }
    if (result == null) {
      emit(state.copyWith(error: 'Login failed. Please try again.'));
      return;
    }
    await _persistSession(result);
    emit(AuthSuccess(result));
  }

  Future<void> _persistSession(Map<String, dynamic> result) async {
    FirebaseService.setMemberId(result['memberId']);
    final guest = await GuestSessionService.load();
    await AttendanceService.mergeGuestSessionData(
      memberId: result['memberId'] as String,
      starterWorkoutsCompleted: guest['starterWorkoutsCompleted'] as int,
      meaningfulActionCount: guest['meaningfulActionCount'] as int,
      lastAction: guest['lastAction'] as String,
      gymTimeMinutes: guest['gymTimeMinutes'] as int,
    );
    await GuestSessionService.clear();
    final memberName = ((result['name'] as String?) ?? '').trim().isEmpty
        ? 'Member'
        : result['name'] as String;
    await AuthPrefs.save(
      memberId: result['memberId'],
      memberName: memberName,
      gymId: (result['gymId'] as String?) ?? '',
    );
  }
}
