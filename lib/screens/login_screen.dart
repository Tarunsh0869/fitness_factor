// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_prefs.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import 'admin_login_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  static const _blue   = Color(0xFF00E5FF);
  static const _blueDk = Color(0xFF7C3DFF);
  static const _bg     = Color(0xFF05070D);
  static const _card   = Color(0xFF101827);
  static const _ink    = Color(0xFFF8FAFC);
  static const _muted  = Color(0xFF94A3B8);
  static const _red    = Color(0xFFFF2D75);

  final _phoneCtrl = TextEditingController();
  bool _loading = false;
  String? _error;

  Future<void> _login() async {
    final phone = _phoneCtrl.text.trim();
    if (phone.isEmpty) return;
    setState(() { _loading = true; _error = null; });
    final result = await AttendanceService.login(phone);
    if (!mounted) return;
    setState(() => _loading = false);
    if (result != null && result.containsKey('error')) {
      setState(() => _error = result['error'] as String);
    } else if (result != null) {
      FirebaseService.setMemberId(result['memberId']);
      await AuthPrefs.save(
        memberId:   result['memberId'],
        memberName: result['name'],
        gymId:      result['gymId'],
        jwtToken:   result['jwtToken'] as String?,
        apiMemberId: result['apiMemberId'] as int?,
        apiGymId:   result['apiGymId'] as int?,
        jwtExpiresAt: result['jwtExpiresAt'] as DateTime?,
      );
      if (!mounted) return;
      Navigator.pushReplacement(context, MaterialPageRoute(
        builder: (_) => HomeScreen(
          memberId:   result['memberId'],
          memberName: result['name'],
          gymId:      result['gymId'],
        ),
      ));
    } else {
      setState(() => _error = 'Phone number not found. Contact your gym.');
    }
  }

  @override
  void dispose() { _phoneCtrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // Decorative blobs
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 240, height: 240,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withOpacity(0.10),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: -80,
            child: Container(
              width: 200, height: 200,
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
                  // Logo
                  GestureDetector(
                    onLongPress: () => Navigator.push(context,
                        MaterialPageRoute(builder: (_) => const AdminLoginScreen())),
                    child: Container(
                      width: 64, height: 64,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_blue, _blueDk],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.3),
                            blurRadius: 20, offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.fitness_center, color: Colors.white, size: 30),
                    ),
                  ),
                  const SizedBox(height: 28),
                  const Text(
                    'Fitness Factor',
                    style: TextStyle(
                      color: _ink, fontSize: 34,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 6),
                  RichText(
                    text: TextSpan(
                      style: const TextStyle(fontSize: 15, height: 1.6),
                      children: [
                        TextSpan(text: 'Auto ', style: TextStyle(color: _muted)),
                        const TextSpan(text: 'geo-attendance',
                            style: TextStyle(color: _blue, fontWeight: FontWeight.w600)),
                        TextSpan(text: '.\nEnter your phone to get started.',
                            style: TextStyle(color: _muted)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 52),
                  Text('Phone Number',
                      style: TextStyle(color: _ink, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _phoneCtrl,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(color: _ink, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: '+60 12-345 6789',
                      hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
                      prefixIcon: const Icon(Icons.phone_outlined, color: _blue),
                      filled: true,
                      fillColor: _card,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: const Color(0xFF243244)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(color: const Color(0xFF243244)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: const BorderSide(color: _blue, width: 1.5),
                      ),
                      errorText: _error,
                      errorStyle: const TextStyle(color: _red),
                    ),
                    onSubmitted: (_) => _login(),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity, height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [_blue, _blueDk],
                        ),
                        borderRadius: BorderRadius.circular(14),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.35),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: ElevatedButton(
                        onPressed: _loading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        child: _loading
                            ? const SizedBox(width: 22, height: 22,
                                child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5))
                            : const Text('Continue',
                                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('New member? ', style: TextStyle(color: _muted, fontSize: 14)),
                      GestureDetector(
                        onTap: () => Navigator.push(context,
                            MaterialPageRoute(builder: (_) => const RegisterScreen())),
                        child: const Text('Register here',
                            style: TextStyle(
                              color: _blue, fontSize: 14, fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
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
}
