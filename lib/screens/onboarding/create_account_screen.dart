import 'package:flutter/material.dart';

class CreateAccountScreen extends StatelessWidget {
  const CreateAccountScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 48),
        const Text(
          'Create an account',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Color(0xFF1E1E1E)),
        ),
        const SizedBox(height: 12),
        const Text(
          'Save your workouts, progress, settings, and more.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 18, color: Color(0xFF6F6F75)),
        ),
        const SizedBox(height: 36),
        _Button(
          label: 'Continue with Google',
          filled: false,
          icon: Icons.g_mobiledata,
          onTap: () {},
        ),
        const SizedBox(height: 14),
        _Button(
          label: 'Continue with Email',
          filled: true,
          icon: Icons.email_outlined,
          onTap: () {},
        ),
        const SizedBox(height: 20),
        Row(
          children: const [
            Expanded(child: Divider(color: Color(0xFFDADDE3))),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 12),
              child: Text('or', style: TextStyle(color: Color(0xFF6F6F75))),
            ),
            Expanded(child: Divider(color: Color(0xFFDADDE3))),
          ],
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.symmetric(horizontal: 12),
          child: Text.rich(
            TextSpan(
              text: 'By continuing, you agree to our ',
              style: TextStyle(color: Color(0xFF6F6F75), height: 1.5),
              children: [
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(color: Color(0xFF1689F7), fontWeight: FontWeight.w600),
                ),
                TextSpan(text: ' and '),
                TextSpan(
                  text: 'Terms of Service',
                  style: TextStyle(color: Color(0xFF1689F7), fontWeight: FontWeight.w600),
                ),
                TextSpan(text: '.'),
              ],
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: 18),
      ],
    );
  }
}

class _Button extends StatelessWidget {
  const _Button({
    required this.label,
    required this.filled,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final bool filled;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: filled ? 20 : 30),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          foregroundColor: filled ? Colors.white : const Color(0xFF1E1E1E),
          backgroundColor: filled ? const Color(0xFF2D84EA) : Colors.white,
          side: filled ? BorderSide.none : const BorderSide(color: Color(0xFFDADDE3)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
        ),
        label: Text(
          label,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
        ),
      ),
    );
  }
}
