import 'package:flutter/material.dart';
import '../../widgets/selectable_chip.dart';
import 'onboarding_model.dart';

class FocusAreaScreen extends StatelessWidget {
  const FocusAreaScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _areas = [
    'Back', 'Arms', 'Shoulders', 'Abs', 'Chest', 'Legs', 'Glutes', 'Full body'
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Choose your focus areas',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 18),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          alignment: WrapAlignment.center,
          children: _areas
              .map((area) => SelectableChip(
                    label: area,
                    selected: model.focusAreas.contains(area),
                    onTap: () => model.toggleFocusArea(area),
                  ))
              .toList(),
        ),
        const SizedBox(height: 24),
        Expanded(
          child: Row(
            children: [
              Expanded(child: _muscleFigure(model.focusAreas.isEmpty)),
              const SizedBox(width: 10),
              Expanded(child: _muscleFigure(model.focusAreas.isEmpty)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _muscleFigure(bool idle) {
    return Column(
      children: [
        Expanded(
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(18),
              color: Colors.transparent,
            ),
            child: Center(
              child: Icon(
                Icons.accessibility_new,
                size: 230,
                color: idle ? const Color(0xFFD4D7DD) : const Color(0xFFCF5B45),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
