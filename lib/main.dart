import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'firebase_options.dart';
import 'services/admin_service.dart';
import 'services/attendance_service.dart';
import 'services/biometric_auth_service.dart';
import 'services/firebase_service.dart';
import 'services/auth_prefs.dart';
import 'theme/app_theme.dart';
import 'screens/complete_profile_screen.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_gym_registration_screen.dart';
import 'screens/onboarding/onboarding_flow_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);

  try {
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    FirebaseMessaging.onBackgroundMessage(_firebaseBackgroundHandler);
    await FirebaseService.init();
  } catch (e) {
    debugPrint('[Firebase] Init failed: $e');
  }

  runApp(const FitnessFactorApp());
}

class FitnessFactorApp extends StatelessWidget {
  const FitnessFactorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Fitness Factor',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.theme,
      home: const _StartupGate(),
    );
  }
}

class _StartupGate extends StatelessWidget {
  const _StartupGate();

  Future<bool> _shouldShowOnboarding() async {
    final savedSession = await AuthPrefs.load();
    return savedSession == null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _shouldShowOnboarding(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        if (snap.data == true) {
          return OnboardingFlowScreen(
            onComplete: AuthPrefs.markOnboardingCompleted,
            completeDestinationBuilder: (_) => const _AuthGate(),
          );
        }

        return const _AuthGate();
      },
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  Future<QuerySnapshot> _loadGyms() async {
    await AdminService.ensureDefaultGym();
    return FirebaseFirestore.instance.collection('gyms').limit(1).get();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: _loadGyms(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }

        // If no gyms exist, show registration screen for first admin
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return const AdminGymRegistrationScreen();
        }

        // If gyms exist, check auth state
        return const _AutoLoginGate();
      },
    );
  }
}

class _AutoLoginGate extends StatelessWidget {
  const _AutoLoginGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, dynamic>?>(
      future: AuthPrefs.load(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: AppTheme.background,
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.primary),
            ),
          );
        }
        final saved = snap.data;
        if (saved != null) {
          if (saved['isAdmin'] == true) {
            return _BiometricSessionGate(saved: saved);
          }
          if (FirebaseAuth.instance.currentUser == null) {
            AuthPrefs.clear();
            return OnboardingFlowScreen(
              onComplete: AuthPrefs.markOnboardingCompleted,
            );
          }
          return _BiometricSessionGate(saved: saved);
        }
        return const LoginScreen();
      },
    );
  }
}

class _BiometricSessionGate extends StatefulWidget {
  final Map<String, dynamic> saved;

  const _BiometricSessionGate({required this.saved});

  @override
  State<_BiometricSessionGate> createState() => _BiometricSessionGateState();
}

class _BiometricSessionGateState extends State<_BiometricSessionGate> {
  late final Future<bool> _unlockFuture;

  @override
  void initState() {
    super.initState();
    _unlockFuture = BiometricAuthService.authenticateForLogin();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: _unlockFuture,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9F7F2),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF035C4A)),
            ),
          );
        }

        if (snap.data != true) {
          return const LoginScreen();
        }

        final saved = widget.saved;
        FirebaseService.setMemberId(saved['memberId'] as String);
        if (saved['isAdmin'] == true) {
          return AdminDashboardScreen(gymId: saved['gymId'] as String);
        }
        return _MemberProfileGate(saved: saved);
      },
    );
  }
}

class _MemberProfileGate extends StatelessWidget {
  final Map<String, dynamic> saved;

  const _MemberProfileGate({required this.saved});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<bool>(
      future: AttendanceService.needsProfileCompletion(
        saved['memberId'] as String,
      ),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF9F7F2),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF035C4A)),
            ),
          );
        }

        if (snap.data == true) {
          return CompleteProfileScreen(
            memberId: saved['memberId'] as String,
            memberName: saved['memberName'] as String,
            gymId: saved['gymId'] as String,
          );
        }

        return HomeScreen(
          memberId: saved['memberId'] as String,
          memberName: saved['memberName'] as String,
          gymId: saved['gymId'] as String,
        );
      },
    );
  }
}
