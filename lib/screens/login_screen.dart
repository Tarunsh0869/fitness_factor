// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_prefs.dart';
import '../services/guest_session_service.dart';
import '../widgets/fitness_factor_logo.dart';
import 'complete_profile_screen.dart';
import 'guest_experience_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  final bool launchedFromGuest;

  const LoginScreen({super.key, this.launchedFromGuest = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
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
  bool _loading = false;
  bool _googleLoading = false;
  bool _passwordObscured = true;
  String? _error;

  Future<void> _login() async {
    final email = _emailCtrl.text.trim();
    final password = _passwordCtrl.text;
    if (email.isEmpty || password.isEmpty) {
      setState(() => _error = 'Enter email and password.');
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await AttendanceService.loginWithEmail(
      email: email,
      password: password,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    await _handleAuthResult(result);
  }

  Future<void> _loginWithGoogle() async {
    setState(() {
      _googleLoading = true;
      _error = null;
    });
    final result = await AttendanceService.signInWithGoogle();
    if (!mounted) return;
    setState(() => _googleLoading = false);

    if (result?['needsRegistration'] == true) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => RegisterScreen(
            initialEmail: result?['email'] as String? ?? '',
            initialName: result?['name'] as String? ?? '',
            useCurrentFirebaseUser: true,
          ),
        ),
      );
      return;
    }

    await _handleAuthResult(result);
  }

  Future<void> _handleAuthResult(Map<String, dynamic>? result) async {
    if (!mounted) return;
    if (result != null && result.containsKey('error')) {
      setState(() => _error = result['error'] as String);
      return;
    }
    if (result == null) {
      setState(() => _error = 'Login failed. Please try again.');
      return;
    }

    FirebaseService.setMemberId(result['memberId']);
    await _mergeGuestData(result['memberId'] as String);
    final memberName = ((result['name'] as String?) ?? '').trim().isEmpty
        ? 'Member'
        : (result['name'] as String);
    final gymId = (result['gymId'] as String?) ?? '';
    await AuthPrefs.save(
      memberId: result['memberId'],
      memberName: memberName,
      gymId: gymId,
    );
    if (!mounted) return;
    final profileCompleted = result['profileCompleted'] == true;
    if (!profileCompleted) {
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
          memberId: result['memberId'],
          memberName: memberName,
          gymId: gymId,
        ),
      ),
    );
  }

  Future<void> _mergeGuestData(String memberId) async {
    final guest = await GuestSessionService.load();
    await AttendanceService.mergeGuestSessionData(
      memberId: memberId,
      starterWorkoutsCompleted: guest['starterWorkoutsCompleted'] as int,
      meaningfulActionCount: guest['meaningfulActionCount'] as int,
      lastAction: guest['lastAction'] as String,
    );
    await GuestSessionService.clear();
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
                              ? 'Sign in to save your guest progress and unlock personalization.'
                              : 'Welcome back. Use email/password or Google to continue.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
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
                    obscureText: _passwordObscured,
                    style: const TextStyle(color: _ink, fontSize: 16),
                    decoration: _inputDecoration(
                      hint: 'Enter password',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _passwordObscured
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: _muted,
                        ),
                        onPressed: () => setState(
                          () => _passwordObscured = !_passwordObscured,
                        ),
                      ),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      _error!,
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
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                        child: _loading
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
                      onPressed: _googleLoading ? null : _loginWithGoogle,
                      icon: _googleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 30),
                      label: Text(
                        _googleLoading
                            ? 'Opening Google...'
                            : 'Continue with Google',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: _ink,
                        side: const BorderSide(color: _outline),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(18),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
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
                            builder: (_) => const GuestExperienceScreen(),
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
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _outline),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(18),
        borderSide: const BorderSide(color: _blue, width: 1.5),
      ),
    );
  }
}
