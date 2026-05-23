// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/geo_service.dart';
import '../services/firebase_service.dart';
import '../services/auth_prefs.dart';
import '../widgets/exit_confirmation_sheet.dart';
import 'settings_screen.dart';
import 'login_screen.dart';
import 'attendance_form_screen.dart';
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

class _HomeScreenState extends State<HomeScreen> {
  static const _blue   = Color(0xFF2563EB);
  static const _blueDk = Color(0xFF1D4ED8);
  static const _green  = Color(0xFF16A34A);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Colors.white;
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);
  static const _subtle = Color(0xFF9CA3AF);

  bool _isInsideGym = false;
  bool _geoReady    = false;
  List<AttendanceRecord> _history = [];
  AttendanceRecord? _openSession;
  Timer? _sessionTimer;
  Timer? _autoCheckoutTimer;
  StreamSubscription? _geoSub;
  StreamSubscription? _fcmSub;
  StreamSubscription? _sessionSub;
  StreamSubscription? _historySub;
  Duration _elapsed    = Duration.zero;
  String _memberPhone  = '';
  String _membership   = '';
  int    _weekVisits   = 0;
  String _topWorkout   = '';

  @override
  void initState() { super.initState(); _init(); }

  Future<void> _init() async {
    _sessionSub = AttendanceService.openSessionStream(widget.memberId).listen((session) {
      if (!mounted) return;
      setState(() {
        _openSession = session;
        // If there's an open session, reflect inside-gym status immediately
        // without waiting for the first GPS reading
        if (session != null && !_isInsideGym) _isInsideGym = true;
      });
      if (session != null) {
        _startSessionTimer(session.checkedIn);
      } else {
        _sessionTimer?.cancel();
        setState(() => _elapsed = Duration.zero);
      }
    });

    _historySub = AttendanceService.historyStream(widget.memberId).listen((records) {
      if (mounted) setState(() => _history = records);
    });

    await Future.wait([_loadMember(), _loadStats()]);
    await _startGeofence();
    _listenFcm();
  }

  Future<void> _loadMember() async {
    final member = await AttendanceService.getMember(widget.memberId);
    if (member != null && mounted) {
      setState(() {
        _memberPhone = member['phone']          ?? '';
        _membership  = member['membershipType'] ?? '';
      });
    }
  }

  Future<void> _loadStats() async {
    final stats = await AttendanceService.getStats(widget.memberId);
    if (mounted) {
      setState(() {
        _weekVisits = stats['weekVisits'] as int;
        _topWorkout = stats['topWorkout'] as String;
      });
    }
  }

  Future<void> _startGeofence() async {
    final granted = await GeoService.requestPermission();
    if (!granted) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Location permission required for auto attendance'),
          backgroundColor: Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
        ));
      }
      return;
    }
    final gym = await AttendanceService.getGym(widget.gymId);
    if (gym == null) return;
    if (mounted) setState(() => _geoReady = true);
    _geoSub = GeoService.watchGeofence(
      gymLat:       (gym['latitude']     as num).toDouble(),
      gymLng:       (gym['longitude']    as num).toDouble(),
      radiusMeters: (gym['radiusMeters'] as num).toDouble(),
    ).listen(_onGeofenceChange);
  }

  void _onGeofenceChange(bool isInside) async {
    setState(() => _isInsideGym = isInside);
    if (isInside && _openSession == null) {
      await AttendanceService.checkIn(widget.memberId, widget.gymId);
    } else if (!isInside && _openSession != null) {
      await AttendanceService.notifyExit(widget.memberId);
      _startAutoCheckoutTimer();
    }
  }

   void _startSessionTimer(DateTime start) {
    _sessionTimer?.cancel();
    _sessionTimer = Timer.periodic(const Duration(milliseconds: 500), (_) {
      if (mounted) setState(() => _elapsed = DateTime.now().difference(start));
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

  void _listenFcm() {
    _fcmSub = FirebaseService.exitConfirmationStream().listen((_) {
      if (!mounted || _openSession == null) return;
      ExitConfirmationSheet.show(context,
        sessionId: _openSession!.id.isEmpty ? 0 : int.tryParse(_openSession!.id) ?? 0,
        onConfirm: _doCheckout,
        onDeny: () { _autoCheckoutTimer?.cancel(); setState(() => _isInsideGym = true); },
      );
    });
  }

  Future<void> _onRefresh() => Future.wait([_loadMember(), _loadStats()]);

  Future<void> _logout() async {
    await AuthPrefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(context,
        MaterialPageRoute(builder: (_) => const LoginScreen()), (_) => false);
  }

  String _formatElapsed(Duration d) {
    final h = d.inHours.toString().padLeft(2, '0');
    final m = (d.inMinutes % 60).toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$h:$m:$s';
  }

  String _formatDuration(Duration? d) {
    if (d == null) return '—';
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
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
                    _buildStatusCard(),
                    const SizedBox(height: 16),
                    if (_openSession != null) ...[
                      _buildSessionCard(),
                      const SizedBox(height: 16),
                    ],
                    _buildHistorySection(),
                    const SizedBox(height: 100),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
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

  Widget _buildAppBar() {
    final membershipColors = {
      'Basic':   _blue,
      'Premium': const Color(0xFFD97706),
      'VIP':     const Color(0xFF7C3AED),
    };
    final badgeColor = membershipColors[_membership] ?? Colors.transparent;

    return SliverAppBar(
      backgroundColor: _bg,
      floating: true,
      titleSpacing: 20,
      automaticallyImplyLeading: false,
      title: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_blue, _blueDk],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(color: _blue.withOpacity(0.25),
                    blurRadius: 8, offset: const Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.fitness_center, color: Colors.white, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text('Hi, ${widget.memberName.split(' ').first}',
                        style: const TextStyle(
                          color: _ink, fontSize: 16, fontWeight: FontWeight.w700,
                        )),
                    if (_membership.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: badgeColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Text(_membership,
                            style: TextStyle(
                              color: badgeColor, fontSize: 10, fontWeight: FontWeight.w700,
                            )),
                      ),
                    ],
                  ],
                ),
                const Text('Fitness Factor',
                    style: TextStyle(color: _muted, fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
      actions: [
        IconButton(
          icon: const Icon(Icons.bar_chart_outlined, color: _muted),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => StatsScreen(memberId: widget.memberId),
          )),
          tooltip: 'Stats',
        ),
        IconButton(
          icon: const Icon(Icons.settings_outlined, color: _muted),
          onPressed: () => Navigator.push(context, MaterialPageRoute(
            builder: (_) => SettingsScreen(
              memberId:    widget.memberId,
              memberName:  widget.memberName,
              memberPhone: _memberPhone,
              gymId:       widget.gymId,
            ),
          )),
        ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: _muted),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildSummaryRow() {
    return Row(
      children: [
        _summaryChip(
          icon: Icons.calendar_today_outlined,
          label: '$_weekVisits visits this week',
          color: _blue,
        ),
        const SizedBox(width: 8),
        if (_topWorkout.isNotEmpty && _topWorkout != '—')
          _summaryChip(
            icon: Icons.fitness_center_outlined,
            label: _topWorkout,
            color: _green,
          ),
      ],
    );
  }

  Widget _summaryChip({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 5),
          Text(label,
              style: TextStyle(color: color, fontSize: 12, fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildStatusCard() {
    final isIn  = _isInsideGym;
    final color = isIn ? _green : _muted;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.25), width: 1),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 56, height: 56,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isIn ? Icons.location_on : Icons.location_off_outlined,
              color: color, size: 28,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Container(width: 8, height: 8,
                      decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                  const SizedBox(width: 6),
                  Text(
                    isIn ? 'INSIDE GYM' : 'OUTSIDE',
                    style: TextStyle(color: color, fontSize: 13,
                        fontWeight: FontWeight.w700, letterSpacing: 1.2),
                  ),
                ]),
                const SizedBox(height: 4),
                Text(
                  isIn ? 'Session in progress'
                      : _geoReady ? 'Monitoring your location' : 'Waiting for GPS...',
                  style: const TextStyle(color: _muted, fontSize: 14),
                ),
              ],
            ),
          ),
          if (!_geoReady)
            SizedBox(width: 20, height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: _subtle)),
        ],
      ),
    );
  }

  Widget _buildSessionCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _blue.withOpacity(0.35),
            blurRadius: 20, offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.timer_outlined, color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Text('Current Session',
                  style: TextStyle(color: Colors.white70, fontSize: 13,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              if (_openSession?.workoutType?.isNotEmpty == true)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(_openSession!.workoutType!,
                      style: const TextStyle(color: Colors.white, fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _formatElapsed(_elapsed),
            style: const TextStyle(
              color: Colors.white, fontSize: 44,
              fontWeight: FontWeight.w800,
              fontFeatures: [FontFeature.tabularFigures()],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _openSession != null
                ? 'Checked in at ${DateFormat('hh:mm a').format(_openSession!.checkedIn)}'
                : '',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, height: 44,
            child: OutlinedButton.icon(
              onPressed: _doCheckout,
              icon: const Icon(Icons.logout_outlined, size: 18),
              label: const Text('Check Out Now'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.white,
                side: const BorderSide(color: Colors.white60, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHistorySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text('Recent Sessions',
                style: TextStyle(color: _ink, fontSize: 18, fontWeight: FontWeight.w700)),
            const Spacer(),
            if (_history.isNotEmpty)
              GestureDetector(
                onTap: () => Navigator.push(context, MaterialPageRoute(
                  builder: (_) => StatsScreen(memberId: widget.memberId),
                )),
                child: const Text('See Stats →',
                    style: TextStyle(color: _blue, fontSize: 13, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
        const SizedBox(height: 12),
        if (_history.isEmpty)
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: _card,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.04),
                    blurRadius: 12, offset: const Offset(0, 4)),
              ],
            ),
            child: const Center(
              child: Text('No sessions yet',
                  style: TextStyle(color: _subtle, fontSize: 14)),
            ),
          )
        else
          ...(_history.take(10).map(_buildHistoryTile)),
      ],
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
