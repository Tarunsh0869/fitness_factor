import 'package:flutter/material.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({
    super.key,
    required this.onJoin,
  });

  final VoidCallback onJoin;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F8FB),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 8),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: _HeroCollage(),
              ),
            ),
            const SizedBox(height: 18),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 36),
              child: Text(
                'Get stronger.\nSee your progress.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 58 / 2,
                  height: 1.3,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF1E1E1E),
                ),
              ),
            ),
            const SizedBox(height: 26),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
              child: SizedBox(
                width: double.infinity,
                height: 62,
                child: ElevatedButton(
                  onPressed: onJoin,
                  style: ElevatedButton.styleFrom(
                    elevation: 0,
                    backgroundColor: const Color(0xFF2D84EA),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(31),
                    ),
                  ),
                  child: const Text(
                    'Join for free',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 32 / 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeroCollage extends StatelessWidget {
  final List<Color> tones = const [
    Color(0xFF343A40),
    Color(0xFF20242A),
    Color(0xFF4A3C32),
    Color(0xFF3A4046),
    Color(0xFF2A2D33),
  ];

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        return Stack(
          children: [
            _tile(0, 0, w * .24, 98, 0),
            _tile(w * .28, 0, w * .24, 120, 1),
            _tile(w * .56, 0, w * .24, 152, 2),
            _tile(w * .84, 0, w * .16, 108, 3),
            _tile(0, 108, w * .24, 160, 4),
            _tile(w * .28, 128, w * .24, 180, 2),
            _tile(w * .56, 180, w * .24, 180, 1),
            _tile(w * .84, 136, w * .16, 120, 0),
            _tile(0, 280, w * .24, 150, 3),
            _tile(w * .28, 338, w * .24, 146, 4),
            _tile(w * .56, 366, w * .24, 118, 0),
            _tile(w * .84, 268, w * .16, 180, 2),
          ],
        );
      },
    );
  }

  Widget _tile(double left, double top, double width, double height, int tone) {
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [tones[tone], tones[(tone + 1) % tones.length]],
          ),
        ),
      ),
    );
  }
}
