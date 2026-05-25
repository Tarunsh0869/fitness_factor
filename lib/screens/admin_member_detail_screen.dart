// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';
import '../services/admin_service.dart';

class AdminMemberDetailScreen extends StatefulWidget {
  final String memberId;
  final String gymId;
  const AdminMemberDetailScreen({
    super.key, required this.memberId, required this.gymId,
  });

  @override
  State<AdminMemberDetailScreen> createState() =>
      _AdminMemberDetailScreenState();
}

class _AdminMemberDetailScreenState extends State<AdminMemberDetailScreen> {
  static const _blue   = Color(0xFF2563EB);
  static const _green  = Color(0xFF16A34A);
  static const _red    = Color(0xFFEF4444);
  static const _amber  = Color(0xFFD97706);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Colors.white;
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);
  static const _subtle = Color(0xFF9CA3AF);

  Map<String, dynamic>? _member;
  Map<String, dynamic>  _stats = {};
  bool _loading = true;

  @override
  void initState() { super.initState(); _load(); }

  Future<void> _load() async {
    final results = await Future.wait([
      AttendanceService.getMember(widget.memberId),
      AttendanceService.getStats(widget.memberId),
    ]);
    if (mounted) {
      setState(() {
        _member  = results[0] as Map<String, dynamic>?; // ignore: unnecessary_cast
        _stats   = (results[1] as Map).cast<String, dynamic>();
        _loading = false;
      });
    }
  }

  Future<void> _toggleActive() async {
    final current = _member?['active'] as bool? ?? true;
    final ok = await AdminService.toggleMemberActive(widget.memberId, !current);
    if (ok && mounted) {
      setState(() => _member = {...?_member, 'active': !current});
    }
  }

  Future<void> _setVerification(String status) async {
    await AdminService.updateVerificationStatus(widget.memberId, status);
    if (mounted) {
      setState(() => _member = {...?_member, 'verificationStatus': status});
    }
  }

  Future<void> _deleteMember() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Delete Member',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        content: Text(
            'Permanently delete ${_member?['name'] ?? 'this member'}? '
            'This cannot be undone.',
            style: TextStyle(color: _muted)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              child: const Text('Delete',
                  style: TextStyle(color: _red, fontWeight: FontWeight.w700))),
        ],
      ),
    );
    if (confirm == true) {
      await AdminService.deleteMember(widget.memberId);
      if (mounted) Navigator.pop(context);
    }
  }

  String _fmtDur(int m) {
    final h = m ~/ 60; final min = m % 60;
    return h > 0 ? '${h}h ${min}m' : '${min}m';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(_member?['name'] ?? 'Member',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        actions: [
          if (_member != null)
            PopupMenuButton<String>(
              color: Colors.white,
              onSelected: (v) {
                if (v == 'toggle') _toggleActive();
                if (v == 'verify') _setVerification('verified');
                if (v == 'reject') _setVerification('rejected');
                if (v == 'pending') _setVerification('pending');
                if (v == 'delete') _deleteMember();
              },
              itemBuilder: (_) {
                final active = _member!['active'] as bool? ?? true;
                final vs = _member!['verificationStatus'] as String? ?? 'pending';
                return [
                  PopupMenuItem(value: 'toggle',
                    child: Row(children: [
                      Icon(active ? Icons.block_outlined : Icons.check_circle_outline,
                          color: active ? _red : _green, size: 18),
                      const SizedBox(width: 8),
                      Text(active ? 'Deactivate' : 'Activate',
                          style: TextStyle(color: active ? _red : _green)),
                    ])),
                  if (vs != 'verified')
                    PopupMenuItem(value: 'verify',
                      child: Row(children: [
                        const Icon(Icons.verified_outlined, color: _green, size: 18),
                        const SizedBox(width: 8),
                        const Text('Mark Verified',
                            style: TextStyle(color: _green)),
                      ])),
                  if (vs != 'rejected')
                    PopupMenuItem(value: 'reject',
                      child: Row(children: [
                        const Icon(Icons.cancel_outlined, color: _red, size: 18),
                        const SizedBox(width: 8),
                        const Text('Reject',
                            style: TextStyle(color: _red)),
                      ])),
                  PopupMenuItem(value: 'delete',
                    child: Row(children: [
                      const Icon(Icons.delete_outline, color: _red, size: 18),
                      const SizedBox(width: 8),
                      const Text('Delete Member',
                          style: TextStyle(color: _red)),
                    ])),
                ];
              },
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(color: _blue))
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildProfileCard(),
                const SizedBox(height: 16),
                _buildStatsRow(),
                const SizedBox(height: 16),
                if ((_stats['typeCount'] as Map).isNotEmpty) ...[
                  _buildWorkoutBreakdown(),
                  const SizedBox(height: 16),
                ],
                _buildAttendanceHistory(),
              ],
            ),
    );
  }

  Widget _buildProfileCard() {
    final name       = _member?['name']           as String? ?? '—';
    final membership = _member?['membershipType'] as String? ?? 'Basic';
    final active     = _member?['active']         as bool?   ?? true;
    final vs         = _member?['verificationStatus'] as String? ?? 'pending';
    final lastSeen   = _stats['lastSeen'] as DateTime?;

    final membershipColors = {
      'Basic':   _blue,
      'Premium': _amber,
      'VIP':     const Color(0xFF7C3AED),
    };
    final color = membershipColors[membership] ?? _blue;

    final vsColor = vs == 'verified' ? _green
        : vs == 'rejected' ? _red : _amber;
    final vsIcon  = vs == 'verified' ? Icons.verified_outlined
        : vs == 'rejected' ? Icons.cancel_outlined
        : Icons.pending_outlined;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05),
            blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 60, height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [color, color.withOpacity(0.6)],
                    begin: Alignment.topLeft, end: Alignment.bottomRight,
                  ),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: const TextStyle(color: Colors.white, fontSize: 26,
                          fontWeight: FontWeight.w800)),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name, style: const TextStyle(color: _ink, fontSize: 18,
                        fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(_member?['phone'] as String? ?? '—',
                        style: TextStyle(color: _muted, fontSize: 13)),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      children: [
                        _badge(membership, color),
                        _badge(active ? 'Active' : 'Inactive',
                            active ? _green : _red),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(vsIcon, color: vsColor, size: 12),
                            const SizedBox(width: 3),
                            Text(vs[0].toUpperCase() + vs.substring(1),
                                style: TextStyle(color: vsColor, fontSize: 11,
                                    fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (lastSeen != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.access_time_outlined, color: _muted, size: 14),
                  const SizedBox(width: 6),
                  Text('Last seen: ${DateFormat('EEE, MMM d · hh:mm a').format(lastSeen)}',
                      style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Text(label, style: TextStyle(color: color, fontSize: 11,
          fontWeight: FontWeight.w700)),
    );
  }

  Widget _buildStatsRow() {
    final total    = _stats['total']    as int;
    final avgMin   = _stats['avgMin']   as int;
    final maxMin   = _stats['maxMin']   as int;
    final last30   = _stats['last30']   as int;
    final streak   = _stats['streak']   as int;
    final totalMin = _stats['totalMin'] as int;

    return Column(
      children: [
        Row(children: [
          _statBox('Total Sessions', '$total', _blue),
          const SizedBox(width: 10),
          _statBox('Last 30 Days', '$last30', _green),
          const SizedBox(width: 10),
          _statBox('Streak', '$streak days', streak >= 3 ? _green : _muted),
        ]),
        const SizedBox(height: 10),
        Row(children: [
          _statBox('Avg Session', avgMin == 0 ? '\u2014' : _fmtDur(avgMin), _amber),
          const SizedBox(width: 10),
          _statBox('Longest', maxMin == 0 ? '\u2014' : _fmtDur(maxMin),
              const Color(0xFF7C3AED)),
          const SizedBox(width: 10),
          _statBox('Total Hours', totalMin == 0 ? '\u2014' : _fmtDur(totalMin),
              const Color(0xFF0891B2)),
        ]),
      ],
    );
  }

  Widget _statBox(String label, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.15)),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
              blurRadius: 6, offset: const Offset(0, 2))],
        ),
        child: Column(
          children: [
            Text(value, style: TextStyle(color: color, fontSize: 16,
                fontWeight: FontWeight.w800)),
            const SizedBox(height: 3),
            Text(label, textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 10)),
          ],
        ),
      ),
    );
  }

  Widget _buildWorkoutBreakdown() {
    final typeCount = (_stats['typeCount'] as Map).cast<String, int>();
    final sorted = typeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final total = sorted.fold<int>(0, (s, e) => s + e.value);
    final colors = [_blue, _green, _red, _amber,
        const Color(0xFF7C3AED), const Color(0xFF0891B2)];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(16),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 10, offset: const Offset(0, 3))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Workout Breakdown',
              style: TextStyle(color: _ink, fontSize: 14,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...sorted.asMap().entries.map((entry) {
            final color = colors[entry.key % colors.length];
            final e     = entry.value;
            final pct   = (e.value / total * 100).round();
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Column(
                children: [
                  Row(children: [
                    Container(width: 8, height: 8,
                        decoration: BoxDecoration(
                            color: color, shape: BoxShape.circle)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(e.key,
                        style: const TextStyle(color: _ink, fontSize: 13))),
                    Text('${e.value}x',
                        style: TextStyle(color: color, fontSize: 13,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(width: 8),
                    Text('$pct%',
                        style: TextStyle(color: _muted, fontSize: 12)),
                  ]),
                  const SizedBox(height: 5),
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

  Widget _buildAttendanceHistory() {
    final records = (_stats['records'] as List).cast<AttendanceRecord>();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Attendance History (${records.length})',
            style: const TextStyle(color: _ink, fontSize: 15,
                fontWeight: FontWeight.w700)),
        const SizedBox(height: 12),
        if (records.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(color: _card,
                borderRadius: BorderRadius.circular(14)),
            child: Center(child: Text('No attendance records',
                style: TextStyle(color: _subtle))),
          )
        else
          ...records.map(_historyTile),
      ],
    );
  }

  Widget _historyTile(AttendanceRecord r) {
    final isOpen   = r.isOpen;
    final duration = r.duration;
    final durStr   = duration == null ? '\u2014' : _fmtDur(duration.inMinutes);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(12),
        border: isOpen ? Border.all(color: _blue.withOpacity(0.25)) : null,
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03),
            blurRadius: 6, offset: const Offset(0, 2))],
      ),
      child: Row(
        children: [
          Icon(isOpen ? Icons.play_circle_outline : Icons.check_circle_outline,
              color: isOpen ? _blue : _subtle, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(DateFormat('EEE, MMM d yyyy').format(r.checkedIn),
                    style: const TextStyle(color: _ink, fontSize: 13,
                        fontWeight: FontWeight.w600)),
                Text(
                  'IN ${DateFormat('hh:mm a').format(r.checkedIn)}'
                  '${r.checkedOut != null ? '  OUT ${DateFormat('hh:mm a').format(r.checkedOut!)}' : '  \u2192 now'}',
                  style: TextStyle(color: _muted, fontSize: 11),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(durStr, style: const TextStyle(color: _ink,
                  fontSize: 13, fontWeight: FontWeight.w700)),
              Text(r.source.toUpperCase(),
                  style: TextStyle(color: _subtle, fontSize: 9,
                      letterSpacing: 0.8)),
            ],
          ),
        ],
      ),
    );
  }
}
