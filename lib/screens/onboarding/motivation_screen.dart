import 'package:flutter/material.dart';

class _MotivationAssets {
  static const progress = 'assets/onboarding/motivation/progress.png';
  static const push = 'assets/onboarding/motivation/push.png';
  static const rightPlace = 'assets/onboarding/motivation/right_place.png';
}

class MotivationScreen extends StatelessWidget {
  const MotivationScreen({super.key, required this.index});

  final int index;

  @override
  Widget build(BuildContext context) {
    if (index == 0) return const _ProgressMotivation();
    if (index == 1) return const _PushMotivation();
    return const _RightPlaceMotivation();
  }
}

class _ProgressMotivation extends StatelessWidget {
  const _ProgressMotivation();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Track progress that matters',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Every workout you log helps you see what’s improving and what needs focus.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.4, color: Color(0xFF535E62)),
        ),
        const SizedBox(height: 16),
        const SizedBox(
          height: 160,
          width: double.infinity,
          child: _MotivationImageCard(
            assetPath: _MotivationAssets.progress,
            fallbackIcon: Icons.stacked_line_chart,
            fallbackIconSize: 84,
          ),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: GridView.count(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.08,
            children: const [
              _InfoCard(icon: Icons.stacked_line_chart, title: 'Trends'),
              _InfoCard(icon: Icons.fitness_center, title: 'Strength'),
              _InfoCard(
                icon: Icons.monitor_weight_outlined,
                title: 'Body data',
              ),
              _InfoCard(icon: Icons.radar_outlined, title: 'Balance'),
            ],
          ),
        ),
      ],
    );
  }
}

class _PushMotivation extends StatelessWidget {
  const _PushMotivation();

  @override
  Widget build(BuildContext context) {
    final items = [
      'Plan your workouts and stay on track with ease.',
      'See your last weight so you know when to push harder.',
      'Track your progress and find the right balance between pushing and recovery.',
    ];

    return Column(
      children: [
        const SizedBox(height: 24),
        const Text(
          'Always know when to push yourself',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 20),
        ...items.map(
          (item) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 7),
                  child: Icon(Icons.circle, size: 8, color: Color(0xFF035C4A)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    item,
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFF2A323E),
                      height: 1.4,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Expanded(
          child: const _MotivationImageCard(
            assetPath: _MotivationAssets.push,
            fallbackIcon: Icons.query_stats,
            fallbackIconSize: 120,
          ),
        ),
      ],
    );
  }
}

class _RightPlaceMotivation extends StatelessWidget {
  const _RightPlaceMotivation();

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const SizedBox(height: 36),
        const Text(
          "You're in the right place!",
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: Color(0xFF2A323E),
          ),
        ),
        const SizedBox(height: 18),
        const Text(
          'It\'s all about helping you stay consistent, set personal records, and see real progress.',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 17, height: 1.4, color: Color(0xFF535E62)),
        ),
        const SizedBox(height: 28),
        Expanded(
          child: const _MotivationImageCard(
            assetPath: _MotivationAssets.rightPlace,
            fallbackIcon: Icons.emoji_events_outlined,
            fallbackIconSize: 130,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({required this.icon, required this.title});

  final IconData icon;
  final String title;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFF3F2ED),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40, color: const Color(0xFF035C4A)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(
              fontSize: 16,
              color: Color(0xFF2A323E),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _MotivationImageCard extends StatelessWidget {
  const _MotivationImageCard({
    required this.assetPath,
    required this.fallbackIcon,
    required this.fallbackIconSize,
  });

  final String assetPath;
  final IconData fallbackIcon;
  final double fallbackIconSize;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: Stack(
        fit: StackFit.expand,
        children: [
          const DecoratedBox(
            decoration: BoxDecoration(color: Color(0xFFF3F2ED)),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              errorBuilder: (_, __, ___) {
                return Center(
                  child: Icon(
                    fallbackIcon,
                    size: fallbackIconSize,
                    color: const Color(0xFF035C4A),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
