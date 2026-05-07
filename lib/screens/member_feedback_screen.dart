// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class MemberFeedbackScreen extends StatefulWidget {
  final String memberId;
  final String gymId;
  const MemberFeedbackScreen({
    super.key, required this.memberId, required this.gymId,
  });

  @override
  State<MemberFeedbackScreen> createState() => _MemberFeedbackScreenState();
}

class _MemberFeedbackScreenState extends State<MemberFeedbackScreen> {
  static const _blue   = Color(0xFF2563EB);
  static const _blueDk = Color(0xFF1D4ED8);
  static const _green  = Color(0xFF16A34A);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Colors.white;
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);

  final _msgCtrl = TextEditingController();
  String  _category = 'general';
  bool    _loading  = false;
  bool    _sent     = false;

  final _categories = [
    {'value': 'general',     'label': 'General',     'icon': Icons.chat_bubble_outline},
    {'value': 'complaint',   'label': 'Complaint',   'icon': Icons.report_outlined},
    {'value': 'suggestion',  'label': 'Suggestion',  'icon': Icons.lightbulb_outline},
    {'value': 'equipment',   'label': 'Equipment',   'icon': Icons.fitness_center_outlined},
    {'value': 'cleanliness', 'label': 'Cleanliness', 'icon': Icons.cleaning_services_outlined},
  ];

  @override
  void dispose() { _msgCtrl.dispose(); super.dispose(); }

  Future<void> _submit() async {
    if (_msgCtrl.text.trim().isEmpty) return;
    setState(() => _loading = true);
    final ok = await AttendanceService.submitFeedback(
      memberId: widget.memberId,
      gymId:    widget.gymId,
      message:  _msgCtrl.text.trim(),
      category: _category,
    );
    if (!mounted) return;
    setState(() { _loading = false; _sent = ok; });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        foregroundColor: _ink,
        elevation: 0,
        title: const Text('Send Feedback',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
      ),
      body: _sent ? _buildSuccess() : _buildForm(),
    );
  }

  Widget _buildSuccess() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                color: _green.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_outline,
                  color: _green, size: 40),
            ),
            const SizedBox(height: 20),
            const Text('Feedback Sent!',
                style: TextStyle(color: _ink, fontSize: 22,
                    fontWeight: FontWeight.w800)),
            const SizedBox(height: 8),
            Text('Thank you. The gym team will review your feedback.',
                textAlign: TextAlign.center,
                style: TextStyle(color: _muted, fontSize: 14, height: 1.5)),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity, height: 50,
              child: OutlinedButton(
                onPressed: () => Navigator.pop(context),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _blue,
                  side: const BorderSide(color: _blue, width: 1.5),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text('Done',
                    style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionLabel('Category'),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8, runSpacing: 8,
            children: _categories.map((c) {
              final sel = _category == c['value'];
              final color = sel ? _blue : _muted;
              return GestureDetector(
                onTap: () => setState(() => _category = c['value'] as String),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 180),
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: sel ? _blue.withOpacity(0.08) : _card,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: sel ? _blue : Colors.grey.shade200,
                      width: sel ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(c['icon'] as IconData, color: color, size: 15),
                      const SizedBox(width: 6),
                      Text(c['label'] as String,
                          style: TextStyle(color: color, fontSize: 13,
                              fontWeight: sel
                                  ? FontWeight.w700 : FontWeight.w400)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 24),
          _sectionLabel('Message'),
          const SizedBox(height: 10),
          TextField(
            controller: _msgCtrl,
            maxLines: 6,
            style: const TextStyle(color: _ink, fontSize: 15),
            decoration: InputDecoration(
              hintText: 'Describe your feedback or issue in detail...',
              hintStyle: TextStyle(color: _muted.withOpacity(0.5), fontSize: 14),
              filled: true,
              fillColor: _card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: _blue, width: 1.5),
              ),
              contentPadding: const EdgeInsets.all(16),
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity, height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [_blue, _blueDk]),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [BoxShadow(color: _blue.withOpacity(0.35),
                    blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: ElevatedButton(
                onPressed: _loading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                child: _loading
                    ? const SizedBox(width: 22, height: 22,
                        child: CircularProgressIndicator(
                            color: Colors.white, strokeWidth: 2.5))
                    : const Text('Submit Feedback',
                        style: TextStyle(fontWeight: FontWeight.w700,
                            fontSize: 16)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(label.toUpperCase(),
      style: const TextStyle(color: _blue, fontSize: 11,
          fontWeight: FontWeight.w700, letterSpacing: 1.4));
}
