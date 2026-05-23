// ignore_for_file: deprecated_member_use

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'login_screen.dart';

class SeedScreen extends StatefulWidget {
  const SeedScreen({super.key});

  @override
  State<SeedScreen> createState() => _SeedScreenState();
}

class _SeedScreenState extends State<SeedScreen> {
  static const _blue   = Color(0xFF2563EB);
  static const _blueDk = Color(0xFF1D4ED8);
  static const _bg     = Color(0xFFF0F4FF);
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);

  String _status = 'Setting up Firestore...';
  bool   _done   = false;

  @override
  void initState() { super.initState(); _seed(); }

  Future<void> _seed() async {
    final db = FirebaseFirestore.instance;
    try {
      await db.collection('gyms').doc('gym_001').set({
        'name': 'Fitness Factor HQ',
        'latitude': 3.1390,
        'longitude': 101.6869,
        'radiusMeters': 50,
        'adminPin': '1234',
      }, SetOptions(merge: true));

      setState(() => _status = '✓ Gym configured');

      await db.collection('members').doc('member_001').set({
        'name': 'Test Member',
        'phone': '+60123456789',
        'gymId': 'gym_001',
        'fcmToken': '',
        'emergencyContact': '+60123456780',
        'membershipType': 'Basic',
        'gender': 'Male',
        'dateOfBirth': '1990-01-01T00:00:00.000',
        'aadhaarNumber': '',
        'aadhaarName': '',
        'active': true,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      setState(() {
        _status = '✓ Gym & test member ready — login below';
        _done   = true;
      });
    } catch (e) {
      setState(() => _status = 'Error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: Stack(
        children: [
          Positioned(
            top: -60, right: -60,
            child: Container(
              width: 220, height: 220,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withOpacity(0.08),
              ),
            ),
          ),
          Positioned(
            bottom: 40, left: -60,
            child: Container(
              width: 180, height: 180,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _blue.withOpacity(0.05),
              ),
            ),
          ),
          Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 72, height: 72,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_blue, _blueDk],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: _blue.withOpacity(0.3),
                            blurRadius: 20, offset: const Offset(0, 8)),
                      ],
                    ),
                    child: const Icon(Icons.fitness_center,
                        color: Colors.white, size: 34),
                  ),
                  const SizedBox(height: 24),
                  const Text('Fitness Factor',
                      style: TextStyle(color: _ink, fontSize: 26,
                          fontWeight: FontWeight.w800)),
                  const SizedBox(height: 8),
                  Text(_status,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: _muted, fontSize: 15)),
                  if (_done) ...[
                    const SizedBox(height: 32),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(color: _blue.withOpacity(0.2)),
                        boxShadow: [
                          BoxShadow(
                            color: _blue.withOpacity(0.08),
                            blurRadius: 16, offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          const Text('Setup Complete',
                              style: TextStyle(color: _ink, fontSize: 16,
                                  fontWeight: FontWeight.w700)),
                          const SizedBox(height: 16),
                          _credRow(Icons.person_outline, 'Member Login',
                              '+60123456789'),
                          const SizedBox(height: 10),
                          _credRow(Icons.admin_panel_settings_outlined, 'Admin PIN',
                              '1234'),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity, height: 52,
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [_blue, _blueDk]),
                                borderRadius: BorderRadius.circular(14),
                                boxShadow: [
                                  BoxShadow(
                                    color: _blue.withOpacity(0.35),
                                    blurRadius: 16, offset: const Offset(0, 6),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () =>
                                    Navigator.pushReplacement(context,
                                        MaterialPageRoute(
                                            builder: (_) => const LoginScreen())),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(14)),
                                ),
                                child: const Text('Open Login',
                                    style: TextStyle(fontWeight: FontWeight.w700,
                                        fontSize: 16)),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ] else
                    Padding(
                      padding: const EdgeInsets.only(top: 24),
                      child: CircularProgressIndicator(color: _blue),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _credRow(IconData icon, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
      decoration: BoxDecoration(
        color: _blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _blue.withOpacity(0.15)),
      ),
      child: Row(
        children: [
          Icon(icon, color: _blue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(color: _muted, fontSize: 12)),
                const SizedBox(height: 1),
                Text(value,
                    style: const TextStyle(color: _ink, fontSize: 14,
                        fontWeight: FontWeight.w700)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: _blue.withOpacity(0.10),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('TEST',
                style: TextStyle(color: _blue, fontSize: 10,
                    fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }
}
