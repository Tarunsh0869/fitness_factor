// ignore_for_file: deprecated_member_use

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/admin_service.dart';

class AdminFeedbackScreen extends StatefulWidget {
  final String gymId;
  const AdminFeedbackScreen({super.key, required this.gymId});

  @override
  State<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends State<AdminFeedbackScreen>
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
  List<Map<String, dynamic>> _all = [];
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    _sub = AdminService.feedbackStream(widget.gymId).listen((list) {
      if (mounted) setState(() => _all = list);
    });
  }

  @override
  void dispose() { _tabs.dispose(); _sub?.cancel(); super.dispose(); }

  List<Map<String, dynamic>> get _open =>
      _all.where((f) => !(f['resolved'] as bool)).toList();
  List<Map<String, dynamic>> get _resolved =>
      _all.where((f) => f['resolved'] as bool).toList();

  Future<void> _resolve(Map<String, dynamic> f) async {
    final noteCtrl = TextEditingController();
    final note = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Resolve Feedback',
            style: TextStyle(color: _ink, fontWeight: FontWeight.w700)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(f['message'] as String? ?? '',
                style: TextStyle(color: _muted, fontSize: 13)),
            const SizedBox(height: 12),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: _ink),
              decoration: InputDecoration(
                hintText: 'Add a note (optional)',
                hintStyle: TextStyle(color: _muted.withOpacity(0.5)),
                filled: true,
                fillColor: const Color(0xFFF3F4F6),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
              child: Text('Cancel', style: TextStyle(color: _muted))),
          TextButton(
            onPressed: () => Navigator.pop(context, noteCtrl.text.trim()),
            child: const Text('Mark Resolved',
                style: TextStyle(color: _green, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
    if (note != null) {
      await AdminService.resolveFeedback(f['id'] as String, note);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: Text('Feedback & Issues (${_open.length} open)',
            style: const TextStyle(fontWeight: FontWeight.w700, color: _ink)),
        bottom: TabBar(
          controller: _tabs,
          labelColor: _blue,
          unselectedLabelColor: _muted,
          indicatorColor: _blue,
          tabs: [
            Tab(text: 'Open (${_open.length})'),
            Tab(text: 'Resolved (${_resolved.length})'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _feedbackList(_open, showResolve: true),
          _feedbackList(_resolved, showResolve: false),
        ],
      ),
    );
  }

  Widget _feedbackList(List<Map<String, dynamic>> items,
      {required bool showResolve}) {
    if (items.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_outlined, color: _subtle, size: 48),
            const SizedBox(height: 12),
            Text(showResolve ? 'No open feedback' : 'No resolved feedback',
                style: TextStyle(color: _muted)),
          ],
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: items.length,
      separatorBuilder: (_, i) => const SizedBox(height: 8),
      itemBuilder: (_, i) => _feedbackTile(items[i], showResolve: showResolve),
    );
  }

  Widget _feedbackTile(Map<String, dynamic> f, {required bool showResolve}) {
    final category  = f['category'] as String? ?? 'general';
    final message   = f['message']  as String? ?? '';
    final name      = f['memberName'] as String? ?? 'Anonymous';
    final createdAt = f['createdAt'] as DateTime?;
    final adminNote = f['adminNote'] as String? ?? '';
    final resolved  = f['resolved'] as bool;

    final catColors = {
      'general':   _blue,
      'complaint': _red,
      'suggestion': _amber,
      'equipment': const Color(0xFF7C3AED),
      'cleanliness': _green,
    };
    final color = catColors[category] ?? _blue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card, borderRadius: BorderRadius.circular(14),
        border: resolved ? null : Border.all(color: color.withOpacity(0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04),
            blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(5),
                ),
                child: Text(category[0].toUpperCase() + category.substring(1),
                    style: TextStyle(color: color, fontSize: 11,
                        fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Text(name, style: const TextStyle(color: _ink, fontSize: 13,
                  fontWeight: FontWeight.w600)),
              const Spacer(),
              if (createdAt != null)
                Text(DateFormat('MMM d, hh:mm a').format(createdAt),
                    style: TextStyle(color: _subtle, fontSize: 11)),
            ],
          ),
          const SizedBox(height: 8),
          Text(message, style: TextStyle(color: _muted, fontSize: 13,
              height: 1.4)),
          if (adminNote.isNotEmpty) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _green.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: _green.withOpacity(0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.admin_panel_settings_outlined,
                      color: _green, size: 14),
                  const SizedBox(width: 6),
                  Expanded(child: Text(adminNote,
                      style: TextStyle(color: _green, fontSize: 12))),
                ],
              ),
            ),
          ],
          if (showResolve) ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: GestureDetector(
                onTap: () => _resolve(f),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _green.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: _green.withOpacity(0.25)),
                  ),
                  child: const Text('Mark Resolved',
                      style: TextStyle(color: _green, fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
