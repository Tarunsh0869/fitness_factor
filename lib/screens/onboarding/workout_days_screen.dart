import 'package:flutter/material.dart';
import '../../widgets/option_card.dart';
import 'onboarding_model.dart';

class WorkoutDaysScreen extends StatelessWidget {
  const WorkoutDaysScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _items = [
    (1, 'Good'),
    (2, 'Promising'),
    (3, 'Recommended'),
    (4, 'Recommended'),
    (5, 'Recommended'),
    (6, 'Impressive'),
    (7, 'Unstoppable'),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'How many days a week would you like to work out?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 25,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You can always change it later',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF535E62)),
        ),
        const SizedBox(height: 18),
        Expanded(
          child: ListView.separated(
            itemCount: _items.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _items[index];
              final selected = model.workoutDays == item.$1;
              return OptionCard(
                title: '${item.$1} day${item.$1 == 1 ? '' : 's'} a week',
                subtitle: item.$2,
                selected: selected,
                onTap: () => model.setWorkoutDays(item.$1),
                trailing: Text(
                  item.$2,
                  style: TextStyle(
                    color: selected
                        ? const Color(0xFF035C4A)
                        : const Color(0xFF535E62),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
