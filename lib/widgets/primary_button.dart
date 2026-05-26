import 'package:flutter/material.dart';

class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  final String label;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      width: double.infinity,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          elevation: 0,
          disabledBackgroundColor: const Color(0xFFC3C8C6),
          backgroundColor: const Color(0xFF035C4A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(30),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: enabled ? Colors.white : const Color(0xFF7A8582),
            fontSize: 35 / 2,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
