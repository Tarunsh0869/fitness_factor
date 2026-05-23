// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class StatsScreen extends StatefulWidget {
  final String memberId;
  const StatsScreen({super.key, required this.memberId});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen> {
  static const _blue  = Color(0xFF00E5FF);
  static const _green = Color(0xFF39FF14);
  static const _red   = Color(0xFFFF2D75);
  static const _bg    = Color(0xFF05070D);
  static const _card  = Color(0xFF101827);
  static const _ink   = Color(0xFFF8FAFC);
  static const _muted = Color(0xFF94A3B8);

  Map<String, dynamic>? _stats;
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    setState(() => _loading = true);
    final s = await AttendanceService.getStats(widget.memberId);
    if (mounted) setState(() { _stats = s; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('My Stats',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh_outlined, color: _muted),
            onPressed: _load,
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : RefreshIndicator(
              onRefresh: _load,
              color: _blue,
              backgroundColor: _card,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 32),
                children: [
                  _buildTopRow(),
                  const SizedBox(height: 16),
                  _buildStreakCard(),
                  const SizedBox(height: 16),
                  _buildBarChart(),
                  const SizedBox(height: 16),
                  _buildTimeCard(),
                  const SizedBox(height: 16),
                  _buildWorkoutBreakdown(),
                ],
              ),
            ),
    );
  }

  Widget _buildTopRow() {
    final s = _stats!;
    return Row(
      children: [
        Expanded(child: _statCard(
          icon: Icons.calendar_month_outlined,
          label: 'This Month',
          value: '${s['monthVisits']}',
          unit: 'visits',
          color: _blue,
        )),
        const SizedBox(width: 12),
        Expanded(child: _statCard(
          icon: Icons.date_range_outlined,
          label: 'This Week',
          value: '${s['weekVisits']}',
          unit: 'visits',
          color: _green,
        )),
      ],
    );
  }

  Widget _statCard({
    required IconData icon,
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.15)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36, height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 12),
          Text(value,
              style: TextStyle(color: color, fontSize: 32,
                  fontWeight: FontWeight.w800)),
          Text(unit, style: TextStyle(color: _muted, fontSize: 12)),
          const SizedBox(height: 2),
          Text(label, style: TextStyle(color: _muted, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildStreakCard() {
    final streak = _stats!['streak'] as int;
    final color  = streak >= 3 ? _green : (streak >= 1 ? _blue : _muted);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.local_fire_department, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Current Streak',
                    style: TextStyle(color: _muted, fontSize: 13)),
                const SizedBox(height: 2),
                RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: '$streak',
                          style: TextStyle(color: color, fontSize: 28,
                              fontWeight: FontWeight.w800)),
                      TextSpan(
                          text: '  day${streak == 1 ? '' : 's'} in a row',
                          style: TextStyle(color: _muted, fontSize: 14)),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (streak >= 7)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.10),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('🔥 On fire!',
                  style: TextStyle(color: _green, fontSize: 12,
                      fontWeight: FontWeight.w700)),
            ),
        ],
      ),
    );
  }

  Widget _buildBarChart() {
    final daily  = (_stats!['dailyVisits'] as List).cast<int>();
    final maxVal = daily.reduce((a, b) => a > b ? a : b).clamp(1, 999);
    final days   = ['6d', '5d', '4d', '3d', '2d', 'Yest', 'Today'];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Last 7 Days',
              style: const TextStyle(color: _ink, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 20),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final val     = daily[i];
                final frac    = val / maxVal;
                final isToday = i == 6;
                final color   = isToday ? _blue : _blue.withOpacity(0.3);
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        if (val > 0)
                          Text('$val',
                              style: TextStyle(
                                color: isToday ? _blue : _muted,
                                fontSize: 10, fontWeight: FontWeight.w700,
                              )),
                        const SizedBox(height: 3),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOut,
                          height: (frac * 72).clamp(4.0, 72.0),
                          decoration: BoxDecoration(
                            color: color,
                            borderRadius: BorderRadius.circular(5),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(days[i],
                            style: TextStyle(
                              color: isToday ? _ink : _muted,
                              fontSize: 9,
                            )),
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

  Widget _buildTimeCard() {
    final s        = _stats!;
    final totalMin = s['totalMinutes'] as int;
    final weekMin  = s['weekMinutes']  as int;
    final avgMin   = s['avgMinutes']   as int;

    String fmtTime(int m) {
      final h = m ~/ 60; final min = m % 60;
      return h > 0 ? '${h}h ${min}m' : '${min}m';
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Time Spent',
              style: TextStyle(color: _ink, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(child: _timeStat('This Month', fmtTime(totalMin), _blue)),
              const SizedBox(width: 12),
              Expanded(child: _timeStat('This Week',  fmtTime(weekMin),  _green)),
              const SizedBox(width: 12),
              Expanded(child: _timeStat('Avg Session', fmtTime(avgMin),  _red)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _timeStat(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.15)),
      ),
      child: Column(
        children: [
          Text(value,
              style: TextStyle(color: color, fontSize: 16,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 4),
          Text(label,
              textAlign: TextAlign.center,
              style: TextStyle(color: _muted, fontSize: 10)),
        ],
      ),
    );
  }

  Widget _buildWorkoutBreakdown() {
    final typeCount = (_stats!['typeCount'] as Map).cast<String, int>();
    if (typeCount.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Center(child: Text('No workout data yet',
            style: TextStyle(color: _muted, fontSize: 14))),
      );
    }

    final sorted = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total  = sorted.fold<int>(0, (s, e) => s + e.value);
    final colors = [_blue, _green, _red, const Color(0xFFFFD166),
                    const Color(0xFFB967FF), const Color(0xFF00F5D4),
                    const Color(0xFFFF2D75), const Color(0xFF00F5D4)];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workout Breakdown',
              style: TextStyle(color: _ink, fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          ...sorted.asMap().entries.map((entry) {
            final i     = entry.key;
            final e     = entry.value;
            final color = colors[i % colors.length];
            final pct   = (e.value / total * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(width: 8, height: 8,
                          decoration: BoxDecoration(
                              color: color, shape: BoxShape.circle)),
                      const SizedBox(width: 8),
                      Expanded(child: Text(e.key,
                          style: TextStyle(color: _ink, fontSize: 13))),
                      Text('${e.value}x',
                          style: TextStyle(color: color, fontSize: 13,
                              fontWeight: FontWeight.w700)),
                      const SizedBox(width: 8),
                      Text('$pct%',
                          style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: e.value / total,
                      backgroundColor: color.withOpacity(0.10),
                      valueColor: AlwaysStoppedAnimation(color),
                      minHeight: 5,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
