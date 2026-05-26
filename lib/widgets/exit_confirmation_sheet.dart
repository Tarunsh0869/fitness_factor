// ignore_for_file: deprecated_member_use

import 'package:flutter/material.dart';

class ExitConfirmationSheet extends StatelessWidget {
  final int sessionId;
  final VoidCallback onConfirm;
  final VoidCallback onDeny;

  const ExitConfirmationSheet({
    super.key,
    required this.sessionId,
    required this.onConfirm,
    required this.onDeny,
  });

  static Future<void> show(
    BuildContext context, {
    required int sessionId,
    required VoidCallback onConfirm,
    required VoidCallback onDeny,
  }) {
    return showModalBottomSheet(
      context: context,
      isDismissible: false,
      enableDrag: false,
      backgroundColor: Colors.transparent,
      builder: (_) => ExitConfirmationSheet(
        sessionId: sessionId,
        onConfirm: onConfirm,
        onDeny: onDeny,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const blue = Color(0xFF035C4A);
    const red = Color(0xFFB3261E);
    const ink = Color(0xFF2A323E);
    const muted = Color(0xFF535E62);
    const surface = Color(0xFFF3F2ED);

    return Container(
      decoration: const BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: const Color(0xFF334155),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 28),
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: red.withOpacity(0.08),
              border: Border.all(color: red.withOpacity(0.2), width: 2),
            ),
            child: const Icon(Icons.directions_run, color: red, size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            'Did you leave the gym?',
            style: TextStyle(
              color: ink,
              fontSize: 22,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'We detected you may have left.\nConfirm to close your session.',
            textAlign: TextAlign.center,
            style: TextStyle(color: muted, fontSize: 14, height: 1.5),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFB3261E), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(14),
                boxShadow: [
                  BoxShadow(
                    color: red.withOpacity(0.3),
                    blurRadius: 14,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pop(context);
                  onConfirm();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.transparent,
                  shadowColor: Colors.transparent,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'YES, CHECK ME OUT',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 15),
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: OutlinedButton(
              onPressed: () {
                Navigator.pop(context);
                onDeny();
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: blue,
                side: const BorderSide(color: blue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: const Text(
                "NO, I'M STILL HERE",
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
