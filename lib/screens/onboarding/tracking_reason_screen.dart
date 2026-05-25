import 'package:flutter/material.dart';
import '../../widgets/option_card.dart';
import 'onboarding_model.dart';

class TrackingReasonScreen extends StatelessWidget {
  const TrackingReasonScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _reasons = [
    'To track my progress over time',
    'To stay motivated and consistent',
    'To have a clear structure for my workouts',
    'To reach specific fitness goals',
    'To understand recovery and rest patterns',
    'Other',
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Why do you track your workouts?',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 26, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 12),
        const Text(
          "Choose as many as you'd like.",
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF6F6F75)),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.separated(
            itemCount: _reasons.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final item = _reasons[index];
              final selected = model.trackingReasons.contains(item);
              return OptionCard(
                title: item,
                selected: selected,
                onTap: () => model.toggleTrackingReason(item),
                trailing: Container(
                  width: 22,
                  height: 22,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? const Color(0xFF1689F7) : const Color(0xFFCDCFD5),
                      width: 1.6,
                    ),
                    color: selected ? const Color(0x141689F7) : Colors.transparent,
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
