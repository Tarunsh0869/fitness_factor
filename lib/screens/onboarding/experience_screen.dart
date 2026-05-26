import 'package:flutter/material.dart';
import '../../widgets/option_card.dart';
import 'onboarding_model.dart';

class ExperienceScreen extends StatelessWidget {
  const ExperienceScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _items = [
    ('I\'m new to weightlifting', ExperienceLevel.newLifter),
    ('I\'ve been lifting for a few months', ExperienceLevel.months),
    ('I\'ve been lifting for a year', ExperienceLevel.year),
    ('I\'ve been lifting for years', ExperienceLevel.years),
    ('I\'m a competitor', ExperienceLevel.competitor),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'How experienced are you with weightlifting?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 20),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              final selected = model.experienceLevel == item.$2;
              return OptionCard(
                title: item.$1,
                selected: selected,
                onTap: () => model.setExperience(item.$2),
                trailing: Icon(
                  Icons.stacked_bar_chart,
                  color: selected
                      ? const Color(0xFF035C4A)
                      : const Color(0xFF7A8582),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
