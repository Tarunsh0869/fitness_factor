import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../blocs/onboarding/onboarding_bloc.dart';
import '../login_screen.dart';
import 'guest_onboarding_flow_screen.dart';

class OnboardingFlowScreen extends StatelessWidget {
  final Future<void> Function()? onComplete;
  final WidgetBuilder completeDestinationBuilder;

  const OnboardingFlowScreen({
    super.key,
    this.onComplete,
    this.completeDestinationBuilder = _defaultCompleteDestination,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => OnboardingBloc(onComplete: onComplete),
      child: _OnboardingFlowView(
        completeDestinationBuilder: completeDestinationBuilder,
      ),
    );
  }
}

Widget _defaultCompleteDestination(BuildContext context) => const LoginScreen();

class _OnboardingFlowView extends StatefulWidget {
  final WidgetBuilder completeDestinationBuilder;
  const _OnboardingFlowView({required this.completeDestinationBuilder});

  @override
  State<_OnboardingFlowView> createState() => _OnboardingFlowViewState();
}

class _OnboardingFlowViewState extends State<_OnboardingFlowView> {
  static const _bg = Color(0xFFF9F7F2);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _accentDark = Color(0xFF02473A);
  static const _ghostSkip = Color(0xFFE7E5DF);

  final PageController _controller = PageController();

  static const _slides = <_SlideData>[
    _SlideData(
      title: 'Build consistency',
      subtitle: 'Start fast workouts and keep your routine on track.',
      icon: Icons.fitness_center_rounded,
    ),
    _SlideData(
      title: 'Track progress',
      subtitle: 'See sessions, streaks, and improvements clearly.',
      icon: Icons.show_chart_rounded,
    ),
    _SlideData(
      title: 'Unlock personalization',
      subtitle: 'Sign in when ready and tailor plans to your goals.',
      icon: Icons.auto_awesome_rounded,
    ),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _next(OnboardingState state) {
    if (state.index >= _slides.length - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _back(OnboardingState state) {
    if (state.index <= 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<OnboardingBloc, OnboardingState>(
      listener: (context, state) {
        if (state is OnboardingGoToGuest) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (_) => const GuestOnboardingFlowScreen()),
          );
        } else if (state is OnboardingGoToSignIn) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: widget.completeDestinationBuilder),
          );
        }
      },
      child: BlocBuilder<OnboardingBloc, OnboardingState>(
        builder: (context, state) {
          final bloc = context.read<OnboardingBloc>();
          final isLast = state.index == _slides.length - 1;

          return Scaffold(
            backgroundColor: _bg,
            body: SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
                child: Column(
                  children: [
                    Expanded(
                      child: PageView.builder(
                        controller: _controller,
                        itemCount: _slides.length,
                        onPageChanged: (i) =>
                            bloc.add(OnboardingPageChanged(i)),
                        itemBuilder: (context, i) {
                          final slide = _slides[i];
                          return Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 152,
                                height: 152,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [_accentDark, _accent],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(40),
                                ),
                                child: Icon(
                                  slide.icon,
                                  color: Colors.white,
                                  size: 68,
                                ),
                              ),
                              const SizedBox(height: 28),
                              Text(
                                slide.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _ink,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                slide.subtitle,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  color: _muted,
                                  fontSize: 15,
                                  height: 1.45,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(
                        _slides.length,
                        (i) => AnimatedContainer(
                          duration: const Duration(milliseconds: 180),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          height: 7,
                          width: i == state.index ? 24 : 7,
                          decoration: BoxDecoration(
                            color: i == state.index
                                ? _accent
                                : const Color(0xFFC3C8C6),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    if (!isLast) ...[
                      Row(
                        children: [
                          if (state.index > 0)
                            TextButton.icon(
                              onPressed: () => _back(state),
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
                                : () => bloc.add(OnboardingNavigateToSignIn()),
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
                      const SizedBox(height: 8),
                    ],
                    if (!isLast)
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => _next(state),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Next',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    if (isLast) ...[
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: state.navigating
                              ? null
                              : () => bloc.add(OnboardingNavigateToGuest()),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _accent,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          child: const Text(
                            'Try as Guest',
                            style: TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton(
                          onPressed: state.navigating
                              ? null
                              : () => bloc.add(OnboardingNavigateToSignIn()),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _ink,
                            side: const BorderSide(color: Color(0xFFC3C8C6)),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: const Text(
                            'Sign In',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                        ),
                      ),
                    ],
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

class _SlideData {
  final String title;
  final String subtitle;
  final IconData icon;

  const _SlideData({
    required this.title,
    required this.subtitle,
    required this.icon,
  });
}
