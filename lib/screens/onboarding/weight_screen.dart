import 'package:flutter/material.dart';
import '../../widgets/weight_picker.dart';
import 'onboarding_model.dart';

class WeightScreen extends StatelessWidget {
  const WeightScreen({super.key, required this.model});

  final OnboardingModel model;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 26),
        const Text(
          'How much do you weigh?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 20),
        WeightPicker(
          metric: model.metric,
          major: model.weightMajor,
          decimal: model.weightDecimal,
          onMetricChanged: model.setMetric,
          onMajorChanged: model.setWeightMajor,
          onDecimalChanged: model.setWeightDecimal,
        ),
      ],
    );
  }
}
