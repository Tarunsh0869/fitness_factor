import 'package:flutter/material.dart';

import '../services/attendance_service.dart';
import 'home_screen.dart';

class CompleteProfileScreen extends StatefulWidget {
  final String memberId;
  final String memberName;
  final String gymId;

  const CompleteProfileScreen({
    super.key,
    required this.memberId,
    required this.memberName,
    required this.gymId,
  });

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen> {
  static const _bg = Color(0xFFF9F7F2);
  static const _card = Color(0xFFF3F2ED);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _danger = Color(0xFFB3261E);

  final _weightCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();

  int _step = 0;
  String? _goal;
  String? _activityLevel;
  String? _experienceLevel;
  final Set<String> _preferences = <String>{};
  bool _saving = false;
  String? _error;

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

  int get _totalSteps => 5;

  @override
  void dispose() {
    _weightCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  bool get _canContinue {
    if (_step == 0) return _goal != null;
    if (_step == 1) return _activityLevel != null;
    return true;
  }

  bool get _isOptionalStep => _step >= 2;

  void _next() {
    if (!_canContinue) return;
    if (_step < _totalSteps - 1) {
      setState(() => _step += 1);
      return;
    }
    _saveProfile();
  }

  void _skip() {
    if (!_isOptionalStep || _step >= _totalSteps - 1) return;
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0) return;
    setState(() => _step -= 1);
  }

  Future<void> _saveProfile() async {
    if (_goal == null || _activityLevel == null) {
      setState(() => _error = 'Goal and activity level are required.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final weight = double.tryParse(_weightCtrl.text.trim());
    final height = double.tryParse(_heightCtrl.text.trim());
    final ok = await AttendanceService.completeProfile(
      memberId: widget.memberId,
      goal: _goal!,
      activityLevel: _activityLevel!,
      experienceLevel: _experienceLevel,
      weightKg: weight,
      heightCm: height,
      preferences: _preferences.toList(),
    );

    if (!mounted) return;
    setState(() => _saving = false);

    if (!ok) {
      setState(() => _error = 'Could not save profile. Please try again.');
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (_) => HomeScreen(
          memberId: widget.memberId,
          memberName: widget.memberName,
          gymId: widget.gymId,
        ),
      ),
      (_) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final progress = (_step + 1) / _totalSteps;
    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _bg,
        elevation: 0,
        foregroundColor: _ink,
        title: const Text(
          'Complete Your Profile',
          style: TextStyle(fontWeight: FontWeight.w700, color: _ink),
        ),
        leading: IconButton(
          onPressed: _step == 0 ? null : _back,
          icon: const Icon(Icons.arrow_back_ios_new),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 6, 18, 20),
          child: Column(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(99),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: const Color(0xFFE0E4E2),
                  valueColor: const AlwaysStoppedAnimation<Color>(_accent),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: _card,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: _contentForStep(),
                ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    _error!,
                    style: const TextStyle(color: _danger, fontSize: 13),
                  ),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  if (_isOptionalStep)
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _saving ? null : _skip,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _ink,
                          side: const BorderSide(color: Color(0xFFC3C8C6)),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          minimumSize: const Size.fromHeight(50),
                        ),
                        child: const Text('Skip for now'),
                      ),
                    ),
                  if (_isOptionalStep) const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _saving || !_canContinue ? null : _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accent,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        minimumSize: const Size.fromHeight(50),
                      ),
                      child: _saving
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.2,
                                color: Colors.white,
                              ),
                            )
                          : Text(
                              _step == _totalSteps - 1 ? 'Finish' : 'Continue',
                            ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _contentForStep() {
    switch (_step) {
      case 0:
        return _requiredSelectionStep(
          title: 'What is your primary goal?',
          why: 'Used to personalize workouts and progress targets.',
          options: _goals,
          selected: _goal,
          onSelect: (value) => setState(() => _goal = value),
        );
      case 1:
        return _requiredSelectionStep(
          title: 'How active are you right now?',
          why: 'Used to set a realistic starting plan and avoid overload.',
          options: _activityLevels,
          selected: _activityLevel,
          onSelect: (value) => setState(() => _activityLevel = value),
        );
      case 2:
        return _optionalSelectionStep(
          title: 'Experience level',
          why: 'Helps tune intensity and progression pace.',
          options: _experienceLevels,
          selected: _experienceLevel,
          onSelect: (value) => setState(() => _experienceLevel = value),
        );
      case 3:
        return _bodyMetricsStep();
      case 4:
        return _preferencesStep();
      default:
        return const SizedBox.shrink();
    }
  }

  Widget _requiredSelectionStep({
    required String title,
    required String why,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(why, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 16),
        ...options.map(
          (item) => _ChoiceTile(
            label: item,
            selected: selected == item,
            onTap: () => onSelect(item),
          ),
        ),
      ],
    );
  }

  Widget _optionalSelectionStep({
    required String title,
    required String why,
    required List<String> options,
    required String? selected,
    required ValueChanged<String> onSelect,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(why, style: const TextStyle(color: _muted, fontSize: 13)),
        const SizedBox(height: 16),
        ...options.map(
          (item) => _ChoiceTile(
            label: item,
            selected: selected == item,
            onTap: () => onSelect(item),
          ),
        ),
      ],
    );
  }

  Widget _bodyMetricsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Body metrics (optional)',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Used to improve calorie and intensity estimates.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        _MetricField(
          controller: _weightCtrl,
          label: 'Weight (kg)',
          hint: 'e.g. 72',
        ),
        const SizedBox(height: 12),
        _MetricField(
          controller: _heightCtrl,
          label: 'Height (cm)',
          hint: 'e.g. 172',
        ),
      ],
    );
  }

  Widget _preferencesStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Preferences (optional)',
          style: TextStyle(
            color: _ink,
            fontSize: 22,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Used to prioritize content and session format.',
          style: TextStyle(color: _muted, fontSize: 13),
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: _preferenceOptions.map((option) {
            final selected = _preferences.contains(option);
            return ChoiceChip(
              selected: selected,
              label: Text(option),
              onSelected: (_) {
                setState(() {
                  if (!selected) {
                    _preferences.add(option);
                  } else {
                    _preferences.remove(option);
                  }
                });
              },
              selectedColor: _accent.withOpacity(0.18),
              labelStyle: TextStyle(
                color: selected ? _accent : _ink,
                fontWeight: FontWeight.w600,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
                side: BorderSide(
                  color: selected ? _accent : const Color(0xFFC3C8C6),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE0EEEA) : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? const Color(0xFF035C4A) : const Color(0xFFC3C8C6),
            width: selected ? 1.4 : 1,
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(
                  color: Color(0xFF2A323E),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            if (selected)
              const Icon(
                Icons.check_circle,
                color: Color(0xFF035C4A),
                size: 19,
              ),
          ],
        ),
      ),
    );
  }
}

class _MetricField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String hint;

  const _MetricField({
    required this.controller,
    required this.label,
    required this.hint,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC3C8C6)),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFFC3C8C6)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: Color(0xFF035C4A), width: 1.4),
        ),
      ),
    );
  }
}
