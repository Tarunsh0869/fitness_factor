import 'package:flutter/material.dart';

import '../login_screen.dart';
import 'guest_onboarding_flow_screen.dart';

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
  static const _bg = Color(0xFFF9F7F2);
  static const _ink = Color(0xFF2A323E);
  static const _muted = Color(0xFF535E62);
  static const _accent = Color(0xFF035C4A);
  static const _accentDark = Color(0xFF02473A);
  static const _ghostSkip = Color(0xFFE7E5DF);

  final PageController _controller = PageController();
  int _index = 0;

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

  Future<void> _completeAndOpenGuest() async {
    await widget.onComplete?.call();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const GuestOnboardingFlowScreen()),
    );
  }

  Future<void> _completeAndOpenSignIn() async {
    await widget.onComplete?.call();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: widget.completeDestinationBuilder),
    );
  }

  void _next() {
    if (_index >= _slides.length - 1) return;
    _controller.nextPage(
      duration: const Duration(milliseconds: 240),
      curve: Curves.easeOut,
    );
  }

  void _back() {
    if (_index <= 0) return;
    _controller.previousPage(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLast = _index == _slides.length - 1;
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
                  onPageChanged: (value) => setState(() => _index = value),
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
                    width: i == _index ? 24 : 7,
                    decoration: BoxDecoration(
                      color: i == _index ? _accent : const Color(0xFFC3C8C6),
                      borderRadius: BorderRadius.circular(30),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 18),
              if (!isLast) ...[
                Row(
                  children: [
                    if (_index > 0)
                      TextButton.icon(
                        onPressed: _back,
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
                      onPressed: _completeAndOpenSignIn,
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
                    onPressed: _next,
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
                    onPressed: _completeAndOpenGuest,
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
                    onPressed: _completeAndOpenSignIn,
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
