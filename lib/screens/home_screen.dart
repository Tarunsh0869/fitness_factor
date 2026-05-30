import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/auth_prefs.dart';
import '../services/firebase_service.dart';
import '../services/geo_service.dart';
import '../widgets/exit_confirmation_sheet.dart';
import 'onboarding/onboarding_flow_screen.dart';
import 'settings_screen.dart';
import 'stats_screen.dart';

class HomeScreen extends StatefulWidget {
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
  State<HomeScreen> createState() => _HomeScreenState();
}

enum _LocationAttendanceAction {
  checkedIn,
  alreadyCheckedIn,
  checkInFailed,
  exitRequested,
  outside,
}

class _HomeScreenState extends State<HomeScreen> {
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

  bool _isInsideGym = false;
  bool _geoReady = false;
  bool _checkingArrival = false;
  bool _manualCheckInLoading = false;
  List<AttendanceRecord> _history = [];
  AttendanceRecord? _openSession;
  Timer? _sessionTimer;
  Timer? _autoCheckoutTimer;
  StreamSubscription? _geoSub;
  StreamSubscription? _fcmSub;
  StreamSubscription? _sessionSub;
  StreamSubscription? _historySub;
  Duration _elapsed = Duration.zero;
  String _memberPhone = '';
  String _gymName = '';
  int _weekVisits = 0;
  bool _geofenceStarted = false;

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

