import 'package:flutter/material.dart';

import '../../services/guest_session_service.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../../widgets/primary_button.dart';
import '../guest_experience_screen.dart';
import 'equipment_screen.dart';
import 'experience_screen.dart';
import 'focus_area_screen.dart';
import 'gender_screen.dart';
import 'goals_screen.dart';
import 'motivation_screen.dart';
import 'onboarding_model.dart';
import 'tracking_reason_screen.dart';
import 'weight_screen.dart';
import 'workout_days_screen.dart';

class GuestOnboardingFlowScreen extends StatefulWidget {
  const GuestOnboardingFlowScreen({super.key});

  @override
  State<GuestOnboardingFlowScreen> createState() =>
      _GuestOnboardingFlowScreenState();
}

class _GuestOnboardingFlowScreenState extends State<GuestOnboardingFlowScreen> {
  static const _bg = Color(0xFFF9F7F2);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _ghostSkip = Color(0xFFE7E5DF);

  final OnboardingModel _model = OnboardingModel();
  int _step = 0;
  bool _navigating = false;

  static const _totalSteps = 11;

  bool get _isLastStep => _step == _totalSteps - 1;

  bool get _canContinue {
    switch (_step) {
      case 0:
        return _model.gender != null;
      case 1:
        return _model.goals.isNotEmpty;
      case 2:
        return _model.focusAreas.isNotEmpty;
      case 3:
        return _model.trackingReasons.isNotEmpty;
      case 4:
        return _model.experienceLevel != null;
      case 5:
        return _model.workoutDays != null;
      case 6:
        return _model.equipment.isNotEmpty;
      default:
        return true;
    }
  }

  bool get _isOptionalStep => _step >= 7;

  @override
  void initState() {
    super.initState();
    _model.addListener(_onModelChanged);
  }

  @override
  void dispose() {
    _model.removeListener(_onModelChanged);
    _model.dispose();
    super.dispose();
  }

  void _onModelChanged() {
    if (!mounted) return;
    setState(() {});
  }

  Future<void> _completeFlow({required bool skipped}) async {
    if (_navigating) return;
    setState(() => _navigating = true);
    await GuestSessionService.recordMeaningfulAction(
      skipped ? 'guest_onboarding_skipped' : 'guest_onboarding_completed',
    );
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GuestExperienceScreen()),
    );
  }

  void _next() {
    if (!_canContinue || _navigating) return;
    if (_isLastStep) {
      _completeFlow(skipped: false);
      return;
    }
    setState(() => _step += 1);
  }

  void _back() {
    if (_step == 0 || _navigating) return;
    setState(() => _step -= 1);
  }

  void _skipStep() {
    if (!_isOptionalStep || _isLastStep || _navigating) return;
    setState(() => _step += 1);
  }

  Widget _buildStep() {
    switch (_step) {
      case 0:
        return GenderScreen(model: _model);
      case 1:
        return GoalsScreen(model: _model);
      case 2:
        return FocusAreaScreen(model: _model);
      case 3:
        return TrackingReasonScreen(model: _model);
      case 4:
        return ExperienceScreen(model: _model);
      case 5:
        return WorkoutDaysScreen(model: _model);
      case 6:
        return EquipmentScreen(model: _model);
      case 7:
        return WeightScreen(model: _model);
      case 8:
        return const MotivationScreen(index: 0);
      case 9:
        return const MotivationScreen(index: 1);
      case 10:
        return const MotivationScreen(index: 2);
      default:
        return const SizedBox.shrink();
    }
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
        automaticallyImplyLeading: false,
        title: const Text(
          'Guest Onboarding',
          style: TextStyle(
            color: _ink,
            fontSize: 18,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 8, 18, 20),
          child: Column(
            children: [
              OnboardingProgressBar(progress: progress),
              const SizedBox(height: 14),
              Expanded(child: _buildStep()),
              Row(
                children: [
                  if (_step > 0)
                    TextButton.icon(
                      onPressed: _navigating ? null : _back,
                      icon: const Icon(Icons.arrow_back_ios_new, size: 14),
                      label: const Text('Back'),
                      style: TextButton.styleFrom(
                        foregroundColor: _muted,
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  const Spacer(),
                  TextButton(
                    onPressed: _navigating
                        ? null
                        : () => _completeFlow(skipped: true),
                    style: TextButton.styleFrom(
                      foregroundColor: _ghostSkip,
                      textStyle: const TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                    child: const Text('Skip'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (_isOptionalStep && !_isLastStep) ...[
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _skipStep,
                    child: const Text(
                      'Skip this step',
                      style: TextStyle(
                        color: _ghostSkip,
                        fontWeight: FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
              ],
              PrimaryButton(
                label: _isLastStep ? 'Finish' : 'Continue',
                enabled: _canContinue && !_navigating,
                onTap: _next,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
