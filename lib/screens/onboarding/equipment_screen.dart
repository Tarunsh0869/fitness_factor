import 'package:flutter/material.dart';
import '../../widgets/option_card.dart';
import 'onboarding_model.dart';

class EquipmentScreen extends StatelessWidget {
  const EquipmentScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _items = [
    (EquipmentType.fullGym, 'Full gym', Icons.apartment_outlined),
    (EquipmentType.barbells, 'Barbells', Icons.fitness_center),
    (EquipmentType.dumbbells, 'Dumbbells', Icons.sports_handball_outlined),
    (
      EquipmentType.kettlebells,
      'Kettlebells',
      Icons.sports_gymnastics_outlined,
    ),
    (
      EquipmentType.machines,
      'Machines',
      Icons.precision_manufacturing_outlined,
    ),
    (
      EquipmentType.none,
      'None of the above',
      Icons.do_not_disturb_alt_outlined,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'What equipment do you have?',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'You can change specifics later',
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
              final selected = model.equipment.contains(item.$1);
              return OptionCard(
                title: item.$2,
                selected: selected,
                onTap: () => model.toggleEquipment(item.$1),
                leading: Icon(
                  item.$3,
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
