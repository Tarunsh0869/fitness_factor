// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import '../services/auth_prefs.dart';
import 'admin_dashboard_screen.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _red = Color(0xFFB3261E);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _outline = Color(0xFFC3C8C6);

  final _gymIdCtrl = TextEditingController();
  final _pin = <int>[];
  bool _loading = false;
  bool _error = false;
  String? _gymIdError;

  void _onKey(int digit) {
    if (_pin.length >= 4) return;
    setState(() {
      _pin.add(digit);
      _error = false;
    });
    if (_pin.length == 4) _verify();
  }

  void _onDelete() {
    if (_pin.isEmpty) return;
    setState(() {
      _pin.removeLast();
      _error = false;
    });
  }

  Future<void> _verify() async {
    final gymInput = _gymIdCtrl.text.trim();
    if (gymInput.isEmpty) {
      setState(() => _gymIdError = 'Gym code is required');
      return;
    }
    setState(() => _loading = true);
    final pinStr = _pin.join();
    final resolvedGymId = await AdminService.resolveGymId(gymInput);
    final ok = resolvedGymId != null &&
        await AdminService.verifyAdminPin(resolvedGymId, pinStr);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok && resolvedGymId != null) {
      await AuthPrefs.save(
        memberId: 'admin',
        memberName: 'Admin',
        gymId: resolvedGymId,
        isAdmin: true,
      );
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AdminDashboardScreen(gymId: resolvedGymId),
        ),
      );
    } else {
      setState(() {
        _pin.clear();
        _error = true;
      });
    }
  }

  @override
  void dispose() {
    _gymIdCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Admin Access',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, _blueDk]),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withOpacity(0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.admin_panel_settings_outlined,
                  color: Colors.white,
                  size: 34,
                ),
              ),
              const SizedBox(height: 24),

              // Gym Code Input
              TextFormField(
                controller: _gymIdCtrl,
                decoration: InputDecoration(
                  labelText: 'Gym Code',
                  hintText: 'Fitness Factor',
                  labelStyle: TextStyle(color: _muted),
                  prefixIcon: const Icon(Icons.fitness_center, color: _blue),
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
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: _red, width: 1),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(18),
                    borderSide: BorderSide(color: _red, width: 1),
                  ),
                  errorText: _gymIdError,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 15,
                  ),
                ),
                style: const TextStyle(color: _ink, fontSize: 15),
                validator: (v) =>
                    v!.trim().isEmpty ? 'Gym code is required' : null,
              ),
              const SizedBox(height: 16),

              const Text(
                'Enter Admin PIN',
                style: TextStyle(
                  color: _ink,
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '4-digit PIN required',
                style: TextStyle(color: _muted, fontSize: 14),
              ),
              const SizedBox(height: 32),

              // PIN dots
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (i) {
                  final filled = i < _pin.length;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    margin: const EdgeInsets.symmetric(horizontal: 10),
                    width: 18,
                    height: 18,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _error
                          ? _red
                          : filled
                          ? _blue
                          : Colors.transparent,
                      border: Border.all(
                        color: _error
                            ? _red
                            : filled
                            ? _blue
                            : _muted,
                        width: 2,
                      ),
                    ),
                  );
                }),
              ),

              if (_error) ...[
                const SizedBox(height: 12),
                Text(
                  'Incorrect PIN. Try again.',
                  style: const TextStyle(
                    color: _red,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],

              const SizedBox(height: 40),

              // Numpad
              if (_loading)
                const CircularProgressIndicator(color: _blue)
              else
                _buildNumpad(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNumpad() {
    return Column(
      children: [
        for (final row in [
          [1, 2, 3],
          [4, 5, 6],
          [7, 8, 9],
          [-1, 0, -2], // -1 = empty, -2 = delete
        ])
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: row.map((d) {
                if (d == -1) return const SizedBox(width: 80, height: 64);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: _numKey(d),
                );
              }).toList(),
            ),
          ),
      ],
    );
  }

  Widget _numKey(int d) {
    final isDelete = d == -2;
    return GestureDetector(
      onTap: isDelete ? _onDelete : () => _onKey(d),
      child: Container(
        width: 72,
        height: 64,
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _blue.withOpacity(0.18)),
          boxShadow: [
            BoxShadow(
              color: _blue.withOpacity(0.10),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Center(
          child: isDelete
              ? Icon(Icons.backspace_outlined, color: _muted, size: 22)
              : Text(
                  '$d',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
        ),
      ),
    );
  }
}
