import 'package:flutter/material.dart';
import '../../widgets/goal_card.dart';
import 'onboarding_model.dart';

class GoalsScreen extends StatelessWidget {
  const GoalsScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _items = [
    ('Build Muscle', Icons.fitness_center, Color(0xFFF8DCDD)),
    ('Gain Strength', Icons.sports_martial_arts, Color(0xFFDDF3F2)),
    ('Lose Weight', Icons.directions_run, Color(0xFFDEF3E8)),
    ('Fundamentals', Icons.sports_gymnastics, Color(0xFFFDEFD8)),
    ('Conditioning', Icons.flash_on_outlined, Color(0xFFE9E3F7)),
    ('Sport', Icons.sports_basketball_outlined, Color(0xFFF7F3D8)),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'What are your goals?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26 * 1.0, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 12),
        const Text(
          "Choose as many as you'd like.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF6F6F75)),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: _items.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 1.16,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            itemBuilder: (context, index) {
              final item = _items[index];
              final title = item.$1;
              return GoalCard(
                title: title,
                icon: item.$2,
                tint: item.$3,
                selected: model.goals.contains(title),
                onTap: () => model.toggleGoal(title),
              );
            },
          ),
        ),
      ],
    );
  }
}
