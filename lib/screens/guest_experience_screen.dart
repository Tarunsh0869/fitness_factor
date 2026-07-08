import 'dart:async';

import 'package:flutter/material.dart';

import '../services/guest_session_service.dart';
import '../widgets/freemium_paywall_sheet.dart';
import 'login_screen.dart';

class GuestExperienceScreen extends StatefulWidget {
  const GuestExperienceScreen({super.key});

  @override
  State<GuestExperienceScreen> createState() => _GuestExperienceScreenState();
}

class _GuestExperienceScreenState extends State<GuestExperienceScreen> {
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _accentDark = Color(0xFF02473A);

  int _starterWorkouts = 0;
  int _meaningfulActions = 0;
  int _gymTimeMinutes = 0;
  bool _timeTrackingActive = false;
  DateTime? _sessionStart;
  Timer? _timeTrackingTimer;
  bool _loadingWorkout = false;
  bool _signInPromptShown = false;

  @override
  void initState() {
    super.initState();
    _initGuestSession();
  }

  @override
  void dispose() {
    _timeTrackingTimer?.cancel();
    super.dispose();
  }

  Future<void> _initGuestSession() async {
    await GuestSessionService.startSession();
    final data = await GuestSessionService.load();
    if (!mounted) return;
    final startMillis = data['timeSessionStart'] as int?;
    setState(() {
      _starterWorkouts = data['starterWorkoutsCompleted'] as int;
      _meaningfulActions = data['meaningfulActionCount'] as int;
      _gymTimeMinutes = data['gymTimeMinutes'] as int;
      _timeTrackingActive = data['sessionActive'] as bool;
      _sessionStart = startMillis != null
          ? DateTime.fromMillisecondsSinceEpoch(startMillis)
          : null;
    });
    if (_timeTrackingActive) {
      _startLiveTimer();
    }
  }

  Future<void> _startStarterWorkout() async {
    if (_loadingWorkout) return;
    setState(() => _loadingWorkout = true);
    await Future.delayed(const Duration(milliseconds: 600));
    await GuestSessionService.recordMeaningfulAction(
      'starter_workout_complete',
    );
    await GuestSessionService.recordStarterWorkoutComplete();
    final data = await GuestSessionService.load();
    if (!mounted) return;
    setState(() {
      _loadingWorkout = false;
      _starterWorkouts = data['starterWorkoutsCompleted'] as int;
      _meaningfulActions = data['meaningfulActionCount'] as int;
      _gymTimeMinutes = data['gymTimeMinutes'] as int;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Starter workout completed. Great start!')),
    );
    await _maybeShowSignInPrompt();
  }

  Future<void> _toggleGymTimeSession() async {
    if (_timeTrackingActive) {
      final totalMinutes = await GuestSessionService.stopGymTimeSession();
      await GuestSessionService.recordMeaningfulAction('guest_time_session_recorded');
      if (!mounted) return;
      setState(() {
        _timeTrackingActive = false;
        _sessionStart = null;
        _gymTimeMinutes = totalMinutes;
      });
      _timeTrackingTimer?.cancel();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Gym time session recorded.')),
      );
      return;
    }

    await GuestSessionService.startGymTimeSession();
    if (!mounted) return;
    setState(() {
      _timeTrackingActive = true;
      _sessionStart = DateTime.now();
    });
    _startLiveTimer();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Gym time session started.')),
    );
  }

  void _startLiveTimer() {
    _timeTrackingTimer?.cancel();
    _timeTrackingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        // Refresh elapsed display.
      });
    });
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return '${hours}h ${minutes}m';
    }
    return '${minutes}m';
  }

  Widget _buildPremiumNeedRow(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: _accent, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: _ink,
                fontSize: 14,
                height: 1.4,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _maybeShowSignInPrompt() async {
    if (_signInPromptShown || _meaningfulActions < 1) return;
    _signInPromptShown = true;
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 42,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFC3C8C6),
                      borderRadius: BorderRadius.circular(99),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Save your progress',
                  style: TextStyle(
                    color: _ink,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Create your account to lock your guest workouts, gym time, and progress into a permanent member profile.',
                  style: TextStyle(color: _muted, fontSize: 14, height: 1.45),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                      Navigator.push(
                        this.context,
                        MaterialPageRoute(
                          builder: (_) =>
                              const LoginScreen(launchedFromGuest: true),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _accent,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      'Sign In',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 15,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _ink,
                      side: const BorderSide(color: Color(0xFFC3C8C6)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Continue as Guest',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
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
          'Guest Mode',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const LoginScreen(launchedFromGuest: true),
              ),
            ),
            child: const Text(
              'Sign in',
              style: TextStyle(color: _accent, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(18, 14, 18, 22),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [_accentDark, _accent],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Your gym journey starts before signup',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  SizedBox(height: 6),
                  Text(
                    'Try a starter workout first. No credentials needed. Upgrade anytime so your guest-mode gains become part of your permanent member story.',
                    style: TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Starter Workout',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                    Text(
                      'Try a starter workout first. No credentials needed. Upgrade anytime so your guest-mode gains become part of your permanent member story.',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _loadingWorkout ? null : _startStarterWorkout,
                      icon: _loadingWorkout
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.play_arrow_rounded),
                      label: Text(
                        _loadingWorkout
                            ? 'Completing...'
                            : 'Start Starter Workout',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                          'Why lock in Premium now',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                        Text(
                          'You’ve already earned $_starterWorkouts starter workout(s), $_gymTimeMinutes minutes of gym time, and $_meaningfulActions progress actions. Upgrade now to keep it in your member profile and power smarter progress.',
                    style: const TextStyle(color: _muted, fontSize: 13, height: 1.45),
                  ),
                  const SizedBox(height: 12),
                  _buildPremiumNeedRow('Save guest workouts and gym time forever'),
                  _buildPremiumNeedRow('Get instantly personalized plans'),
                  _buildPremiumNeedRow('Turn every visit into smarter progress'),
                  const SizedBox(height: 16),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton(
                      onPressed: () => FreemiumPaywallSheet.show(
                        context,
                        title: 'Premium for your progress',
                        subtitle:
                            'Keep the workouts and gym time you already earned, then unlock smarter plans and faster results.',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Unlock Premium Now',
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: _card,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Gym Time Recording',
                    style: TextStyle(
                      color: _ink,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _timeTrackingActive
                        ? 'Your current session is being tracked.'
                        : 'Track your gym visit time as a guest and save it when you sign in.',
                    style: const TextStyle(color: _muted, fontSize: 13),
                  ),
                  const SizedBox(height: 14),
                  if (_timeTrackingActive && _sessionStart != null)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Started: ${TimeOfDay.fromDateTime(_sessionStart!).format(context)}',
                          style: const TextStyle(color: _muted, fontSize: 13),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Elapsed: ${_formatDuration(DateTime.now().difference(_sessionStart!))}',
                          style: const TextStyle(
                            color: _ink,
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    )
                  else
                    Text(
                      'Recorded time: ${_gymTimeMinutes}m',
                      style: const TextStyle(
                        color: _ink,
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  const SizedBox(height: 14),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: _toggleGymTimeSession,
                      icon: Icon(
                        _timeTrackingActive
                            ? Icons.stop_circle_outlined
                            : Icons.play_circle_outlined,
                      ),
                      label: Text(
                        _timeTrackingActive ? 'Stop Session' : 'Start Session',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Meaningful actions completed: $_meaningfulActions',
              style: const TextStyle(color: _muted, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}
