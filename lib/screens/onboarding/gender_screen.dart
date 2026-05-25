import 'package:flutter/material.dart';
import 'onboarding_model.dart';

class GenderScreen extends StatelessWidget {
  const GenderScreen({super.key, required this.model});

  final OnboardingModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 34),
        const Text(
          "What's your gender?",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 52 / 2, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 12),
        const Text(
          'This helps us personalize your experience',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 36 / 2, color: Color(0xFF6F6F75)),
        ),
        const SizedBox(height: 42),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _GenderBody(
                  label: 'Male',
                  selected: model.gender == Gender.male,
                  onTap: () => model.setGender(Gender.male),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderBody(
                  label: 'Female',
                  selected: model.gender == Gender.female,
                  onTap: () => model.setGender(Gender.female),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _GenderBody extends StatelessWidget {
  const _GenderBody({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Column(
        children: [
          Expanded(
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                color: selected ? const Color(0x10F97316) : Colors.transparent,
              ),
              child: Center(
                child: Icon(
                  Icons.accessibility_new_rounded,
                  size: 210,
                  color: selected ? const Color(0xFFCF5B45) : const Color(0xFFD0D2D8),
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            label,
            style: TextStyle(
              fontSize: 20,
              color: selected ? const Color(0xFF1E1E1E) : const Color(0xFF6F6F75),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }
}
