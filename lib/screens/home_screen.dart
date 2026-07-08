import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';

import '../blocs/home/home_bloc.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/auth_prefs.dart';
import '../services/firebase_service.dart';
import '../services/geo_service.dart';
import '../widgets/exit_confirmation_sheet.dart';
import '../widgets/fitness_factor_logo.dart';
import 'onboarding/onboarding_flow_screen.dart';
import 'rewards_screen.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'attendance_form_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatelessWidget {
  final String memberId;
  final String memberName;
  final String gymId;

  const HomeScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.gymId,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => HomeBloc(memberId: memberId, gymId: gymId)
        ..add(HomeInit()),
      child: _HomeView(memberId: memberId, memberName: memberName, gymId: gymId),
    );
  }
}

enum _LocationAttendanceAction {
  checkedIn,
  alreadyCheckedIn,
  checkInFailed,
  exitRequested,
  outside,
}

class _HomeView extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String gymId;

  const _HomeView({
    required this.memberId,
    required this.memberName,
    required this.gymId,
  });

  @override
  State<_HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<_HomeView> {
  static const _pageBg = Color(0xFFF9F7F2);
  static const _cardBg = Color(0xFFF3F2ED);
  static const _surfaceAlt = Color(0xFFE0E4E2);
  static const _outline = Color(0xFFC3C8C6);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _accentDark = Color(0xFF02473A);
  static const _success = Color(0xFF0A8F69);
  static const _danger = Color(0xFFB3261E);

  // All reactive state is now owned by HomeBloc.
  // These booleans track one-shot UI that needs BuildContext (dialog).
  bool _qrDialogOpen = false;

  StreamSubscription? _sessionSub;
  StreamSubscription? _historySub;
  StreamSubscription? _statsSub;
  StreamSubscription? _geoSub;
  StreamSubscription? _fcmSub;
  Timer? _sessionTimer;
  Timer? _autoCheckoutTimer;
  AttendanceRecord? _openSession;
  List<AttendanceRecord> _history = [];
  int _weekVisits = 0;
  Duration _elapsed = Duration.zero;
  bool _isInsideGym = false;
  bool _geoReady = false;
  bool _geofenceStarted = false;
  bool _checkingArrival = false;
  bool _manualCheckInLoading = false;
  String _gymName = '';
  String _memberPhone = '';
  int _selectedTab = 0;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    _sessionSub = AttendanceService.openSessionStream(widget.memberId).listen((
      session,
    ) {
      if (!mounted) return;
      setState(() {
        _openSession = session;
        if (session != null && !_isInsideGym) {
          _isInsideGym = true;
        }
      });
      if (session != null) {
        _startSessionTimer(session.checkedIn);
      } else {
        _sessionTimer?.cancel();
        setState(() => _elapsed = Duration.zero);
      }
    });

    _historySub = AttendanceService.historyStream(widget.memberId).listen((
      records,
    ) {
      if (!mounted) return;
      setState(() => _history = records);
    });

    _statsSub = AttendanceService.statsStream(widget.memberId).listen((stats) {
      if (!mounted) return;
      setState(() => _weekVisits = stats['weekVisits'] as int);
    });

    await Future.wait([_loadMember(), _loadGymName()]);
    _listenFcm();
  }

  Future<void> _loadMember() async {
    final member = await AttendanceService.getMember(widget.memberId);
    if (!mounted || member == null) return;
    setState(() {
      _memberPhone = member['phone'] ?? '';
    });
  }

  Future<void> _loadGymName() async {
    final gym = await AttendanceService.getGym(widget.gymId);
    if (!mounted) return;
    final name = (gym?['name'] as String? ?? '').trim();
    setState(() {
      _gymName = name.isEmpty ? widget.gymId : name;
    });
  }

  Future<bool> _ensureGeofenceStarted() async {
    if (_geofenceStarted) return true;

    final granted = await GeoService.requestPermission();
    if (!granted) return false;
    final gym = await AttendanceService.getGym(widget.gymId);
    if (gym == null || !mounted) return false;

    setState(() {
      _geoReady = true;
      _geofenceStarted = true;
    });
    _geoSub = GeoService.watchGeofence(
      gymLat: (gym['latitude'] as num).toDouble(),
      gymLng: (gym['longitude'] as num).toDouble(),
      radiusMeters: (gym['radiusMeters'] as num).toDouble(),
    ).listen(_onGeofenceChange);
    return true;
  }

  Future<_LocationAttendanceAction?> _applyLocationAttendance(
    bool isInside,
  ) async {
    if (!mounted) return null;
    setState(() => _isInsideGym = isInside);
    if (isInside && _openSession == null) {
      await AttendanceService.checkIn(widget.memberId, widget.gymId);
    } else if (!isInside && _openSession != null) {
      await AttendanceService.notifyExit(widget.memberId);
      _startAutoCheckoutTimer();
      return _LocationAttendanceAction.exitRequested;
    }

    return _LocationAttendanceAction.outside;
  }

  Future<void> _onGeofenceChange(bool isInside) async {
    await _applyLocationAttendance(isInside);
  }

  Future<void> _syncArrivalByLocation({bool showFeedback = true}) async {
    if (_checkingArrival) return;

    setState(() => _checkingArrival = true);
    try {
      final granted = await _ensureGeofenceStarted();
      if (!mounted) return;
      if (!granted) {
        if (showFeedback) {
          _showArrivalSnack(
            'Location permission is needed to confirm arrival.',
            color: _danger,
          );
        }
        return;
      }

      final gym = await AttendanceService.getGym(widget.gymId);
      if (!mounted) return;
      final lat = gym?['latitude'];
      final lng = gym?['longitude'];
      final radius = gym?['radiusMeters'];
      if (lat is! num || lng is! num) {
        if (showFeedback) {
          _showArrivalSnack('Gym location is not configured.', color: _danger);
        }
        return;
      }

      final isInside = await GeoService.isInsideGeofence(
        gymLat: lat.toDouble(),
        gymLng: lng.toDouble(),
        radiusMeters: radius is num ? radius.toDouble() : 50,
      );
      if (!mounted) return;
      if (isInside == null) {
        if (showFeedback) {
          _showArrivalSnack(
            'Could not read your current location.',
            color: _danger,
          );
        }
        return;
      }

      final action = await _applyLocationAttendance(isInside);
      if (!showFeedback || action == null || !mounted) return;

      switch (action) {
        case _LocationAttendanceAction.checkedIn:
          _showArrivalSnack('Arrival confirmed. Check-in started.');
          break;
        case _LocationAttendanceAction.alreadyCheckedIn:
          _showArrivalSnack('You are already checked in.');
          break;
        case _LocationAttendanceAction.checkInFailed:
          _showArrivalSnack(
            'Arrival found, but check-in failed.',
            color: _danger,
          );
          break;
        case _LocationAttendanceAction.exitRequested:
          _showArrivalSnack('You are outside the gym. Exit confirmation sent.');
          break;
        case _LocationAttendanceAction.outside:
          _showArrivalSnack('You are outside the gym range.', color: _danger);
          break;
      }
    } finally {
      if (mounted) setState(() => _checkingArrival = false);
    }
  }

  void _showArrivalSnack(String message, {Color color = _accent}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }

  void _startSessionTimer(DateTime start) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsed = DateTime.now().difference(start));
    });
  }

  void _startAutoCheckoutTimer() {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = Timer(const Duration(minutes: 5), _doCheckout);
  }

  Future<void> _doCheckout() async {
    final session = _openSession;
    if (session == null) return;
    _autoCheckoutTimer?.cancel();
    await AttendanceService.checkOut(session.id);
  }

  Future<void> _checkOutNow() async {
    if (_openSession == null) return;
    await _doCheckout();
    if (!mounted) return;
    _showArrivalSnack('Session checked out.');
  }

  Future<void> _quickManualCheckIn() async {
    if (_manualCheckInLoading || _openSession != null) return;
    setState(() => _manualCheckInLoading = true);
    try {
      final sessionId = await AttendanceService.quickManualCheckIn(
        memberId: widget.memberId,
        gymId: widget.gymId,
      );
      if (!mounted) return;
      if (sessionId == null) {
        _showArrivalSnack(
          'Could not check in. You may already have an open session.',
          color: _danger,
        );
        return;
      }
      _showArrivalSnack('Manual check-in successful.');
    } finally {
      if (mounted) setState(() => _manualCheckInLoading = false);
    }
  }

  Future<void> _checkInWithGymCode() async {
    if (_openSession != null) return;
    final ctrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: _cardBg,
          title: const Text(
            'Enter Gym QR Code',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
          ),
          content: TextField(
            controller: ctrl,
            textCapitalization: TextCapitalization.characters,
            decoration: InputDecoration(
              hintText: 'e.g. FF-123',
              hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: _outline),
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _muted)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, ctrl.text.trim()),
              style: ElevatedButton.styleFrom(
                backgroundColor: _accent,
                foregroundColor: Colors.white,
              ),
              child: const Text('Check In'),
            ),
          ],
        );
      },
    );
    if (!mounted || result == null || result.isEmpty) return;

    final checkInResult = await AttendanceService.checkInWithGymCode(
      memberId: widget.memberId,
      gymCode: result,
    );
    if (!mounted) return;
    if (checkInResult['ok'] == true) {
      _showArrivalSnack('QR check-in successful.');
      return;
    }
    _showArrivalSnack(
      checkInResult['error'] as String? ?? 'QR check-in failed.',
      color: _danger,
    );
  }

  void _listenFcm() {
    _fcmSub = FirebaseService.exitConfirmationStream().listen((_) {
      if (!mounted || _openSession == null) return;
      ExitConfirmationSheet.show(
        context,
        sessionId: _openSession!.id.isEmpty
            ? 0
            : int.tryParse(_openSession!.id) ?? 0,
        onConfirm: _doCheckout,
        onDeny: () {
          _autoCheckoutTimer?.cancel();
          setState(() => _isInsideGym = true);
        },
      );
    });
  }

  Future<void> _onRefresh() =>
      Future.wait([_loadMember(), _loadGymName()]);

  Future<void> _logout() async {
    await AttendanceService.logout();
    await AuthPrefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) =>
            OnboardingFlowScreen(onComplete: AuthPrefs.markOnboardingCompleted),
      ),
      (_) => false,
    );
  }

  Future<void> _openSettings() async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SettingsScreen(
          memberId: widget.memberId,
          memberName: widget.memberName,
          memberPhone: _memberPhone,
          gymId: widget.gymId,
        ),
      ),
    );
  }

  Future<void> _openStats() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => StatsScreen(memberId: widget.memberId)),
    );
  }


  Duration? _averageDuration() {
    final closed = _history.where((r) => r.duration != null).toList();
    if (closed.isEmpty) return null;
    final totalMinutes = closed.fold<int>(
      0,
      (sum, r) => sum + r.duration!.inMinutes,
    );
    return Duration(minutes: (totalMinutes / closed.length).round());
  }

  int _estimateCalories(Duration? duration) {
    if (duration == null) return 0;
    return (duration.inMinutes * 7.2).round();
  }

  String _formatDuration(Duration? duration) {
    if (duration == null) return '--';
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    if (hours > 0) {
      return minutes == 0 ? '${hours}h' : '${hours}h ${minutes}m';
    }
    return '${duration.inMinutes}m';
  }

  String _relativeDay(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final target = DateTime(date.year, date.month, date.day);
    final diff = today.difference(target).inDays;

    if (diff == 0) return 'Today';
    if (diff == 1) return 'Yesterday';
    return DateFormat('MMM d').format(date);
  }

  String _formatElapsed(Duration duration) {
    final h = duration.inHours.toString().padLeft(2, '0');
    final m = (duration.inMinutes % 60).toString().padLeft(2, '0');
    final s = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  IconData _workoutIcon(String? workoutType) {
    final type = (workoutType ?? '').toLowerCase();
    if (type.contains('cardio')) return Icons.directions_run_rounded;
    if (type.contains('yoga')) return Icons.self_improvement_rounded;
    if (type.contains('swim')) return Icons.pool_rounded;
    if (type.contains('cycle')) return Icons.directions_bike_rounded;
    if (type.contains('crossfit')) return Icons.bolt_rounded;
    return Icons.fitness_center_rounded;
  }

  void _handleNavTap(int index) {
    if (_selectedTab != index) setState(() => _selectedTab = index);
  }

  @override
  Widget build(BuildContext context) {
    const weeklyGoal = 5;
    final weeklyProgress = (_weekVisits / weeklyGoal).clamp(0.0, 1.0);
    final avgDuration = _averageDuration();
    final burnedCalories = _history.fold<int>(
      0,
      (sum, r) => sum + _estimateCalories(r.duration),
    );
    final recentSessions = _history.take(4).toList();

    return Scaffold(
      backgroundColor: _bg,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.push(context, MaterialPageRoute(
          builder: (_) => AttendanceFormScreen(
            memberId: widget.memberId, gymId: widget.gymId,
          ),
        )),
        backgroundColor: _blue,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Log Attendance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: _blue,
          backgroundColor: Colors.white,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    _buildSummaryRow(),
                    const SizedBox(height: 16),
                    _buildCheckInCard(),
                    const SizedBox(height: 14),
                    _buildWeeklyProgressCard(
                      visits: _weekVisits,
                      goal: weeklyGoal,
                      progress: weeklyProgress,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.watch_later_outlined,
                            label: 'Avg. Duration',
                            value: _formatDuration(avgDuration),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _buildMetricCard(
                            icon: Icons.local_fire_department_outlined,
                            label: 'Burned',
                            value:
                                '${NumberFormat.decimalPattern().format(burnedCalories)} kcal',
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        const Text(
                          'Recent Sessions',
                          style: TextStyle(
                            color: _ink,
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        GestureDetector(
                          onTap: () => setState(() => _selectedTab = 1),
                          child: const Text(
                            'View All',
                            style: TextStyle(
                              color: _accent,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    if (recentSessions.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18),
                        decoration: BoxDecoration(
                          color: _cardBg,
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: const Text(
                          'No sessions yet. Start with Gym Check-In.',
                          style: TextStyle(color: _muted, fontSize: 14),
                        ),
                      )
                    else
                      ...recentSessions.map(_buildRecentTile),
                    const SizedBox(height: 18),
                  ],
                ),
              ),
            ),
          ),
          StatsScreen(memberId: widget.memberId, embedded: true),
          RewardsScreen(memberId: widget.memberId, embedded: true),
        ],
      ),
    );
  }

  Widget _buildTopBar() {
    final firstInitial = widget.memberName.trim().isEmpty
        ? 'U'
        : widget.memberName.trim().substring(0, 1).toUpperCase();
    final gymLabel = _gymName.isEmpty ? widget.gymId : _gymName;

    return Row(
      children: [
        const FitnessFactorLogo(size: 80),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Fitness Factor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: _ink,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                gymLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _muted,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        GestureDetector(
          onTap: _openSettings,
          child: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(19),
            ),
            alignment: Alignment.center,
            child: Text(
              firstInitial,
              style: const TextStyle(color: _ink, fontWeight: FontWeight.w700),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCheckInCard() {
    final statusText = _checkingArrival
        ? 'Checking your location...'
        : _openSession == null
        ? 'Use location, manual, or QR check-in'
        : 'Session running ${_formatElapsed(_elapsed)}';
    final anyLoading = _checkingArrival || _manualCheckInLoading;

    return InkWell(
      onTap: anyLoading || _openSession != null
          ? null
          : () => _syncArrivalByLocation(),
      borderRadius: BorderRadius.circular(18),
      child: Ink(
        height: _openSession == null ? 252 : 212,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [_accentDark, _accent],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: _accent.withOpacity(0.28),
              blurRadius: 18,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              right: -24,
              top: -16,
              child: Icon(
                Icons.fitness_center_rounded,
                size: 120,
                color: Colors.white.withOpacity(0.08),
              ),
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: (_isInsideGym ? _success : _muted).withOpacity(0.24),
                  borderRadius: BorderRadius.circular(50),
                ),
                child: Text(
                  _isInsideGym
                      ? 'Inside Gym'
                      : (_geoReady ? 'Outside' : 'GPS Syncing'),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.16),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: anyLoading
                        ? const Padding(
                            padding: EdgeInsets.all(12),
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2.5,
                            ),
                          )
                        : const Icon(
                            Icons.my_location_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Gym Arrival',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    statusText,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.85),
                      fontSize: 13,
                    ),
                  ),
                  if (_openSession == null) ...[
                    const SizedBox(height: 14),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ElevatedButton.icon(
                          onPressed: _checkingArrival
                              ? null
                              : _syncArrivalByLocation,
                          icon: const Icon(Icons.my_location_rounded, size: 16),
                          label: const Text('Use Location'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: _accentDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton.icon(
                          onPressed: _manualCheckInLoading
                              ? null
                              : _quickManualCheckIn,
                          icon: const Icon(Icons.touch_app_outlined, size: 16),
                          label: const Text('Quick Check-In'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.9),
                            foregroundColor: _accentDark,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            textStyle: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    TextButton.icon(
                      onPressed: _checkInWithGymCode,
                      icon: const Icon(
                        Icons.qr_code_2_rounded,
                        color: Colors.white,
                      ),
                      label: const Text(
                        'Check In with QR Code',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                  if (_openSession != null) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: _checkOutNow,
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Check Out Now'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.white,
                          foregroundColor: _accentDark,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(22),
                          ),
                          textStyle: const TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklyProgressCard({
    required int visits,
    required int goal,
    required double progress,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly Progress',
                  style: TextStyle(color: _muted, fontSize: 12),
                ),
                const SizedBox(height: 4),
                Text(
                  '$visits/$goal',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 36,
                    fontWeight: FontWeight.w800,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Sessions this week',
                  style: TextStyle(
                    color: _accent,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 68,
            height: 68,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 6,
                  backgroundColor: _surfaceAlt,
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
                const Icon(Icons.trending_up_rounded, color: _accent, size: 24),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: _accent, size: 18),
          const SizedBox(height: 8),
          Text(label, style: const TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              color: _ink,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistoryTile(AttendanceRecord r) {
    final isOpen = r.isOpen;
    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AttendanceFormScreen(
          memberId: widget.memberId, gymId: widget.gymId, existing: r,
        ),
      )),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: isOpen ? Border.all(color: _blue.withOpacity(0.3), width: 1.5) : null,
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 8, offset: const Offset(0, 2)),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40, height: 40,
              decoration: BoxDecoration(
                color: isOpen ? _blue.withOpacity(0.10) : const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                isOpen ? Icons.play_circle_outline : Icons.check_circle_outline,
                color: isOpen ? _blue : _subtle, size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(DateFormat('EEE, MMM d').format(r.checkedIn),
                      style: const TextStyle(
                          color: _ink, fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Text(
                    '${DateFormat('hh:mm a').format(r.checkedIn)}'
                    '${r.checkedOut != null ? ' → ${DateFormat('hh:mm a').format(r.checkedOut!)}' : ' → now'}',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  if (r.workoutType != null && r.workoutType!.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(r.workoutType!,
                        style: const TextStyle(color: _subtle, fontSize: 11)),
                  ],
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(_formatDuration(r.duration),
                    style: const TextStyle(
                        color: _ink, fontSize: 14, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text(r.source.toUpperCase(),
                    style: const TextStyle(
                        color: _subtle, fontSize: 10, letterSpacing: 0.8)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
