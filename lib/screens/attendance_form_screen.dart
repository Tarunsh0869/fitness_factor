// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/attendance_record.dart';
import '../services/attendance_service.dart';

class AttendanceFormScreen extends StatefulWidget {
  final String memberId;
  final String gymId;
  final AttendanceRecord? existing;

  const AttendanceFormScreen({
    super.key,
    required this.memberId,
    required this.gymId,
    this.existing,
  });

  @override
  State<AttendanceFormScreen> createState() => _AttendanceFormScreenState();
}

class _AttendanceFormScreenState extends State<AttendanceFormScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _red = Color(0xFFB3261E);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);

  final _notesCtrl = TextEditingController();
  String _workoutType = 'General';
  DateTime _checkedIn = DateTime.now();
  DateTime? _checkedOut;
  bool _loading = false;
  bool get _isEdit => widget.existing != null;

  final _workoutTypes = [
    {'label': 'General', 'icon': Icons.fitness_center},
    {'label': 'Cardio', 'icon': Icons.directions_run},
    {'label': 'Weights', 'icon': Icons.sports_gymnastics},
    {'label': 'CrossFit', 'icon': Icons.bolt},
    {'label': 'Yoga', 'icon': Icons.self_improvement},
    {'label': 'Swimming', 'icon': Icons.pool},
    {'label': 'Cycling', 'icon': Icons.directions_bike},
    {'label': 'HIIT', 'icon': Icons.local_fire_department},
  ];

  @override
  void initState() {
    super.initState();
    if (_isEdit) {
      _workoutType = widget.existing!.workoutType?.isNotEmpty == true
          ? widget.existing!.workoutType!
          : 'General';
      _notesCtrl.text = widget.existing!.notes ?? '';
      _checkedIn = widget.existing!.checkedIn;
      _checkedOut = widget.existing!.checkedOut;
    }
  }

  @override
  void dispose() {
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime({required bool isCheckIn}) async {
    final initial = isCheckIn ? _checkedIn : (_checkedOut ?? DateTime.now());
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
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
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
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
    if (time == null || !mounted) return;
    final picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    setState(() {
      if (isCheckIn) {
        _checkedIn = picked;
      } else {
        _checkedOut = picked;
      }
    });
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    bool success;
    if (_isEdit) {
      success = await AttendanceService.updateAttendanceForm(
        sessionId: widget.existing!.id,
        workoutType: _workoutType,
        notes: _notesCtrl.text.trim(),
        checkedOut: _checkedOut,
      );
    } else {
      final id = await AttendanceService.manualCheckIn(
        memberId: widget.memberId,
        gymId: widget.gymId,
        workoutType: _workoutType,
        notes: _notesCtrl.text.trim(),
        checkedIn: _checkedIn,
      );
      success = id != null;
    }
    if (!mounted) return;
    setState(() => _loading = false);
    if (success) {
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_isEdit ? 'Attendance updated' : 'Attendance recorded'),
          backgroundColor: _blue,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed — you may already have an open session'),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _delete() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: _card,
        title: const Text(
          'Delete Record',
          style: TextStyle(color: _ink, fontWeight: FontWeight.w700),
        ),
        content: Text(
          'This attendance record will be permanently deleted.',
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
              'Delete',
              style: TextStyle(color: _red, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;
    setState(() => _loading = true);
    await AttendanceService.deleteAttendance(widget.existing!.id);
    if (!mounted) return;
    Navigator.pop(context, true);
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
          _isEdit ? 'Edit Attendance' : 'Log Attendance',
          style: const TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        actions: [
          if (_isEdit)
            IconButton(
              icon: const Icon(Icons.delete_outline, color: _red),
              onPressed: _loading ? null : _delete,
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionLabel('Workout Type'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _workoutTypes.map((w) {
                final sel = _workoutType == w['label'];
                return GestureDetector(
                  onTap: () =>
                      setState(() => _workoutType = w['label'] as String),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: sel ? _blue.withOpacity(0.08) : _card,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: sel ? _blue : const Color(0xFFC3C8C6),
                        width: sel ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          w['icon'] as IconData,
                          color: sel ? _blue : _muted,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          w['label'] as String,
                          style: TextStyle(
                            color: sel ? _blue : _muted,
                            fontSize: 13,
                            fontWeight: sel ? FontWeight.w700 : FontWeight.w400,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 28),
            _sectionLabel('Check-in Time'),
            const SizedBox(height: 10),
            _timeTile(
              icon: Icons.login_outlined,
              label: DateFormat('EEE, MMM d • hh:mm a').format(_checkedIn),
              color: _blue,
              onTap: () => _pickDateTime(isCheckIn: true),
            ),
            const SizedBox(height: 12),
            _sectionLabel('Check-out Time'),
            const SizedBox(height: 10),
            _timeTile(
              icon: Icons.logout_outlined,
              label: _checkedOut != null
                  ? DateFormat('EEE, MMM d • hh:mm a').format(_checkedOut!)
                  : 'Tap to set check-out time',
              color: _checkedOut != null ? _red : _muted,
              onTap: () => _pickDateTime(isCheckIn: false),
              trailing: _checkedOut != null
                  ? GestureDetector(
                      onTap: () => setState(() => _checkedOut = null),
                      child: Icon(Icons.close, color: _muted, size: 18),
                    )
                  : null,
            ),
            if (_checkedOut != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: _blue.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: _blue, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      _formatDuration(_checkedOut!.difference(_checkedIn)),
                      style: const TextStyle(
                        color: _blue,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 28),
            _sectionLabel('Notes (optional)'),
            const SizedBox(height: 10),
            TextField(
              controller: _notesCtrl,
              maxLines: 4,
              style: const TextStyle(color: _ink, fontSize: 15),
              decoration: InputDecoration(
                hintText: 'e.g. Leg day, felt great. PR on squats...',
                hintStyle: TextStyle(
                  color: _muted.withOpacity(0.5),
                  fontSize: 14,
                ),
                filled: true,
                fillColor: _card,
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
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 36),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [_blue, _blueDk]),
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: _blue.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.transparent,
                    shadowColor: Colors.transparent,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(18),
                    ),
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          _isEdit ? 'Save Changes' : 'Log Attendance',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Text(
    label.toUpperCase(),
    style: const TextStyle(
      color: _blue,
      fontSize: 11,
      fontWeight: FontWeight.w700,
      letterSpacing: 1.4,
    ),
  );

  Widget _timeTile({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: color.withOpacity(0.3), width: 1),
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
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            trailing ??
                Icon(
                  Icons.edit_outlined,
                  color: color.withOpacity(0.5),
                  size: 16,
                ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration d) {
    final h = d.inHours;
    final m = d.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}