    await Future.wait([_loadMember(), _loadStats(), _loadGymName()]);
    _listenFcm();
  }

  Future<void> _loadMember() async {
    final member = await AttendanceService.getMember(widget.memberId);
    if (!mounted || member == null) return;
    setState(() {
      _memberPhone = member['phone'] ?? '';
    });
  }

  Future<void> _loadStats() async {
    final stats = await AttendanceService.getStats(widget.memberId);
    if (!mounted) return;
    setState(() {
      _weekVisits = stats['weekVisits'] as int;
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

    if (isInside) {
      _autoCheckoutTimer?.cancel();
      if (_openSession != null) {
        return _LocationAttendanceAction.alreadyCheckedIn;
      }

      final id = await AttendanceService.checkIn(widget.memberId, widget.gymId);
      return id == null
          ? _LocationAttendanceAction.checkInFailed
          : _LocationAttendanceAction.checkedIn;
    }

    if (!isInside && _openSession != null) {
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
      Future.wait([_loadMember(), _loadStats(), _loadGymName()]);

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

  Future<void> _openQuickMenu() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: _cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
      ),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: _outline,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              ListTile(
                leading: const Icon(Icons.bar_chart_rounded, color: _accent),
                title: const Text('View Stats'),
                onTap: () {
                  Navigator.pop(context);
                  _openStats();
                },
              ),
              ListTile(
                leading: const Icon(Icons.settings_outlined, color: _accent),
                title: const Text('Settings'),
                onTap: () {
                  Navigator.pop(context);
                  _openSettings();
                },
              ),
              ListTile(
                leading: const Icon(Icons.logout_rounded, color: _danger),
                title: const Text('Logout'),
                onTap: () {
                  Navigator.pop(context);
                  _logout();
                },
              ),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
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

  Future<void> _handleNavTap(int index) async {
    if (index == 0) {
      if (_selectedTab != 0) {
        setState(() => _selectedTab = 0);
      }
      return;
    }

    if (index == 1) {
      setState(() => _selectedTab = 1);
      await _syncArrivalByLocation();
      return;
    }

    if (index == 2) {
      await _openStats();
    } else if (index == 3) {
      await _openSettings();
    }

    if (mounted) {
      setState(() => _selectedTab = 0);
    }
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
      backgroundColor: _pageBg,
      bottomNavigationBar: _buildBottomNav(),
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          color: _accent,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildTopBar(),
                const SizedBox(height: 4),
                const Text(
                  'Track your Fitness Factor goals.',
                  style: TextStyle(color: _muted, fontSize: 15),
                ),
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
                      onTap: _openStats,
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
    );
  }

  Widget _buildTopBar() {
    final firstInitial = widget.memberName.trim().isEmpty
        ? 'U'
        : widget.memberName.trim().substring(0, 1).toUpperCase();
    final gymLabel = _gymName.isEmpty ? widget.gymId : _gymName;

    return Row(
      children: [
        Material(
          color: _cardBg,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: _openQuickMenu,
            child: const SizedBox(
              width: 40,
              height: 40,
              child: Icon(Icons.menu_rounded, color: _ink),
            ),
          ),
        ),
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

  Widget _buildRecentTile(AttendanceRecord record) {
    final calories = _estimateCalories(record.duration);
    final subtitle =
        '${_relativeDay(record.checkedIn)} • ${DateFormat('hh:mm a').format(record.checkedIn)}';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: _surfaceAlt,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              _workoutIcon(record.workoutType),
              color: _accent,
              size: 19,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  (record.workoutType?.isNotEmpty ?? false)
                      ? record.workoutType!
                      : 'General Workout',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: _muted, fontSize: 12),
                ),
              ],
            ),
          ),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                _formatDuration(record.duration),
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '$calories kcal',
                style: const TextStyle(color: _muted, fontSize: 12),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    final items = [
      (Icons.home_outlined, Icons.home_rounded, 'Home'),
      (Icons.location_on_outlined, Icons.location_on_rounded, 'Arrival'),
      (
        Icons.local_fire_department_outlined,
        Icons.local_fire_department_rounded,
        'Streaks',
      ),
      (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.hasBoundedWidth
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width;
        final compact = width < 390;
        final tiny = width < 340;
        final marginX = tiny ? 8.0 : (compact ? 10.0 : 14.0);
        final paddingX = tiny ? 6.0 : (compact ? 8.0 : 10.0);
        final paddingY = tiny ? 7.0 : 9.0;
        final itemWidth =
            (width - (marginX * 2) - (paddingX * 2)) / items.length;
        final activePillWidth = (itemWidth - 8)
            .clamp(38.0, tiny ? 46.0 : (compact ? 52.0 : 58.0))
            .toDouble();
        final inactivePillWidth = (itemWidth - 14)
            .clamp(34.0, tiny ? 40.0 : 46.0)
            .toDouble();
        final pillHeight = tiny ? 30.0 : 34.0;
        final labelFontSize = tiny ? 9.5 : (compact ? 10.0 : 11.0);

        return SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.fromLTRB(marginX, 0, marginX, 12),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: paddingX,
                vertical: paddingY,
              ),
              decoration: BoxDecoration(
                color: _cardBg,
                borderRadius: BorderRadius.circular(tiny ? 28 : 34),
                border: Border.all(color: Colors.white.withOpacity(0.72)),
                boxShadow: [
                  BoxShadow(
                    color: _accent.withOpacity(0.16),
                    blurRadius: compact ? 22 : 28,
                    offset: Offset(0, compact ? 10 : 14),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: compact ? 14 : 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Row(
                children: List.generate(items.length, (index) {
                  final selected = index == _selectedTab;
                  final (icon, activeIcon, label) = items[index];

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => _handleNavTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: Padding(
                        padding: EdgeInsets.symmetric(vertical: tiny ? 2 : 4),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              curve: Curves.easeOut,
                              width: selected
                                  ? activePillWidth
                                  : inactivePillWidth,
                              height: pillHeight,
                              decoration: BoxDecoration(
                                color: selected
                                    ? _accent.withOpacity(0.14)
                                    : Colors.transparent,
                                borderRadius: BorderRadius.circular(22),
                              ),
                              child: Icon(
                                selected ? activeIcon : icon,
                                color: selected ? _accent : _muted,
                                size: selected
                                    ? (tiny ? 19 : 21)
                                    : (tiny ? 17 : 19),
                              ),
                            ),
                            SizedBox(height: tiny ? 1 : 2),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                label,
                                maxLines: 1,
                                style: TextStyle(
                                  color: selected ? _accent : _muted,
                                  fontWeight: selected
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  fontSize: labelFontSize,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _geoSub?.cancel();
    _fcmSub?.cancel();
    _sessionTimer?.cancel();
    _autoCheckoutTimer?.cancel();
    _sessionSub?.cancel();
    _historySub?.cancel();
    super.dispose();
  }
}
