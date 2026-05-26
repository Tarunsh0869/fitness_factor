import 'package:flutter/material.dart';

class SelectableChip extends StatelessWidget {
  const SelectableChip({
    super.key,
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
      borderRadius: BorderRadius.circular(28),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 170),
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F2ED),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: selected ? const Color(0xFF035C4A) : const Color(0xFFC3C8C6),
            width: 1.5,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? const Color(0xFF035C4A) : const Color(0xFF2A323E),
            fontWeight: FontWeight.w500,
            fontSize: 16,
          ),
        ),
      ),
    );
  }
}
