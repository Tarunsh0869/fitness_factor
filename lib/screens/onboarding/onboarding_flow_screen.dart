import 'package:flutter/material.dart';
import '../../widgets/onboarding_progress_bar.dart';
import '../../widgets/primary_button.dart';
import '../login_screen.dart';
import 'equipment_screen.dart';
import 'experience_screen.dart';
import 'focus_area_screen.dart';
import 'gender_screen.dart';
import 'goals_screen.dart';
import 'motivation_screen.dart';
import 'onboarding_model.dart';
import 'tracking_reason_screen.dart';
import 'weight_screen.dart';
import 'welcome_screen.dart';
import 'workout_days_screen.dart';

class OnboardingFlowScreen extends StatefulWidget {
  final Future<void> Function()? onComplete;
  final WidgetBuilder completeDestinationBuilder;

  const OnboardingFlowScreen({
    super.key,
    this.onComplete,
    this.completeDestinationBuilder = _defaultCompleteDestination,
  });

  @override
  State<OnboardingFlowScreen> createState() => _OnboardingFlowScreenState();
}

Widget _defaultCompleteDestination(BuildContext context) => const LoginScreen();

class _OnboardingFlowScreenState extends State<OnboardingFlowScreen> {
  final OnboardingModel _model = OnboardingModel();

  @override
  void initState() {
    super.initState();
    _model.addListener(_refresh);
  }

  @override
  void dispose() {
    _model.removeListener(_refresh);
    _model.dispose();
    super.dispose();
  }

  void _refresh() => setState(() {});

  Future<void> _finishOnboarding() async {
    await widget.onComplete?.call();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: widget.completeDestinationBuilder),
    );
  }

  Future<void> _continue() async {
    if (_model.step < OnboardingModel.totalSteps - 1) {
      _model.nextStep();
      return;
    }
    await _finishOnboarding();
  }

  Future<void> _skip() async {
    await _finishOnboarding();
  }

  @override
  Widget build(BuildContext context) {
    if (_model.step == 0) {
      return WelcomeScreen(onJoin: _continue, onSkip: _skip);
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF9F7F2),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  IconButton(
                    onPressed: _model.previousStep,
                    icon: const Icon(
                      Icons.arrow_back_ios_new,
                      color: Color(0xFF7A8582),
                    ),
                  ),
                  Expanded(
                    child: SizedBox(
                      width: double.infinity,
                      child: OnboardingProgressBar(progress: _model.progress),
                    ),
                  ),
                  SizedBox(
                    width: 64,
                    child: TextButton(
                      onPressed: _skip,
                      child: const Text(
                        'Skip',
                        style: TextStyle(
                          color: Color(0xFF035C4A),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 240),
                  switchInCurve: Curves.easeOut,
                  switchOutCurve: Curves.easeIn,
                  child: _contentByStep(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: PrimaryButton(
                label: _model.step == OnboardingModel.totalSteps - 1
                    ? 'Get started'
                    : 'Continue',
                enabled: _model.canContinue,
                onTap: _continue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _contentByStep() {
    switch (_model.step) {
      case 1:
        return GenderScreen(key: const ValueKey(1), model: _model);
      case 2:
        return GoalsScreen(key: const ValueKey(2), model: _model);
      case 3:
        return FocusAreaScreen(key: const ValueKey(3), model: _model);
      case 4:
        return TrackingReasonScreen(key: const ValueKey(4), model: _model);
      case 5:
        return ExperienceScreen(key: const ValueKey(5), model: _model);
      case 6:
        return WorkoutDaysScreen(key: const ValueKey(6), model: _model);
      case 7:
        return EquipmentScreen(key: const ValueKey(7), model: _model);
      case 8:
        return WeightScreen(key: const ValueKey(8), model: _model);
      case 9:
        return const MotivationScreen(key: ValueKey(9), index: 0);
      case 10:
        return const MotivationScreen(key: ValueKey(10), index: 1);
      case 11:
        return const MotivationScreen(key: ValueKey(11), index: 2);
      default:
        return const SizedBox.shrink();
    }
  }
}
