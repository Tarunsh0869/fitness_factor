// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../blocs/auth/auth_bloc.dart';
import '../services/attendance_service.dart';
import '../widgets/fitness_factor_logo.dart';
import 'complete_profile_screen.dart';
import 'home_screen.dart';
import 'pending_verification_screen.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';
import 'onboarding/guest_onboarding_flow_screen.dart';

// Needed by AuthBloc to call signInWithGoogle — keep AttendanceService import.
export '../services/attendance_service.dart' show AttendanceService;

class LoginScreen extends StatelessWidget {
  final bool launchedFromGuest;

  const LoginScreen({super.key, this.launchedFromGuest = false});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => AuthBloc(),
      child: _LoginView(launchedFromGuest: launchedFromGuest),
    );
  }
}

class _LoginView extends StatefulWidget {
  final bool launchedFromGuest;
  const _LoginView({required this.launchedFromGuest});

  @override
  State<_LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<_LoginView> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _red = Color(0xFFB3261E);
  static const _outline = Color(0xFFC3C8C6);

  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _handleSuccess(BuildContext context, Map<String, dynamic> result) {
    final memberName = ((result['name'] as String?) ?? '').trim().isEmpty
        ? 'Member'
        : result['name'] as String;
    final gymId = (result['gymId'] as String?) ?? '';
    final verificationStatus =
        result['verificationStatus'] as String? ?? 'pending';

    if (verificationStatus == 'pending' || verificationStatus == 'rejected') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => PendingVerificationScreen(
            memberName: memberName,
            verificationStatus: verificationStatus,
          ),
        ),
      );
      return;
    }

    if (result['profileCompleted'] != true) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => CompleteProfileScreen(
            memberId: result['memberId'] as String,
            memberName: memberName,
            gymId: gymId,
          ),
        ),
      );
      return;
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          memberId: result['memberId'] as String,
          memberName: memberName,
          gymId: gymId,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthSuccess) {
          _handleSuccess(context, state.result);
        } else if (state is AuthNeedsRegistration) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => RegisterScreen(
                initialEmail: state.email,
                initialName: state.name,
                useCurrentFirebaseUser: true,
              ),
            ),
          );
        }
      },
      child: BlocBuilder<AuthBloc, AuthState>(
        builder: (context, state) {
          final bloc = context.read<AuthBloc>();
          return Scaffold(
            backgroundColor: _bg,
            resizeToAvoidBottomInset: true,
            body: Stack(
              children: [
                Positioned(
                  top: -60,
                  right: -60,
                  child: Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _blue.withOpacity(0.10),
                    ),
                  ),
                ),
                Positioned(
                  bottom: 40,
                  left: -80,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _blue.withOpacity(0.06),
                    ),
                  ),
                ),
                SafeArea(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 28),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 64),
                        Center(
                          child: Column(
                            children: [
                              const FitnessFactorLogo(size: 132),
                              const SizedBox(height: 20),
                              GestureDetector(
                                onLongPress: () => Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => const AdminLoginScreen(),
                                  ),
                                ),
                                child: const SizedBox(
                                  width: double.infinity,
                                  child: Text(
                                    'Fitness Factor',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(
                                      color: _ink,
                                      fontSize: 40,
                                      fontWeight: FontWeight.w900,
                                      height: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                widget.launchedFromGuest
                                    ? 'Sign in to keep your guest-mode workouts, gym time, attendance, and progress safe in your member profile.'
                                    : 'Welcome back. Use email/password or Google to continue.',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 44),
                        _label('Email Address'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _emailCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(color: _ink, fontSize: 16),
                          decoration: _inputDecoration(
                            hint: 'member@example.com',
                            icon: Icons.email_outlined,
                          ),
                        ),
                        const SizedBox(height: 14),
                        _label('Password'),
                        const SizedBox(height: 8),
                        TextField(
                          controller: _passwordCtrl,
                          obscureText: state.passwordObscured,
                          style: const TextStyle(color: _ink, fontSize: 16),
                          decoration: _inputDecoration(
                            hint: 'Enter password',
                            icon: Icons.lock_outline,
                            suffix: IconButton(
                              icon: Icon(
                                state.passwordObscured
                                    ? Icons.visibility_outlined
                                    : Icons.visibility_off_outlined,
                                color: _muted,
                              ),
                              onPressed: () =>
                                  bloc.add(AuthTogglePasswordVisibility()),
                            ),
                          ),
                          onSubmitted: (_) => bloc.add(
                            AuthLoginWithEmail(
                              _emailCtrl.text.trim(),
                              _passwordCtrl.text,
                            ),
                          ),
                        ),
                        if (state.error != null) ...[
                          const SizedBox(height: 10),
                          Text(
                            state.error!,
                            style: const TextStyle(color: _red, fontSize: 13),
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [_blue, _blueDk],
                              ),
                              borderRadius: BorderRadius.circular(28),
                              boxShadow: [
                                BoxShadow(
                                  color: _blue.withOpacity(0.35),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                            ),
                            child: ElevatedButton(
                              onPressed: state.loading
                                  ? null
                                  : () => bloc.add(
                                        AuthLoginWithEmail(
                                          _emailCtrl.text.trim(),
                                          _passwordCtrl.text,
                                        ),
                                      ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(28),
                                ),
                              ),
                              child: state.loading
                                  ? const SizedBox(
                                      width: 22,
                                      height: 22,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2.5,
                                      ),
                                    )
                                  : const Text(
                                      'Sign In',
                                      style: TextStyle(
                                        fontWeight: FontWeight.w700,
                                        fontSize: 16,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: state.googleLoading
                                ? null
                                : () => bloc.add(AuthLoginWithGoogle()),
                            icon: state.googleLoading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Icon(Icons.g_mobiledata, size: 30),
                            label: Text(
                              state.googleLoading
                                  ? 'Opening Google...'
                                  : 'Continue with Google',
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: _ink,
                              side: const BorderSide(color: _outline),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(28),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text(
                              'New member? ',
                              style: TextStyle(color: _muted, fontSize: 14),
                            ),
                            GestureDetector(
                              onTap: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => const RegisterScreen(),
                                ),
                              ),
                              child: const Text(
                                'Register here',
                                style: TextStyle(
                                  color: _blue,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        if (!widget.launchedFromGuest)
                          Center(
                            child: TextButton(
                              onPressed: () => Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const GuestOnboardingFlowScreen(),
                                ),
                              ),
                              child: const Text(
                                'Try as Guest',
                                style: TextStyle(
                                  color: _blue,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ),
                        const SizedBox(height: 32),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _label(String label) => Text(
    label,
    style: const TextStyle(
      color: _ink,
      fontSize: 13,
      fontWeight: FontWeight.w600,
    ),
  );

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
      prefixIcon: Icon(icon, color: _blue),
      suffixIcon: suffix,
      filled: true,
      fillColor: _card,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(28),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }
}
