import 'package:flutter/material.dart';

class OnboardingProgressBar extends StatelessWidget {
  const OnboardingProgressBar({super.key, required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 4,
      decoration: BoxDecoration(
        color: const Color(0xFFC3C8C6),
        borderRadius: BorderRadius.circular(99),
      ),
      child: FractionallySizedBox(
        widthFactor: progress.clamp(0.04, 1.0),
        alignment: Alignment.centerLeft,
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF035C4A),
            borderRadius: BorderRadius.circular(99),
          ),
        ),
      ),
    );
  }
}
