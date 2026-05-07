// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';
import 'admin_member_detail_screen.dart';

class AdminVerificationScreen extends StatefulWidget {
  final String gymId;
  const AdminVerificationScreen({super.key, required this.gymId});

  @override
  State<AdminVerificationScreen> createState() =>
      _AdminVerificationScreenState();
}

class _AdminVerificationScreenState extends State<AdminVerificationScreen>
    with SingleTickerProviderStateMixin {
  static const _blue   = Color(0xFF2563EB);
  static const _green  = Color(0xFF16A34A);
  static const _red    = Color(0xFFEF4444);
  static const _amber  = Color(0xFFD97706);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Colors.white;
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);
  static const _subtle = Color(0xFF9CA3AF);

  late final TabController _tabs;
  List<Map<String, dynamic>> _pending  = [];
  List<Map<String, dynamic>> _all      = [];
  StreamSubscription? _pendingSub;
  StreamSubscription? _allSub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
    _pendingSub = AdminService.pendingVerificationStream(widget.gymId)
        .listen((list) {
      if (mounted) setState(() => _pending = list);
    });
    _allSub = AdminService.membersStream(widget.gymId).listen((list) {
      if (mounted) setState(() => _all = list);
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _pendingSub?.cancel();
    _allSub?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> get _verified =>
      _all.where((m) => m['verificationStatus'] == 'verified').toList();
  List<Map<String, dynamic>> get _rejected =>
      _all.where((m) => m['verificationStatus'] == 'rejected').toList();

  Future<void> _setStatus(String memberId, String status) async {
    await AdminService.updateVerificationStatus(memberId, status);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: Text('Member Verification (${_pending.length} pending)',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _blue,
          unselectedLabelColor: _muted,
          indicatorColor: _blue,
          tabs: [
            Tab(text: 'Pending (${_pending.length})'),
            Tab(text: 'Verified (${_verified.length})'),
            Tab(text: 'Rejected (${_rejected.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _memberList(_pending, showActions: true),
          _memberList(_verified, showActions: false),
          _memberList(_rejected, showActions: false),
        ],
      ),
    );
  }

  Widget _memberList(List<Map<String, dynamic>> members,
      {required bool showActions}) {
    if (members.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.verified_user_outlined, color: _subtle, size: 48),
            const SizedBox(height: 12),
            Text('No members in this category',
                style: TextStyle(color: _muted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: members.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _memberTile(members[i], showActions: showActions),
    );
  }

  Widget _memberTile(Map<String, dynamic> m, {required bool showActions}) {
    final name       = m['name']           as String? ?? '—';
    final phone      = m['phone']          as String? ?? '—';
    final membership = m['membershipType'] as String? ?? 'Basic';
    final gender     = m['gender']         as String? ?? '—';
    final vs         = m['verificationStatus'] as String? ?? 'pending';

    final membershipColors = {
      'Basic':   _blue,
      'Premium': _amber,
      'VIP':     const Color(0xFF7C3AED),
    };
    final mColor = membershipColors[membership] ?? _blue;

    final vsColor = vs == 'verified' ? _green
        : vs == 'rejected' ? _red : _amber;

    // Parse join date
    String joinedStr = '—';
    try {
      final raw = m['createdAt'];
      if (raw != null) {
        final dt = raw is DateTime ? raw
            : DateTime.tryParse(raw.toString());
        if (dt != null) joinedStr = DateFormat('MMM d, yyyy').format(dt);
      }
    } catch (_) {}

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => AdminMemberDetailScreen(
          memberId: m['id'] as String, gymId: widget.gymId,
        ),
      )),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card, borderRadius: BorderRadius.circular(14),
          border: vs == 'pending'
              ? Border.all(color: _amber.withOpacity(0.3)) : null,
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
              blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 44, height: 44,
                  decoration: BoxDecoration(
                    color: mColor.withOpacity(0.10), shape: BoxShape.circle),
                  child: Center(
                    child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: TextStyle(color: mColor, fontSize: 18,
                            fontWeight: FontWeight.w800)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(name, style: const TextStyle(color: _ink,
                          fontSize: 14, fontWeight: FontWeight.w600)),
                      Text(phone,
                          style: TextStyle(color: _muted, fontSize: 12)),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: mColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(membership,
                      style: TextStyle(color: mColor, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _infoChip(Icons.person_outline, gender),
                const SizedBox(width: 8),
                _infoChip(Icons.calendar_today_outlined, 'Joined $joinedStr'),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: vsColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Text(vs[0].toUpperCase() + vs.substring(1),
                      style: TextStyle(color: vsColor, fontSize: 11,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ),
            if (showActions) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setStatus(m['id'] as String, 'verified'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _green.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _green.withOpacity(0.25)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.check_circle_outline,
                                color: _green, size: 16),
                            const SizedBox(width: 6),
                            const Text('Verify',
                                style: TextStyle(color: _green,
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: GestureDetector(
                      onTap: () => _setStatus(m['id'] as String, 'rejected'),
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 9),
                        decoration: BoxDecoration(
                          color: _red.withOpacity(0.06),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: _red.withOpacity(0.2)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.cancel_outlined,
                                color: _red, size: 16),
                            const SizedBox(width: 6),
                            const Text('Reject',
                                style: TextStyle(color: _red,
                                    fontSize: 13, fontWeight: FontWeight.w700)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _infoChip(IconData icon, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: _subtle, size: 12),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(color: _muted, fontSize: 11)),
      ],
    );
  }
}
