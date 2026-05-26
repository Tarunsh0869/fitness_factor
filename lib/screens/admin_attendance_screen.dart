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
    'completed': 0,
    'avgMinutes': 0,
    'peakHour': 0,
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
    if (mounted)
      setState(() {
        _data = d;
        _loading = false;
      });
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
    final total = _data['totalVisits'] as int;
    final completed = _data['completed'] as int;
    final avgMin = _data['avgMinutes'] as int;
    final peakHour = _data['peakHour'] as int;
    final totalMin = _data['totalMinutes'] as int;

    final peakStr = peakHour == 0
        ? '—'
        : DateFormat('ha').format(DateTime(2000, 1, 1, peakHour));

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
              _dayStat('Completed', '$completed', _green),
              _dayStat(
                'Avg Duration',
                avgMin == 0 ? '\u2014' : _fmtDur(avgMin),
                _amber,
              ),
              _dayStat('Peak Hour', peakStr, const Color(0xFF535E62)),
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
    final name = r['memberName'] as String? ?? '—';

    String durationStr = '\u2014';
    if (checkedIn != null && checkedOut != null) {
      durationStr = _fmtDur(checkedOut.difference(checkedIn).inMinutes);
    }

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AdminMemberDetailScreen(
            memberId: r['memberId'] as String,
            gymId: widget.gymId,
          ),
        ),
      ),
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
                      '${checkedOut != null ? '  OUT ${DateFormat('hh:mm a').format(checkedOut)}' : '  \u2192 now'}',
                      style: TextStyle(color: _muted, fontSize: 12),
                    ),
                  if ((r['workoutType'] as String).isNotEmpty)
                    Text(
                      r['workoutType'],
                      style: TextStyle(color: _subtle, fontSize: 11),
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
                  (r['source'] as String).toUpperCase(),
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
      ),
    );
  }
}
