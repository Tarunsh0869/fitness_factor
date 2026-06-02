import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/guest_onboarding/guest_onboarding_bloc.dart';
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

class GuestOnboardingFlowScreen extends StatelessWidget {
  const GuestOnboardingFlowScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => GuestOnboardingBloc(),
      child: const _GuestOnboardingView(),
    );
  }
}

class _GuestOnboardingView extends StatefulWidget {
  const _GuestOnboardingView();

  @override
  State<_GuestOnboardingView> createState() => _GuestOnboardingViewState();
}

class _GuestOnboardingViewState extends State<_GuestOnboardingView> {
  static const _bg = Color(0xFFF9F7F2);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _ghostSkip = Color(0xFFE7E5DF);

  final OnboardingModel _model = OnboardingModel();

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
    if (mounted) setState(() {});
  }

  bool _canContinue(int step) {
    switch (step) {
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

  Widget _buildStep(int step) {
    switch (step) {
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
    return BlocListener<GuestOnboardingBloc, GuestOnboardingState>(
      listener: (context, state) {
        if (state is GuestOnboardingDone) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GuestExperienceScreen()),
          );
        }
      },
      child: BlocBuilder<GuestOnboardingBloc, GuestOnboardingState>(
        builder: (context, state) {
          final bloc = context.read<GuestOnboardingBloc>();
          final canContinue = _canContinue(state.step) && !state.navigating;
          final progress =
              (state.step + 1) / GuestOnboardingState.totalSteps;

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
                    Expanded(child: _buildStep(state.step)),
                    Row(
                      children: [
                        if (state.step > 0)
                          TextButton.icon(
                            onPressed: state.navigating
                                ? null
                                : () => bloc.add(GuestOnboardingBack()),
                            icon: const Icon(
                              Icons.arrow_back_ios_new,
                              size: 14,
                            ),
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
                          onPressed: state.navigating
                              ? null
                              : () => bloc.add(
                                    GuestOnboardingComplete(skipped: true),
                                  ),
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
                    if (state.isOptionalStep && !state.isLastStep) ...[
                      SizedBox(
                        width: double.infinity,
                        child: TextButton(
                          onPressed: () => bloc.add(GuestOnboardingSkipStep()),
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
                      label: state.isLastStep ? 'Finish' : 'Continue',
                      enabled: canContinue,
                      onTap: () => bloc.add(GuestOnboardingNext()),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
