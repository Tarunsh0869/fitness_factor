// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';
import '../services/attendance_service.dart';

class EditProfileScreen extends StatefulWidget {
  final String memberId;
  final Map<String, dynamic> initialProfile;

  const EditProfileScreen({
    super.key,
    required this.memberId,
    required this.initialProfile,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  static const _blue = Color(0xFF035C4A);
  static const _blueDk = Color(0xFF02473A);
  static const _red = Color(0xFFB3261E);
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _outline = Color(0xFFC3C8C6);

  static const _memberships = ['Free', 'Premium', 'VIP'];
  static const _goals = [
    'Lose weight',
    'Build muscle',
    'Stay fit',
    'Move daily',
  ];
  static const _activityLevels = ['Low', 'Moderate', 'Active'];
  static const _experienceLevels = ['Beginner', 'Intermediate', 'Advanced'];
  static const _preferenceOptions = [
    'Home workouts',
    'Gym workouts',
    'Short sessions',
    'Nutrition tips',
    'Daily reminders',
  ];

  final _formKey = GlobalKey<FormState>();
  late final _nameCtrl = TextEditingController();
  late final _emergCtrl = TextEditingController();
  late final _weightCtrl = TextEditingController();
  late final _heightCtrl = TextEditingController();

  late String _membership;
  String? _goal;
  String? _activityLevel;
  String? _experienceLevel;
  final Set<String> _preferences = <String>{};

  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.initialProfile;
    _nameCtrl.text = (p['name'] as String? ?? '').trim();
    _emergCtrl.text = (p['emergencyContact'] as String? ?? '').trim();

    final membership = (p['membershipType'] as String? ?? 'Free').trim();
    _membership = _memberships.contains(membership) ? membership : 'Free';

    _goal = _fromOptions(p['goal'], _goals);
    _activityLevel = _fromOptions(p['activityLevel'], _activityLevels);
    _experienceLevel = _fromOptions(p['experienceLevel'], _experienceLevels);

    final bodyMetrics = p['bodyMetrics'] as Map<String, dynamic>?;
    _weightCtrl.text = _numToText(bodyMetrics?['weightKg']);
    _heightCtrl.text = _numToText(bodyMetrics?['heightCm']);

    final prefMap = p['preferences'] as Map<String, dynamic>?;
    final tags = prefMap?['tags'];
    if (tags is List) {
      for (final item in tags) {
        final value = item.toString().trim();
        if (_preferenceOptions.contains(value)) {
          _preferences.add(value);
        }
      }
    }
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emergCtrl.dispose();
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  String? _fromOptions(dynamic raw, List<String> options) {
    final value = (raw as String? ?? '').trim();
    if (value.isEmpty) return null;
    return options.contains(value) ? value : null;
  }

  String _numToText(dynamic value) {
    if (value is num) {
      final number = value.toDouble();
      if (number == number.roundToDouble()) {
        return number.toInt().toString();
      }
      return number.toString();
    }
    return '';
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final weightInput = _weightCtrl.text.trim();
    final heightInput = _heightCtrl.text.trim();
    double? weightKg;
    double? heightCm;

    if (weightInput.isNotEmpty) {
      weightKg = double.tryParse(weightInput);
      if (weightKg == null) {
        setState(() => _error = 'Weight must be a valid number.');
        return;
      }
    }
    if (heightInput.isNotEmpty) {
      heightCm = double.tryParse(heightInput);
      if (heightCm == null) {
        setState(() => _error = 'Height must be a valid number.');
        return;
      }
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    final sortedPreferences = _preferences.toList()..sort();
    final ok = await AttendanceService.updateProfile(
      memberId: widget.memberId,
      name: _nameCtrl.text.trim(),
      emergencyContact: _emergCtrl.text.trim(),
      membershipType: _membership,
      goal: _goal,
      activityLevel: _activityLevel,
      experienceLevel: _experienceLevel ?? '',
      weightKg: weightKg,
      heightCm: heightCm,
      preferences: sortedPreferences,
      overwriteBodyMetrics: true,
      overwritePreferences: true,
    );
    if (!mounted) return;
    setState(() => _loading = false);

    if (ok) {
      Navigator.pop(context, {
        'name': _nameCtrl.text.trim(),
        'emergencyContact': _emergCtrl.text.trim(),
        'membershipType': _membership,
        'goal': _goal ?? '',
        'activityLevel': _activityLevel ?? '',
        'experienceLevel': _experienceLevel ?? '',
        'bodyMetrics': {'weightKg': weightKg, 'heightCm': heightCm},
        'preferences': {'tags': sortedPreferences},
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
        title: const Text(
          'Edit Profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
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
              _field(
                controller: _nameCtrl,
                label: 'Full Name',
                icon: Icons.person_outline,
                validator: (v) => v!.trim().isEmpty ? 'Name is required' : null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _emergCtrl,
                label: 'Emergency Contact',
                icon: Icons.emergency_outlined,
                keyboardType: TextInputType.phone,
                validator: (v) =>
                    v!.trim().isEmpty ? 'Emergency contact is required' : null,
              ),
              const SizedBox(height: 28),

              _sectionLabel('Membership Plan'),
              const SizedBox(height: 12),
              ..._memberships.map(_membershipTile),
              const SizedBox(height: 28),

              _sectionLabel('Fitness Profile'),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Goal',
                icon: Icons.flag_outlined,
                value: _goal,
                items: _goals,
                validator: (v) => v == null ? 'Goal is required' : null,
                onChanged: (v) => setState(() => _goal = v),
              ),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Activity Level',
                icon: Icons.directions_run_outlined,
                value: _activityLevel,
                items: _activityLevels,
                validator: (v) =>
                    v == null ? 'Activity level is required' : null,
                onChanged: (v) => setState(() => _activityLevel = v),
              ),
              const SizedBox(height: 12),
              _dropdownField(
                label: 'Experience Level',
                icon: Icons.trending_up_outlined,
                hintText: 'Optional',
                value: _experienceLevel,
                items: _experienceLevels,
                onChanged: (v) => setState(() => _experienceLevel = v),
              ),
              if (_experienceLevel != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: TextButton(
                    onPressed: () => setState(() => _experienceLevel = null),
                    child: const Text('Clear experience level'),
                  ),
                ),
              const SizedBox(height: 12),
              _field(
                controller: _weightCtrl,
                label: 'Weight (kg)',
                icon: Icons.monitor_weight_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (_) => null,
              ),
              const SizedBox(height: 12),
              _field(
                controller: _heightCtrl,
                label: 'Height (cm)',
                icon: Icons.height_outlined,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                validator: (_) => null,
              ),
              const SizedBox(height: 14),
              Text(
                'Preferences',
                style: TextStyle(
                  color: _muted,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _preferenceOptions.map(_preferenceChip).toList(),
              ),

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
                      Expanded(
                        child: Text(
                          _error!,
                          style: const TextStyle(color: _red, fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
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
                    onPressed: _loading ? null : _save,
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
                        : const Text(
                            'Save Changes',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
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
    child: Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: _blue,
        fontSize: 11,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.4,
      ),
    ),
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
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _dropdownField({
    required String label,
    required IconData icon,
    required List<String> items,
    required String? value,
    required ValueChanged<String?> onChanged,
    String? hintText,
    String? Function(String?)? validator,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      isExpanded: true,
      onChanged: onChanged,
      validator: validator,
      iconEnabledColor: _muted,
      dropdownColor: _card,
      style: const TextStyle(color: _ink, fontSize: 15),
      items: items
          .map(
            (item) => DropdownMenuItem<String>(
              value: item,
              child: Text(item, overflow: TextOverflow.ellipsis),
            ),
          )
          .toList(),
      decoration: InputDecoration(
        labelText: label,
        hintText: hintText,
        labelStyle: TextStyle(color: _muted),
        hintStyle: TextStyle(color: _muted.withOpacity(0.6)),
        prefixIcon: Icon(icon, color: _blue, size: 20),
        filled: true,
        fillColor: _card,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _outline),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _outline),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _blue, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: const BorderSide(color: _red, width: 1.5),
        ),
        errorStyle: const TextStyle(color: _red),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
      ),
    );
  }

  Widget _preferenceChip(String label) {
    final selected = _preferences.contains(label);
    return GestureDetector(
      onTap: () {
        setState(() {
          if (selected) {
            _preferences.remove(label);
          } else {
            _preferences.add(label);
          }
        });
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.08) : _card,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFC3C8C6),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? _blue : _muted,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }

  Widget _membershipTile(String type) {
    final selected = _membership == type;
    final details = {
      'Free': {'price': 'RM 0 / month', 'icon': Icons.star_outline},
      'Premium': {'price': 'RM 150 / month', 'icon': Icons.star_half},
      'VIP': {'price': 'RM 250 / month', 'icon': Icons.star},
    };
    final detail = details[type]!;
    return GestureDetector(
      onTap: () => setState(() => _membership = type),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? _blue.withOpacity(0.06) : _card,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? _blue : const Color(0xFFC3C8C6),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              detail['icon'] as IconData,
              color: selected ? _blue : _muted,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                type,
                style: TextStyle(
                  color: selected ? _ink : _muted,
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            Text(
              detail['price'] as String,
              style: TextStyle(
                color: selected ? _blue : _muted,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(width: 10),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? _blue : Colors.transparent,
                border: Border.all(
                  color: selected ? _blue : const Color(0xFF334155),
                  width: 2,
                ),
              ),
              child: selected
                  ? const Icon(Icons.check, color: Colors.white, size: 12)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
