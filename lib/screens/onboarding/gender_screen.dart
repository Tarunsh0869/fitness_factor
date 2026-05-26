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
          style: TextStyle(
            fontSize: 52 / 2,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'This helps us personalize your experience',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 36 / 2, color: Color(0xFF535E62)),
        ),
        const SizedBox(height: 42),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: _GenderBody(
                  label: 'Male',
                  assetPath: 'assets/onboarding/gender/male.png',
                  selected: model.gender == Gender.male,
                  onTap: () => model.setGender(Gender.male),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _GenderBody(
                  label: 'Female',
                  assetPath: 'assets/onboarding/gender/female.png',
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
    required this.assetPath,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String assetPath;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            decoration: BoxDecoration(
              color: selected
                  ? const Color(0x14035C4A)
                  : const Color(0xFFF3F2ED),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: selected
                    ? const Color(0xFF035C4A)
                    : const Color(0xFFC3C8C6),
                width: selected ? 2 : 1,
              ),
            ),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: onTap,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Image.asset(
                        assetPath,
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomCenter,
                        errorBuilder: (_, __, ___) => Icon(
                          Icons.accessibility_new_rounded,
                          size: 150,
                          color: selected
                              ? const Color(0xFF035C4A)
                              : const Color(0xFFC3C8C6),
                        ),
                      ),
                    ),
                    if (selected)
                      Positioned(
                        top: 10,
                        right: 10,
                        child: Container(
                          width: 28,
                          height: 28,
                          decoration: const BoxDecoration(
                            color: Color(0xFF035C4A),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 20,
            color: selected ? const Color(0xFF2A323E) : const Color(0xFF535E62),
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
