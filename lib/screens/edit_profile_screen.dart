// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String memberId;
  final String initialName;
  final String initialEmergency;
  final String initialMembership;

  const EditProfileScreen({
    super.key,
    required this.memberId,
    required this.initialName,
    required this.initialEmergency,
    required this.initialMembership,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _blue   = Color(0xFF2563EB);
  static const _blueDk = Color(0xFF1D4ED8);
  static const _red    = Color(0xFFEF4444);
  static const _bg     = Color(0xFFF0F4FF);
  static const _card   = Colors.white;
  static const _ink    = Color(0xFF111827);
  static const _muted  = Color(0xFF6B7280);

  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl  = TextEditingController(text: widget.initialName);
  late final _emergCtrl = TextEditingController(text: widget.initialEmergency);
  late String _membership = widget.initialMembership;
  bool    _loading = false;
  String? _error;

  final _memberships = ['Basic', 'Premium', 'VIP'];

  @override
  void dispose() { _nameCtrl.dispose(); _emergCtrl.dispose(); super.dispose(); }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() { _loading = true; _error = null; });
    final ok = await AttendanceService.updateProfile(
      memberId:         widget.memberId,
      name:             _nameCtrl.text.trim(),
      emergencyContact: _emergCtrl.text.trim(),
      membershipType:   _membership,
    );
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) {
      Navigator.pop(context, {
        'name':             _nameCtrl.text.trim(),
        'emergencyContact': _emergCtrl.text.trim(),
        'membershipType':   _membership,
      });
    } else {
      setState(() => _error = 'Failed to save. Please try again.');
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
        title: const Text('Edit Profile',
            style: TextStyle(fontWeight: FontWeight.w700, color: _ink)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _sectionLabel('Personal'),
              const SizedBox(height: 12),
              _field(controller: _nameCtrl, label: 'Full Name',
                  icon: Icons.person_outline,
                  validator: (v) => v!.trim().isEmpty ? 'Name is required' : null),
              const SizedBox(height: 12),
              _field(controller: _emergCtrl, label: 'Emergency Contact',
                  icon: Icons.emergency_outlined,
                  keyboardType: TextInputType.phone,
                  validator: (v) => v!.trim().isEmpty
                      ? 'Emergency contact is required' : null),
              const SizedBox(height: 28),
              _sectionLabel('Membership Plan'),
              const SizedBox(height: 12),
              ..._memberships.map(_membershipTile),
              if (_error != null) ...[
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _red.withOpacity(0.25)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: _red, size: 18),
                      const SizedBox(width: 8),
                      Expanded(child: Text(_error!,
                          style: const TextStyle(color: _red, fontSize: 13))),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 36),
              SizedBox(
                width: double.infinity, height: 54,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [_blue, _blueDk]),
                    borderRadius: BorderRadius.circular(14),
                    boxShadow: [
                      BoxShadow(color: _blue.withOpacity(0.35),
                          blurRadius: 16, offset: const Offset(0, 6)),
                    ],
                  ),
                  child: ElevatedButton(
                    onPressed: _loading ? null : _save,
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
                        : const Text('Save Changes',
                            style: TextStyle(fontWeight: FontWeight.w700,
                                fontSize: 16)),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionLabel(String label) => Padding(
    padding: const EdgeInsets.only(bottom: 4),
    child: Text(label.toUpperCase(),
        style: const TextStyle(color: _blue, fontSize: 11,
            fontWeight: FontWeight.w700, letterSpacing: 1.4)),
  );

  Widget _field({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: const TextStyle(color: _ink, fontSize: 15),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: TextStyle(color: _muted),
        prefixIcon: Icon(icon, color: _blue, size: 20),
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
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _red),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
      ),
    );
  }

  Widget _membershipTile(String type) {
    final sel = _membership == type;
    final details = {
      'Basic':   {'price': 'RM 80 / month',  'icon': Icons.star_outline},
      'Premium': {'price': 'RM 150 / month', 'icon': Icons.star_half},
      'VIP':     {'price': 'RM 250 / month', 'icon': Icons.star},
    };
    final d = details[type]!;
    return GestureDetector(
      onTap: () => setState(() => _membership = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: sel ? _blue.withOpacity(0.06) : _card,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: sel ? _blue : Colors.grey.shade200,
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(d['icon'] as IconData,
                color: sel ? _blue : _muted, size: 20),
            const SizedBox(width: 12),
            Expanded(child: Text(type,
                style: TextStyle(
                  color: sel ? _ink : _muted,
                  fontSize: 15, fontWeight: FontWeight.w600,
                ))),
            Text(d['price'] as String,
                style: TextStyle(
                  color: sel ? _blue : _muted,
                  fontSize: 13, fontWeight: FontWeight.w600,
                )),
            const SizedBox(width: 10),
            Container(
              width: 20, height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: sel ? _blue : Colors.transparent,
                border: Border.all(
                    color: sel ? _blue : Colors.grey.shade300, width: 2),
              ),
              child: sel
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
