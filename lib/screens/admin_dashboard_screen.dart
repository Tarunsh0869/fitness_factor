// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import '../services/auth_prefs.dart';
import 'login_screen.dart';
import 'admin_members_screen.dart';
import 'admin_attendance_screen.dart';
import 'admin_gym_settings_screen.dart';
import 'admin_feedback_screen.dart';
import 'admin_verification_screen.dart';

class AdminDashboardScreen extends StatefulWidget {
  final String gymId;
  const AdminDashboardScreen({super.key, required this.gymId});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _green = Color(0xFF0A8F69);
  static const _red = Color(0xFFB3261E);
  static const _amber = Color(0xFFC7A66A);
  static const _purple = Color(0xFF535E62);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _subtle = Color(0xFF7A8582);

  Map<String, dynamic> _stats = {
    'totalMembers': 0,
    'insideNow': 0,
    'todayVisits': 0,
    'monthVisits': 0,
    'weekVisits': 0,
    'pendingVerify': 0,
    'openFeedback': 0,
  };
  List<Map<String, dynamic>> _insideNow = [];
  List<Map<String, dynamic>> _todayFeed = [];
  List<int> _weeklyOccupancy = List.filled(7, 0);
  String _headerTime = '';
  String _headerDate = '';
  Timer? _clockTimer;

  StreamSubscription? _insideSub;
  StreamSubscription? _todaySub;
  Timer? _statsTimer;
  bool _statsLoading = true;

  @override
  void initState() {
    super.initState();
    _updateClock();
    _clockTimer = Timer.periodic(
      const Duration(seconds: 1),
      (_) => _updateClock(),
    );
    _loadAll();
    _statsTimer = Timer.periodic(const Duration(minutes: 2), (_) => _loadAll());
    _insideSub = AdminService.insideNowStream(widget.gymId).listen((list) {
      if (mounted) setState(() => _insideNow = list);
    });
    _todaySub = AdminService.todayAttendanceStream(widget.gymId).listen((list) {
      if (mounted) setState(() => _todayFeed = list);
    });
  }

  void _updateClock() {
    final now = DateTime.now();
    setState(() {
      _headerTime = DateFormat('hh:mm:ss a').format(now);
      _headerDate = DateFormat('EEE, MMM d · yyyy').format(now);
    });
  }

  Future<void> _loadAll() async {
    final results = await Future.wait([
      AdminService.getGymStats(widget.gymId),
      AdminService.getWeeklyOccupancy(widget.gymId),
    ]);
    if (mounted) {
      setState(() {
        _stats = results[0] as Map<String, dynamic>;
        _weeklyOccupancy = results[1] as List<int>;
        _statsLoading = false;
      });
    }
  }

