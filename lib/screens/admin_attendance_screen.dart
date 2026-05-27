// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import 'admin_member_detail_screen.dart';

class AdminAttendanceScreen extends StatefulWidget {
  final String gymId;
  const AdminAttendanceScreen({super.key, required this.gymId});

  @override
  State<AdminAttendanceScreen> createState() => _AdminAttendanceScreenState();
}

class _AdminAttendanceScreenState extends State<AdminAttendanceScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _green = Color(0xFF0A8F69);
  static const _amber = Color(0xFFC7A66A);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _subtle = Color(0xFF7A8582);

  Map<String, dynamic> _data = {
    'records': [],
    'totalVisits': 0,
    'uniqueAttendees': 0,
    'completed': 0,
    'openSessions': 0,
    'missedCheckoutRate': 0.0,
    'avgMinutes': 0,
    'peakHour': 0,
    'repeatMembers7d': 0,
    'repeatMembers30d': 0,
    'hourCounts': List<int>.filled(24, 0),
    'totalMinutes': 0,
  };
  bool _loading = true;
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final d = await AdminService.getDayAttendance(widget.gymId, _selectedDate);
    if (mounted) {
      setState(() {
        _data = d;
        _loading = false;
      });
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.dark(
            primary: _blue,
            onPrimary: _bg,
            surface: _card,
            onSurface: _ink,
          ),
          dialogTheme: const DialogThemeData(backgroundColor: _card),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
      _load();
    }
  }

  String _fmtDur(int m) {
    final h = m ~/ 60;
    final min = m % 60;
    return h > 0 ? '${h}h ${min}m' : '${min}m';
  }

  Future<void> _forceCheckout(String sessionId, String memberName) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Force Checkout',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'Force checkout for $memberName?',
          style: TextStyle(color: _muted),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: _muted)),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Force Checkout',
              style: TextStyle(color: _blue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true) return;
    await AdminService.forceCheckout(sessionId);
    if (!mounted) return;
    _load();
  }

  @override
  Widget build(BuildContext context) {
    final isToday =
        DateFormat('yyyy-MM-dd').format(_selectedDate) ==
        DateFormat('yyyy-MM-dd').format(DateTime.now());
    final records = (_data['records'] as List).cast<Map<String, dynamic>>();

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Attendance Records',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        actions: [
          TextButton.icon(
            onPressed: _pickDate,
            icon: const Icon(
              Icons.calendar_today_outlined,
              color: _blue,
              size: 16,
            ),
            label: Text(
              isToday
                  ? 'Today'
                  : DateFormat('MMM d, yyyy').format(_selectedDate),
              style: const TextStyle(color: _blue, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : records.isEmpty
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.event_busy_outlined, color: _subtle, size: 48),
                  const SizedBox(height: 12),
                  Text(
                    'No attendance on ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
                    style: TextStyle(color: _muted),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _buildDayStats(),
                const SizedBox(height: 16),
                _buildHourlyChart(),
                const SizedBox(height: 16),
                ...records.map(_recordTile),
              ],
            ),
    );
  }

  Widget _buildDayStats() {
    final total = _data['totalVisits'] as int? ?? 0;
    final unique = _data['uniqueAttendees'] as int? ?? 0;
    final completed = _data['completed'] as int? ?? 0;
    final openSessions = _data['openSessions'] as int? ?? 0;
    final avgMin = _data['avgMinutes'] as int? ?? 0;
    final peakHour = _data['peakHour'] as int? ?? -1;
    final repeat7 = _data['repeatMembers7d'] as int? ?? 0;
    final repeat30 = _data['repeatMembers30d'] as int? ?? 0;
    final totalMin = _data['totalMinutes'] as int? ?? 0;
    final missedRate = (_data['missedCheckoutRate'] as num?)?.toDouble() ?? 0;

    final peakStr = peakHour >= 0
        ? DateFormat('ha').format(DateTime(2000, 1, 1, peakHour))
        : '-';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            DateFormat('EEEE, MMMM d yyyy').format(_selectedDate),
            style: const TextStyle(
              color: _ink,
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _dayStat('Total Visits', '$total', _blue),
              _dayStat('Unique', '$unique', _green),
              _dayStat('Completed', '$completed', _green),
              _dayStat('Open', '$openSessions', _amber),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              _dayStat(
                'Avg Duration',
                avgMin == 0 ? '-' : _fmtDur(avgMin),
                _amber,
              ),
              _dayStat('Peak Hour', peakStr, const Color(0xFF535E62)),
              _dayStat('Repeat 7d', '$repeat7', _blue),
              _dayStat('Repeat 30d', '$repeat30', _green),
            ],
          ),
          if (totalMin > 0) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _blue.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.timer_outlined, color: _blue, size: 14),
                  const SizedBox(width: 6),
                  Text(
                    'Total gym time: ${_fmtDur(totalMin)}',
                    style: const TextStyle(
                      color: _blue,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (missedRate > 0) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: _amber.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _amber.withOpacity(0.30)),
              ),
              child: Text(
                'Missed check-out rate: ${(missedRate * 100).toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: _ink,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _dayStat(String label, String value, Color color) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(color: _muted, fontSize: 10),
          ),
        ],
      ),
    );
  }

  Widget _buildHourlyChart() {
    final hourCounts = (_data['hourCounts'] as List).cast<int>();
    // Show only 6am–10pm
    final hours = List.generate(17, (i) => i + 6);
    final maxVal = hours
        .map((h) => hourCounts[h])
        .reduce((a, b) => a > b ? a : b)
        .clamp(1, 9999);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Hourly Traffic (6am \u2013 10pm)',
            style: TextStyle(
              color: _ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 60,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: hours.map((h) {
                final val = hourCounts[h];
                final frac = val / maxVal;
                final isPeak =
                    val == hourCounts.reduce((a, b) => a > b ? a : b) &&
                    val > 0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          height: (frac * 48).clamp(2.0, 48.0),
                          decoration: BoxDecoration(
                            color: isPeak ? _amber : _blue.withOpacity(0.35),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          h % 12 == 0 ? '12' : '${h % 12}',
                          style: TextStyle(color: _subtle, fontSize: 7),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _recordTile(Map<String, dynamic> r) {
    final checkedIn = r['checkedIn'] as DateTime?;
    final checkedOut = r['checkedOut'] as DateTime?;
    final isOpen = checkedOut == null;
    final name = r['memberName'] as String? ?? '-';
    final memberId = r['memberId'] as String? ?? '';
    final sessionId = r['sessionId'] as String? ?? '';
    final checkInMethod =
        ((r['checkInMethod'] as String? ?? 'unknown')
                .replaceAll('_', ' ')
                .trim())
            .toUpperCase();
    final sessionState =
        ((r['sessionState'] as String? ?? 'legacy').replaceAll('_', ' ').trim())
            .toUpperCase();
    final source = (r['source'] as String? ?? 'auto').toUpperCase();
    final workoutType = r['workoutType'] as String? ?? '';

    String durationStr = '-';
    if (checkedIn != null && checkedOut != null) {
      final minutes = checkedOut.difference(checkedIn).inMinutes;
      durationStr = _fmtDur(minutes < 0 ? 0 : minutes);
    }

    return GestureDetector(
      onTap: memberId.isEmpty
          ? null
          : () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AdminMemberDetailScreen(
                  memberId: memberId,
                  gymId: widget.gymId,
                ),
              ),
            ),
      child: Opacity(
        opacity: memberId.isEmpty ? 0.8 : 1.0,
        child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            borderRadius: BorderRadius.circular(14),
            border: isOpen ? Border.all(color: _blue.withOpacity(0.25)) : null,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isOpen
                      ? _blue.withOpacity(0.10)
                      : const Color(0xFFE0E4E2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    name.isNotEmpty ? name[0].toUpperCase() : '?',
                    style: TextStyle(
                      color: isOpen ? _blue : _muted,
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
                    if (checkedIn != null)
                      Text(
                        'IN ${DateFormat('hh:mm a').format(checkedIn)}'
                        '${checkedOut != null ? '  OUT ${DateFormat('hh:mm a').format(checkedOut)}' : '  -> now'}',
                        style: TextStyle(color: _muted, fontSize: 12),
                      ),
                    if (workoutType.isNotEmpty)
                      Text(
                        workoutType,
                        style: TextStyle(color: _subtle, fontSize: 11),
                      ),
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _pill(checkInMethod, _blue),
                        _pill(sessionState, isOpen ? _amber : _green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
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
                    source,
                    style: TextStyle(
                      color: _subtle,
                      fontSize: 9,
                      letterSpacing: 0.8,
                    ),
                  ),
                  if (isOpen && sessionId.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () => _forceCheckout(sessionId, name),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _blue.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _blue.withOpacity(0.25)),
                        ),
                        child: const Text(
                          'Force OUT',
                          style: TextStyle(
                            color: _blue,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 9,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.4,
        ),
      ),
    );
  }
}
