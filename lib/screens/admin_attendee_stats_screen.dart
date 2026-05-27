// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/admin_service.dart';
import 'admin_member_detail_screen.dart';

enum _SortMode { visits30, visits7, streak, avgDuration, lastSeen }

class AdminAttendeeStatsScreen extends StatefulWidget {
  final String gymId;
  const AdminAttendeeStatsScreen({super.key, required this.gymId});

  @override
  State<AdminAttendeeStatsScreen> createState() =>
      _AdminAttendeeStatsScreenState();
}

class _AdminAttendeeStatsScreenState extends State<AdminAttendeeStatsScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _green = Color(0xFF0A8F69);
  static const _red = Color(0xFFB3261E);
  static const _amber = Color(0xFFC7A66A);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);

  final _searchCtrl = TextEditingController();

  List<Map<String, dynamic>> _insights = const [];
  bool _loading = true;
  String _query = '';
  bool _onlyActive = false;
  _SortMode _sortMode = _SortMode.visits30;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final insights = await AdminService.getMemberAttendanceInsights(
      widget.gymId,
    );
    if (!mounted) return;
    setState(() {
      _insights = insights;
      _loading = false;
    });
  }

  List<Map<String, dynamic>> get _visibleMembers {
    final query = _query.trim().toLowerCase();
    final filtered = _insights.where((member) {
      if (_onlyActive && member['active'] != true) return false;
      if (query.isEmpty) return true;
      final name = (member['name'] as String? ?? '').toLowerCase();
      final phone = (member['phone'] as String? ?? '').toLowerCase();
      final membership = (member['membershipType'] as String? ?? '')
          .toLowerCase();
      return name.contains(query) ||
          phone.contains(query) ||
          membership.contains(query);
    }).toList();

    filtered.sort((a, b) {
      switch (_sortMode) {
        case _SortMode.visits30:
          final byVisits30 = (b['visits30'] as int).compareTo(
            a['visits30'] as int,
          );
          if (byVisits30 != 0) return byVisits30;
          return (b['visits7'] as int).compareTo(a['visits7'] as int);
        case _SortMode.visits7:
          final byVisits7 = (b['visits7'] as int).compareTo(
            a['visits7'] as int,
          );
          if (byVisits7 != 0) return byVisits7;
          return (b['visits30'] as int).compareTo(a['visits30'] as int);
        case _SortMode.streak:
          final byStreak = (b['streakDays'] as int).compareTo(
            a['streakDays'] as int,
          );
          if (byStreak != 0) return byStreak;
          return (b['visits30'] as int).compareTo(a['visits30'] as int);
        case _SortMode.avgDuration:
          final byAvg = (b['avgMinutes30'] as int).compareTo(
            a['avgMinutes30'] as int,
          );
          if (byAvg != 0) return byAvg;
          return (b['totalMinutes30'] as int).compareTo(
            a['totalMinutes30'] as int,
          );
        case _SortMode.lastSeen:
          final aLast = a['lastSeen'] as DateTime?;
          final bLast = b['lastSeen'] as DateTime?;
          if (aLast == null && bLast == null) return 0;
          if (aLast == null) return 1;
          if (bLast == null) return -1;
          return bLast.compareTo(aLast);
      }
    });

    return filtered;
  }

  String _fmtDur(int minutes) {
    if (minutes <= 0) return '-';
    final h = minutes ~/ 60;
    final m = minutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }

  String _fmtLastSeen(DateTime? value) {
    if (value == null) return 'No visits in last 30d';
    final now = DateTime.now();
    final dateOnly = DateTime(value.year, value.month, value.day);
    final nowOnly = DateTime(now.year, now.month, now.day);
    final days = nowOnly.difference(dateOnly).inDays;
    if (days == 0) {
      return 'Last seen today ${DateFormat('h:mm a').format(value)}';
    }
    if (days == 1) {
      return 'Last seen yesterday ${DateFormat('h:mm a').format(value)}';
    }
    return 'Last seen ${DateFormat('MMM d, h:mm a').format(value)}';
  }

  @override
  Widget build(BuildContext context) {
    final members = _visibleMembers;

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text(
          'Attendee Stats',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh_outlined),
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                children: [
                  _searchBar(),
                  const SizedBox(height: 12),
                  _summaryCards(),
                  const SizedBox(height: 12),
                  _sortChips(),
                  const SizedBox(height: 12),
                  if (members.isEmpty)
                    _emptyCard()
                  else
                    ...members.map(_memberTile),
                ],
              ),
            ),
    );
  }

  Widget _searchBar() {
    return Container(
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFC3C8C6)),
      ),
      child: TextField(
        controller: _searchCtrl,
        onChanged: (value) => setState(() => _query = value),
        style: const TextStyle(color: _ink),
        decoration: InputDecoration(
          hintText: 'Search member by name, phone, or plan',
          hintStyle: TextStyle(color: _muted.withOpacity(0.65)),
          prefixIcon: const Icon(Icons.search, color: _blue, size: 20),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          suffixIcon: _query.isEmpty
              ? null
              : IconButton(
                  icon: const Icon(Icons.close, size: 18, color: _muted),
                  onPressed: () {
                    _searchCtrl.clear();
                    setState(() => _query = '');
                  },
                ),
        ),
      ),
    );
  }

  Widget _summaryCards() {
    final total = _insights.length;
    final active = _insights.where((m) => m['active'] == true).length;
    final visited7 = _insights.where((m) => (m['visits7'] as int) > 0).length;
    final noVisit7 = _insights
        .where((m) => m['active'] == true && (m['visits7'] as int) == 0)
        .length;
    final openNow = _insights.where((m) => m['openSession'] == true).length;

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _summaryCard('Members', '$total', _blue)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Active', '$active', _green)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Visited 7d', '$visited7', _amber)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _summaryCard('No Visit 7d', '$noVisit7', _red)),
            const SizedBox(width: 10),
            Expanded(child: _summaryCard('Open Now', '$openNow', _blue)),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
                decoration: BoxDecoration(
                  color: _card,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: _blue.withOpacity(0.2)),
                ),
                child: FilterChip(
                  selected: _onlyActive,
                  onSelected: (selected) {
                    setState(() => _onlyActive = selected);
                  },
                  backgroundColor: _card,
                  selectedColor: _blue.withOpacity(0.14),
                  checkmarkColor: _blue,
                  label: const Text('Only Active'),
                  labelStyle: TextStyle(
                    color: _onlyActive ? _blue : _muted,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(color: _blue.withOpacity(0.25)),
                  visualDensity: VisualDensity.compact,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _summaryCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: const TextStyle(color: _muted, fontSize: 10),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _sortChips() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _sortChip('Visits 30d', _SortMode.visits30),
        _sortChip('Visits 7d', _SortMode.visits7),
        _sortChip('Streak', _SortMode.streak),
        _sortChip('Avg Duration', _SortMode.avgDuration),
        _sortChip('Last Seen', _SortMode.lastSeen),
      ],
    );
  }

  Widget _sortChip(String label, _SortMode mode) {
    final selected = _sortMode == mode;
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => setState(() => _sortMode = mode),
      backgroundColor: _card,
      selectedColor: _blue.withOpacity(0.16),
      side: BorderSide(color: selected ? _blue : _muted.withOpacity(0.2)),
      labelStyle: TextStyle(
        color: selected ? _blue : _muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _memberTile(Map<String, dynamic> member) {
    final memberId = member['id'] as String;
    final name = member['name'] as String? ?? 'Member';
    final phone = member['phone'] as String? ?? '-';
    final membership = member['membershipType'] as String? ?? 'Basic';
    final visits7 = member['visits7'] as int? ?? 0;
    final visits30 = member['visits30'] as int? ?? 0;
    final streak = member['streakDays'] as int? ?? 0;
    final avgMinutes = member['avgMinutes30'] as int? ?? 0;
    final totalMinutes = member['totalMinutes30'] as int? ?? 0;
    final openSession = member['openSession'] == true;
    final lastSeen = member['lastSeen'] as DateTime?;
    final active = member['active'] == true;
    final verification = member['verificationStatus'] as String? ?? 'pending';

    final membershipColor = membership == 'Premium'
        ? _amber
        : membership == 'VIP'
        ? _muted
        : _blue;
    final verificationColor = verification == 'verified'
        ? _green
        : verification == 'rejected'
        ? _red
        : _amber;

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AdminMemberDetailScreen(
              memberId: memberId,
              gymId: widget.gymId,
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: openSession
                ? _green.withOpacity(0.35)
                : const Color(0xFFC3C8C6).withOpacity(0.65),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: membershipColor.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: membershipColor,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name,
                          style: TextStyle(
                            color: active ? _ink : _muted,
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (!active)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: const Text(
                            'Inactive',
                            style: TextStyle(
                              color: _red,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    phone,
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  const SizedBox(height: 6),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: [
                      _chip(membership, membershipColor),
                      _chip(verification, verificationColor),
                      if (openSession) _chip('inside now', _green),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Visits: $visits7 (7d) / $visits30 (30d)',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  Text(
                    'Avg: ${_fmtDur(avgMinutes)}  Total: ${_fmtDur(totalMinutes)}  Streak: $streak d',
                    style: const TextStyle(color: _muted, fontSize: 12),
                  ),
                  Text(
                    _fmtLastSeen(lastSeen),
                    style: const TextStyle(color: _muted, fontSize: 11),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(7),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  Widget _emptyCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: _card,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Text(
        'No attendee data found for this filter.',
        style: TextStyle(color: _muted),
        textAlign: TextAlign.center,
      ),
    );
  }
}