  Future<void> _logout() async {
    await AuthPrefs.clear();
    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const LoginScreen()),
      (_) => false,
    );
  }

  Future<void> _forceCheckout(String sessionId, String name) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Force Checkout',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        content: Text('Check out $name now?', style: TextStyle(color: _muted)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Check Out',
              style: TextStyle(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm == true) await AdminService.forceCheckout(sessionId);
  }

  void _showAlertPicker(BuildContext ctx, int pendingV, int openFeed) {
    showModalBottomSheet(
      context: ctx,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 24),
            const Text(
              'Notifications',
              style: TextStyle(
                color: _ink,
                fontSize: 20,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$pendingV pending · $openFeed open feedback',
              style: const TextStyle(color: _muted, fontSize: 13),
            ),
            const SizedBox(height: 20),
            _alertActionTile(
              icon: Icons.verified_user_outlined,
              label: 'Verify Members',
              subtitle: '$pendingV pending',
              color: _amber,
              onTap: () => _navigateVerification(ctx, context),
            ),
            const SizedBox(height: 8),
            _alertActionTile(
              icon: Icons.feedback_outlined,
              label: 'Review Feedback',
              subtitle: '$openFeed open',
              color: _blue,
              onTap: () => _navigateFeedback(ctx, context),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  void _navigateVerification(BuildContext from, BuildContext ctx) {
    Navigator.pop(ctx);
    Navigator.push(
      from,
      MaterialPageRoute(
        builder: (_) => AdminVerificationScreen(gymId: widget.gymId),
      ),
    );
  }

  void _navigateFeedback(BuildContext from, BuildContext ctx) {
    Navigator.pop(ctx);
    Navigator.push(
      from,
      MaterialPageRoute(
        builder: (_) => AdminFeedbackScreen(gymId: widget.gymId),
      ),
    );
  }

  Widget _alertActionTile({
    required IconData icon,
    required String label,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.05),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      color: color,
                      fontSize: 15,
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
            Icon(
              Icons.chevron_right_outlined,
              color: color.withOpacity(0.5),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _clockTimer?.cancel();
    _insideSub?.cancel();
    _todaySub?.cancel();
    _statsTimer?.cancel();
    super.dispose();
  }

  String _fmtDur(int minutes) {
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _loadAll,
          color: _blue,
          backgroundColor: _card,
          child: CustomScrollView(
            slivers: [
              _buildAppBar(),
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 20),
                sliver: SliverList(
                  delegate: SliverChildListDelegate([
                    const SizedBox(height: 8),
                    if (!_statsLoading) ...[
                      _buildAlertBanner(),
                      const SizedBox(height: 16),
                    ],
                    _buildStatsGrid(),
                    const SizedBox(height: 20),
                    _buildOccupancyChart(),
                    const SizedBox(height: 20),
                    _buildQuickActions(),
                    const SizedBox(height: 20),
                    _buildInsideNow(),
                    const SizedBox(height: 20),
                    _buildTodayFeed(),
                    const SizedBox(height: 40),
                  ]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppBar() {
    final alerts =
        (_stats['pendingVerify'] as int) + (_stats['openFeedback'] as int);
    return SliverAppBar(
      backgroundColor: _bg,
      floating: true,
      automaticallyImplyLeading: false,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [_blue, _blueDk]),
              borderRadius: BorderRadius.circular(11),
              boxShadow: [
                BoxShadow(
                  color: _blue.withOpacity(0.25),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: const Icon(
              Icons.admin_panel_settings_outlined,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Admin Dashboard',
                style: TextStyle(
                  color: _ink,
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Row(
                children: [
                  Icon(Icons.access_time_outlined, color: _muted, size: 10),
                  const SizedBox(width: 4),
                  Text(
                    _headerTime.isEmpty && _headerDate.isEmpty
                        ? DateFormat('h:mm a').format(DateTime.now())
                        : '$_headerTime · $_headerDate',
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
      actions: [
        if (alerts > 0)
          Stack(
            children: [
              IconButton(
                icon: const Icon(Icons.notifications_outlined, color: _muted),
                onPressed: () {
                  final pendingV = _stats['pendingVerify'] as int;
                  final openFeed = _stats['openFeedback'] as int;
                  if (pendingV > 0 && openFeed > 0) {
                    _showAlertPicker(context, pendingV, openFeed);
                  } else if (pendingV > 0) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminVerificationScreen(gymId: widget.gymId),
                      ),
                    );
                  } else {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminFeedbackScreen(gymId: widget.gymId),
                      ),
                    );
                  }
                },
              ),
              Positioned(
                right: 8,
                top: 8,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: const BoxDecoration(
                    color: _red,
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(
                      '$alerts',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        IconButton(
          icon: const Icon(Icons.logout_outlined, color: _muted),
          onPressed: _logout,
        ),
      ],
    );
  }

  Widget _buildAlertBanner() {
    final pending = _stats['pendingVerify'] as int;
    final feedback = _stats['openFeedback'] as int;
    if (pending == 0 && feedback == 0) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _amber.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _amber.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_outlined, color: _amber, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (pending > 0)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminVerificationScreen(gymId: widget.gymId),
                      ),
                    ),
                    child: Text(
                      '$pending member${pending > 1 ? 's' : ''} pending verification  →',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                if (feedback > 0)
                  GestureDetector(
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) =>
                            AdminFeedbackScreen(gymId: widget.gymId),
                      ),
                    ),
                    child: Text(
                      '$feedback open feedback item${feedback > 1 ? 's' : ''}  →',
                      style: const TextStyle(
                        color: _amber,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid() {
    if (_statsLoading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: CircularProgressIndicator(color: _blue),
        ),
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Total Members',
                '${_stats['totalMembers']}',
                Icons.people_outline,
                _blue,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Inside Now',
                '${_stats['insideNow']}',
                Icons.location_on_outlined,
                _green,
                highlight: (_stats['insideNow'] as int) > 0,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'Today',
                '${_stats['todayVisits']}',
                Icons.today_outlined,
                _purple,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'This Week',
                '${_stats['weekVisits']}',
                Icons.date_range_outlined,
                _amber,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _statCard(
                'This Month',
                '${_stats['monthVisits']}',
                Icons.calendar_month_outlined,
                const Color(0xFF035C4A),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _statCard(
                'Pending Verify',
                '${_stats['pendingVerify']}',
                Icons.verified_user_outlined,
                _red,
                highlight: (_stats['pendingVerify'] as int) > 0,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _statCard(
    String label,
    String value,
    IconData icon,
    Color color, {
    bool highlight = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: highlight ? color.withOpacity(0.08) : _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(highlight ? 0.3 : 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: color,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(label, style: TextStyle(color: _muted, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOccupancyChart() {
    final days = ['6d', '5d', '4d', '3d', '2d', 'Yest', 'Today'];
    final maxVal = _weeklyOccupancy.isEmpty
        ? 1
        : _weeklyOccupancy.reduce((a, b) => a > b ? a : b).clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                'Weekly Occupancy',
                style: TextStyle(
                  color: _ink,
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  '${_weeklyOccupancy.last} today',
                  style: const TextStyle(
                    color: _blue,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 90,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val = _weeklyOccupancy[i];
                final frac = val / maxVal;
                final isToday = i == 6;
                final color = isToday ? _blue : _blue.withOpacity(0.3);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text(
                            '$val',
                            style: TextStyle(
                              color: isToday ? _blue : _muted,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: (frac * 64).clamp(4.0, 64.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          days[i],
                          style: TextStyle(
                            color: isToday ? _ink : _muted,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActions() {
    final actions = [
      _DashboardAction(
        icon: Icons.people_outline,
        label: 'Members',
        color: _blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminMembersScreen(gymId: widget.gymId),
          ),
        ),
      ),
      _DashboardAction(
        icon: Icons.fact_check_outlined,
        label: 'Attendance',
        color: _purple,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminAttendanceScreen(gymId: widget.gymId),
          ),
        ),
      ),
      _DashboardAction(
        icon: Icons.verified_user_outlined,
        label: 'Verify',
        color: _green,
        badge: _stats['pendingVerify'] as int,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminVerificationScreen(gymId: widget.gymId),
          ),
        ),
      ),
      _DashboardAction(
        icon: Icons.feedback_outlined,
        label: 'Feedback',
        color: _amber,
        badge: _stats['openFeedback'] as int,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminFeedbackScreen(gymId: widget.gymId),
          ),
        ),
      ),
      _DashboardAction(
        icon: Icons.settings_outlined,
        label: 'Gym Setup',
        color: _blue,
        onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminGymSettingsScreen(gymId: widget.gymId),
          ),
        ),
      ),
      _DashboardAction(
        icon: Icons.bar_chart_outlined,
        label: 'Reports',
        color: _purple,
        onTap: () => ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Reports feature coming soon')),
        ),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Manage',
          style: TextStyle(
            color: _ink,
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 12),
        Column(
          children: List.generate(actions.length, (index) {
            final action = actions[index];
            return Padding(
              padding: EdgeInsets.only(
                bottom: index == actions.length - 1 ? 0 : 10,
              ),
              child: _actionCard(
                action.icon,
                action.label,
                action.color,
                action.onTap,
                badge: action.badge,
              ),
            );
          }),
        ),
      ],
    );
  }

  Widget _actionCard(
    IconData icon,
    String label,
    Color color,
    VoidCallback onTap, {
    int badge = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        constraints: const BoxConstraints(minHeight: 62),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.16)),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.07),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 21),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            if (badge > 0) ...[
              Container(
                constraints: const BoxConstraints(minWidth: 22, minHeight: 22),
                padding: const EdgeInsets.symmetric(horizontal: 7),
                decoration: BoxDecoration(
                  color: _red,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Center(
                  child: Text(
                    '$badge',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
            ],
            Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: color.withOpacity(0.08),
                borderRadius: BorderRadius.circular(9),
              ),
              child: Icon(Icons.chevron_right_outlined, color: color, size: 19),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInsideNow() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: _green,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Inside Now (${_insideNow.length})',
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (_insideNow.isEmpty)
          _emptyCard('No one is currently inside the gym')
        else
          ..._insideNow.map(_insideTile),
      ],
    );
  }

  Widget _insideTile(Map<String, dynamic> s) {
    final name = s['memberName'] as String? ?? '';
    final checkedIn = s['checkedIn'] as DateTime;
    final elapsed = DateTime.now().difference(checkedIn);
    final workout = s['workoutType'] as String? ?? '';
    final elapsedStr = _fmtDur(elapsed.inMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _green.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: _green,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'IN ${DateFormat('hh:mm a').format(checkedIn)} · $elapsedStr'
                  '${workout.isNotEmpty ? ' · $workout' : ''}',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _forceCheckout(s['sessionId'] as String, name),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _red.withOpacity(0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _red.withOpacity(0.2)),
              ),
              child: const Text(
                'OUT',
                style: TextStyle(
                  color: _red,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayFeed() {
    // Compute today's avg duration
    final closed = _todayFeed.where((s) => s['checkedOut'] != null).toList();
    int totalMin = 0;
    for (final s in closed) {
      final ci = s['checkedIn'] as DateTime;
      final co = s['checkedOut'] as DateTime;
      totalMin += co.difference(ci).inMinutes;
    }
    final avgStr = closed.isEmpty ? '—' : _fmtDur(totalMin ~/ closed.length);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              "Today's Visits (${_todayFeed.length})",
              style: const TextStyle(
                color: _ink,
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            GestureDetector(
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => AdminAttendanceScreen(gymId: widget.gymId),
                ),
              ),
              child: const Text(
                'View All \u2192',
                style: TextStyle(
                  color: _blue,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
        if (closed.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              _miniStat('Avg Duration', avgStr, _blue),
              const SizedBox(width: 8),
              _miniStat('Completed', '${closed.length}', _green),
              const SizedBox(width: 8),
              _miniStat('Active', '${_insideNow.length}', _amber),
            ],
          ),
        ],
        const SizedBox(height: 12),
        if (_todayFeed.isEmpty)
          _emptyCard('No visits recorded today yet')
        else
          ..._todayFeed.take(10).map(_todayTile),
      ],
    );
  }

  Widget _miniStat(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.15)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                color: color,
                fontSize: 15,
                fontWeight: FontWeight.w800,
              ),
            ),
            Text(label, style: TextStyle(color: _muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _todayTile(Map<String, dynamic> s) {
    final checkedIn = s['checkedIn'] as DateTime;
    final checkedOut = s['checkedOut'] as DateTime?;
    final isOpen = checkedOut == null;
    final duration = checkedOut?.difference(checkedIn);
    final durationStr = duration == null
        ? '\u2014'
        : _fmtDur(duration.inMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        border: isOpen ? Border.all(color: _blue.withOpacity(0.25)) : null,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isOpen ? _blue.withOpacity(0.10) : const Color(0xFFE0E4E2),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(
              isOpen ? Icons.play_circle_outline : Icons.check_circle_outline,
              color: isOpen ? _blue : _subtle,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  s['memberName'] as String? ?? '',
                  style: const TextStyle(
                    color: _ink,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  'IN ${DateFormat('hh:mm a').format(checkedIn)}'
                  '${checkedOut != null ? '  OUT ${DateFormat('hh:mm a').format(checkedOut)}' : '  \u2192 now'}',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                durationStr,
                style: const TextStyle(
                  color: _ink,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                (s['source'] as String).toUpperCase(),
                style: TextStyle(
                  color: _subtle,
                  fontSize: 9,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _emptyCard(String msg) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Center(
        child: Text(msg, style: TextStyle(color: _subtle, fontSize: 13)),
      ),
    );
  }
}

class _DashboardAction {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final int badge;

  const _DashboardAction({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.badge = 0,
  });
}
