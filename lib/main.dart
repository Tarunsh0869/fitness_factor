import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';
import 'services/firebase_service.dart';
import 'services/auth_prefs.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'screens/seed_screen.dart';
import 'screens/admin_dashboard_screen.dart';
import 'screens/admin_login_screen.dart';
import 'screens/admin_gym_registration_screen.dart';

@pragma('vm:entry-point')
Future<void> _firebaseBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    systemNavigationBarColor: Colors.white,
    systemNavigationBarIconBrightness: Brightness.dark,
  ));

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
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF2563EB),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xFFF0F4FF),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFFF0F4FF),
          foregroundColor: Color(0xFF111827),
          elevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle(
            statusBarIconBrightness: Brightness.dark,
            statusBarColor: Colors.transparent,
          ),
        ),
        cardColor: Colors.white,
      ),
      home: const _AuthGate(),
    );
  }
}

class _AuthGate extends StatelessWidget {
  const _AuthGate();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<QuerySnapshot>(
      future: FirebaseFirestore.instance.collection('gyms').limit(1).get(),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            backgroundColor: Color(0xFFF0F4FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
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
            backgroundColor: Color(0xFFF0F4FF),
            body: Center(
              child: CircularProgressIndicator(color: Color(0xFF2563EB)),
            ),
          );
        }
        final saved = snap.data;
        if (saved != null) {
          FirebaseService.setMemberId(saved['memberId'] as String);
          if (saved['isAdmin'] == true) {
            return AdminDashboardScreen(gymId: saved['gymId'] as String);
          }
          return HomeScreen(
            memberId:   saved['memberId'] as String,
            memberName: saved['memberName'] as String,
            gymId:      saved['gymId'] as String,
          );
        }
        return const LoginScreen();
      },
    );
  }
}
