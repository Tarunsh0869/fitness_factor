import 'package:flutter/material.dart';
import '../services/attendance_service.dart';
import '../services/auth_prefs.dart';
import 'onboarding/onboarding_flow_screen.dart';

class PendingVerificationScreen extends StatefulWidget {
  final String memberName;
  final String verificationStatus; // 'pending' | 'rejected'

  const PendingVerificationScreen({
    super.key,
    required this.memberName,
    required this.verificationStatus,
  });

  @override
  State<PendingVerificationScreen> createState() =>
      _PendingVerificationScreenState();
}

class _PendingVerificationScreenState
    extends State<PendingVerificationScreen> {
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _red = Color(0xFFB3261E);
  static const _amber = Color(0xFFC7A66A);

  bool _checking = false;

  bool get _isRejected => widget.verificationStatus == 'rejected';

  Future<void> _checkStatus() async {
    setState(() => _checking = true);
    try {
      // Reload the Firebase user and re-fetch their member doc
      final user = await AttendanceService.reloadCurrentUser();
      if (!mounted) return;
      if (user != null && user['verificationStatus'] == 'verified') {
        // Verified — go back to root so _AutoLoginGate re-evaluates
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (_) => OnboardingFlowScreen(
              onComplete: AuthPrefs.markOnboardingCompleted,
            ),
          ),
          (_) => false,
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Still pending. Check back later.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _checking = false);
    }
  }

  Future<void> _logout() async {
    await AttendanceService.logout();
    await AuthPrefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => OnboardingFlowScreen(
          onComplete: AuthPrefs.markOnboardingCompleted,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final color = _isRejected ? _red : _amber;
    final icon = _isRejected
        ? Icons.block_rounded
        : Icons.hourglass_top_rounded;
    final title = _isRejected ? 'Access Denied' : 'Awaiting Approval';
    final body = _isRejected
        ? 'Your membership request was not approved. Please contact your gym administrator for more information.'
        : 'Your account is pending approval by the gym administrator. You\'ll be able to access the app once verified.';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 88,
                height: 88,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 42),
              ),
              const SizedBox(height: 24),
              Text(
                'Hi, ${widget.memberName}',
                style: const TextStyle(
                  color: _muted,
                  fontSize: 15,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  body,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 32),
              if (!_isRejected)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton.icon(
                    onPressed: _checking ? null : _checkStatus,
                    icon: _checking
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.refresh_rounded),
                    label: Text(_checking ? 'Checking...' : 'Check Status'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _logout,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _ink,
                    side: const BorderSide(color: Color(0xFFC3C8C6)),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text(
                    'Sign Out',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
