import 'dart:math' as math;

import 'package:flutter/material.dart';

class FitnessFactorLogo extends StatelessWidget {
  const FitnessFactorLogo({
    super.key,
    this.size = 96,
    this.assetPath = 'assets/logo/fitness_factor_logo.png',
  });

  final double size;
  final String assetPath;

  static const _metalDark = Color(0xFF44484D);
  static const _metalMid = Color(0xFFBFC4C9);
  static const _metalLight = Color(0xFFE5E8EA);
  static const _metalShadow = Color(0xFF26292D);
  static const _green = Color(0xFF00A678);
  static const _canvas = Color(0xFFF3F3EE);

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      assetPath,
      width: size,
      height: size,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => _buildFallbackLogo(),
    );
  }

  Widget _buildFallbackLogo() {
    final ringWidth = size * 0.1;
    final innerSize = size * 0.62;
    final stroke = size * 0.12;
    final radius = BorderRadius.circular(stroke / 2);

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          CustomPaint(
            size: Size.square(size),
            painter: _HexFramePainter(ringWidth: ringWidth),
          ),
          Center(
            child: SizedBox(
              width: innerSize,
              height: innerSize,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: innerSize * 0.04,
                    right: innerSize * 0.04,
                    top: innerSize * 0.47,
                    child: _MetalStroke(
                      width: innerSize * 0.92,
                      height: stroke * 0.18,
                      radius: BorderRadius.circular(stroke * 0.18),
                    ),
                  ),
                  Positioned(
                    left: innerSize * 0.12,
                    top: innerSize * 0.24,
                    child: _MiniPlate(stroke: stroke, reverse: false),
                  ),
                  Positioned(
                    right: innerSize * 0.12,
                    top: innerSize * 0.24,
                    child: _MiniPlate(stroke: stroke, reverse: true),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _MetalStroke(
                      width: innerSize * 0.62,
                      height: stroke,
                      radius: radius,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: 0,
                    child: _MetalStroke(
                      width: stroke,
                      height: innerSize * 0.85,
                      radius: radius,
                    ),
                  ),
                  Positioned(
                    left: 0,
                    top: innerSize * 0.36,
                    child: _MetalStroke(
                      width: innerSize * 0.58,
                      height: stroke,
                      radius: radius,
                    ),
                  ),
                  Positioned(
                    left: innerSize * 0.44,
                    top: innerSize * 0.12,
                    child: _MetalStroke(
                      width: stroke,
                      height: innerSize * 0.88,
                      radius: radius,
                    ),
                  ),
                  Positioned(
                    left: innerSize * 0.44,
                    top: innerSize * 0.12,
                    child: _MetalStroke(
                      width: innerSize * 0.56,
                      height: stroke,
                      radius: radius,
                    ),
                  ),
                  Positioned(
                    left: innerSize * 0.44,
                    top: innerSize * 0.52,
                    child: _MetalStroke(
                      width: innerSize * 0.5,
                      height: stroke,
                      radius: radius,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HexFramePainter extends CustomPainter {
  _HexFramePainter({required this.ringWidth});

  final double ringWidth;

  static const _metalDark = FitnessFactorLogo._metalDark;
  static const _metalMid = FitnessFactorLogo._metalMid;
  static const _metalLight = FitnessFactorLogo._metalLight;
  static const _metalShadow = FitnessFactorLogo._metalShadow;
  static const _canvas = FitnessFactorLogo._canvas;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2 - ringWidth * 0.4;
    final innerRadius = outerRadius - ringWidth;

    final outer = _hexPath(center, outerRadius);
    final inner = _hexPath(center, innerRadius);

    final shadowPaint = Paint()
      ..color = _metalShadow.withOpacity(0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3.4);
    canvas.drawPath(outer.shift(const Offset(0, 1.8)), shadowPaint);

    final fillPaint = Paint()
      ..style = PaintingStyle.fill
      ..shader = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [_metalDark, _metalMid, _metalLight, _metalDark],
        stops: [0.0, 0.35, 0.68, 1.0],
      ).createShader(Offset.zero & size);

    final ring = Path.combine(PathOperation.difference, outer, inner);
    canvas.drawPath(ring, fillPaint);

    final innerFillPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = _canvas;
    canvas.drawPath(inner, innerFillPaint);

    final innerStrokePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = ringWidth * 0.14
      ..color = _metalDark.withOpacity(0.35);
    canvas.drawPath(inner, innerStrokePaint);
  }

  Path _hexPath(Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (math.pi / 3 * i) - math.pi / 6;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (i == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    return path;
  }

  @override
  bool shouldRepaint(covariant _HexFramePainter oldDelegate) {
    return oldDelegate.ringWidth != ringWidth;
  }
}

class _MetalStroke extends StatelessWidget {
  const _MetalStroke({
    required this.width,
    required this.height,
    required this.radius,
  });

  final double width;
  final double height;
  final BorderRadius radius;

  static const _metalDark = FitnessFactorLogo._metalDark;
  static const _metalMid = FitnessFactorLogo._metalMid;
  static const _metalLight = FitnessFactorLogo._metalLight;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_metalDark, _metalMid, _metalLight, _metalDark],
          stops: [0.0, 0.4, 0.72, 1.0],
        ),
      ),
    );
  }
}

class _MiniPlate extends StatelessWidget {
  const _MiniPlate({
    required this.stroke,
    required this.reverse,
  });

  final double stroke;
  final bool reverse;

  static const _green = FitnessFactorLogo._green;
  static const _metalDark = FitnessFactorLogo._metalDark;
  static const _metalMid = FitnessFactorLogo._metalMid;
  static const _metalLight = FitnessFactorLogo._metalLight;

  @override
  Widget build(BuildContext context) {
    final plateWidth = stroke * 0.58;
    final plateHeight = stroke * 1.45;
    final gap = stroke * 0.16;

    final row = Row(
      children: [
        _plate(width: plateWidth, height: plateHeight, green: true),
        SizedBox(width: gap),
        _plate(width: plateWidth, height: plateHeight, green: false),
      ],
    );

    return reverse
        ? Transform(
            alignment: Alignment.center,
            transform: Matrix4.identity()..scale(-1.0, 1.0),
            child: row,
          )
        : row;
  }

  Widget _plate({
    required double width,
    required double height,
    required bool green,
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(width),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: green
              ? const [Color(0xFF1AD8A6), _green, Color(0xFF0C785B)]
              : const [_metalDark, _metalMid, _metalDark],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.28),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
    );
  }
}
