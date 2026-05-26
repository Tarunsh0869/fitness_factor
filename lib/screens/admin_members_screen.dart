// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import '../services/admin_service.dart';
import 'admin_member_detail_screen.dart';

class AdminMembersScreen extends StatefulWidget {
  final String gymId;
  const AdminMembersScreen({super.key, required this.gymId});

  @override
  State<AdminMembersScreen> createState() => _AdminMembersScreenState();
}

class _AdminMembersScreenState extends State<AdminMembersScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _green = Color(0xFF0A8F69);
  static const _red = Color(0xFFB3261E);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);

  List<Map<String, dynamic>> _all = [];
  List<Map<String, dynamic>> _filtered = [];
  StreamSubscription? _sub;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _sub = AdminService.membersStream(widget.gymId).listen((list) {
      if (mounted) {
        setState(() {
          _all = list;
          _filtered = _applyFilter(list, _query);
        });
      }
    });
  }

  List<Map<String, dynamic>> _applyFilter(
    List<Map<String, dynamic>> list,
    String q,
  ) {
    if (q.isEmpty) return list;
    final lower = q.toLowerCase();
    return list
        .where(
          (m) =>
              (m['name'] as String? ?? '').toLowerCase().contains(lower) ||
              (m['phone'] as String? ?? '').contains(lower),
        )
        .toList();
  }

  void _onSearch(String q) {
    setState(() {
      _query = q;
      _filtered = _applyFilter(_all, q);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: Text(
          'Members (${_all.length})',
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
            child: TextField(
              onChanged: _onSearch,
              style: const TextStyle(color: _ink),
              decoration: InputDecoration(
                hintText: 'Search by name or phone...',
                hintStyle: TextStyle(color: _muted.withOpacity(0.6)),
                prefixIcon: const Icon(Icons.search, color: _blue, size: 20),
                filled: true,
                fillColor: _card,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: const Color(0xFFC3C8C6)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: BorderSide(color: const Color(0xFFC3C8C6)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(18),
                  borderSide: const BorderSide(color: _blue, width: 1.5),
                ),
              ),
            ),
          ),
        ),
      ),
      body: _filtered.isEmpty
          ? Center(
              child: Text(
                _query.isEmpty
                    ? 'No members found'
                    : 'No results for "$_query"',
                style: TextStyle(color: _muted),
              ),
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: _filtered.length,
              separatorBuilder: (context, i) => const SizedBox(height: 8),
              itemBuilder: (_, i) => _memberTile(_filtered[i]),
            ),
    );
  }

  Widget _memberTile(Map<String, dynamic> m) {
    final name = m['name'] as String? ?? '—';
    final phone = m['phone'] as String? ?? '—';
    final membership = m['membershipType'] as String? ?? 'Basic';
    final active = m['active'] as bool? ?? true;

    final membershipColors = {
      'Basic': _blue,
      'Premium': const Color(0xFFC7A66A),
      'VIP': const Color(0xFF535E62),
    };
    final mColor = membershipColors[membership] ?? _blue;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) =>
              AdminMemberDetailScreen(memberId: m['id'], gymId: widget.gymId),
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: active ? null : Border.all(color: _red.withOpacity(0.2)),
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
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: active
                    ? mColor.withOpacity(0.10)
                    : const Color(0xFFE0E4E2),
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: active ? mColor : _muted,
                    fontSize: 18,
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
                  Row(
                    children: [
                      Text(
                        name,
                        style: TextStyle(
                          color: active ? _ink : _muted,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      if (!active) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: _red.withOpacity(0.08),
                            borderRadius: BorderRadius.circular(4),
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
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(phone, style: TextStyle(color: _muted, fontSize: 12)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: mColor.withOpacity(0.10),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    membership,
                    style: TextStyle(
                      color: mColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Switch.adaptive(
                  value: active,
                  activeColor: _green,
                  onChanged: (val) =>
                      AdminService.toggleMemberActive(m['id'], val),
                  materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
