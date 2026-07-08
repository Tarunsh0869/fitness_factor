import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../theme/app_theme.dart';
import '../../widgets/selectable_chip.dart';
import 'onboarding_model.dart';

class FocusAreaScreen extends StatelessWidget {
  const FocusAreaScreen({super.key, required this.model});

  final OnboardingModel model;

  static const _areas = <String>[
    'Back',
    'Arms',
    'Shoulders',
    'Abs',
    'Chest',
    'Legs',
    'Glutes',
    'Full body',
  ];

  bool _isFullBodySelected() => model.focusAreas.contains('Full body');

  bool _isAreaSelected(String area) {
    if (area == 'Full body') return _isFullBodySelected();
    return _isFullBodySelected() || model.focusAreas.contains(area);
  }

  void _toggleArea(String area) {
    if (area == 'Full body') {
      final enableFullBody = !_isFullBodySelected();
      if (enableFullBody) {
        for (final item in _areas.where((value) => value != 'Full body')) {
          if (model.focusAreas.contains(item)) {
            model.toggleFocusArea(item);
          }
        }
      }
      model.toggleFocusArea('Full body');
      return;
    }

    if (_isFullBodySelected()) {
      model.toggleFocusArea('Full body');
    }
    model.toggleFocusArea(area);
  }

  @override
  Widget build(BuildContext context) {
    final fullBody = _isFullBodySelected();
    final selectedCount = fullBody
        ? _areas.length - 1
        : model.focusAreas.length;
    final selectedSnapshot = Set<String>.from(model.focusAreas);
    final palette = _MuscleMapPalette.fromTheme(Theme.of(context));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const SizedBox(height: 18),
        Text(
          'Choose your focus areas',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: palette.text,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          fullBody
              ? 'Full-body target selected'
              : selectedCount == 0
              ? 'Tap specific muscle groups on the body map'
              : '$selectedCount muscle groups selected',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 14, color: palette.muted),
        ),
        const SizedBox(height: 14),
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final mapHeight = math.min(390.0, constraints.maxHeight * 0.58);
              return SingleChildScrollView(
                padding: const EdgeInsets.only(bottom: 4),
                child: Column(
                  children: [
                    SizedBox(
                      height: mapHeight,
                      child: Row(
                        children: [
                          Expanded(
                            child: _MuscleMapCard(
                              title: 'Front',
                              data: _MuscleMapRepository.front,
                              selectedAreas: selectedSnapshot,
                              fullBodySelected: fullBody,
                              palette: palette,
                              onAreaTap: _toggleArea,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _MuscleMapCard(
                              title: 'Back',
                              data: _MuscleMapRepository.back,
                              selectedAreas: selectedSnapshot,
                              fullBodySelected: fullBody,
                              palette: palette,
                              onAreaTap: _toggleArea,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      alignment: WrapAlignment.center,
                      children: _areas
                          .map(
                            (area) => SelectableChip(
                              label: area,
                              selected: _isAreaSelected(area),
                              onTap: () => _toggleArea(area),
                            ),
                          )
                          .toList(),
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _MuscleMapCard extends StatelessWidget {
  const _MuscleMapCard({
    required this.title,
    required this.data,
    required this.selectedAreas,
    required this.fullBodySelected,
    required this.palette,
    required this.onAreaTap,
  });

  final String title;
  final _MuscleMapData data;
  final Set<String> selectedAreas;
  final bool fullBodySelected;
  final _MuscleMapPalette palette;
  final ValueChanged<String> onAreaTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: palette.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: palette.border),
      ),
      child: Column(
        children: [
          Text(
            title,
            style: TextStyle(
              color: palette.muted,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 6),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: _InteractiveMuscleMap(
                data: data,
                selectedAreas: selectedAreas,
                fullBodySelected: fullBodySelected,
                palette: palette,
                onAreaTap: onAreaTap,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InteractiveMuscleMap extends StatelessWidget {
  const _InteractiveMuscleMap({
    required this.data,
    required this.selectedAreas,
    required this.fullBodySelected,
    required this.palette,
    required this.onAreaTap,
  });

  final _MuscleMapData data;
  final Set<String> selectedAreas;
  final bool fullBodySelected;
  final _MuscleMapPalette palette;
  final ValueChanged<String> onAreaTap;

  // Keep base figure neutral so selected overlays stand out clearly.
  static const _neutralBodyFilter = ColorFilter.matrix(<double>[
    0.2126,
    0.7152,
    0.0722,
    0,
    42,
    0.2126,
    0.7152,
    0.0722,
    0,
    42,
    0.2126,
    0.7152,
    0.0722,
    0,
    42,
    0,
    0,
    0,
    1,
    0,
  ]);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final design = _MuscleMapRepository.designSize;
        final scale = math.min(
          constraints.maxWidth / design.width,
          constraints.maxHeight / design.height,
        );
        final mapWidth = design.width * scale;
        final mapHeight = design.height * scale;
        final dx = (constraints.maxWidth - mapWidth) / 2;
        final dy = (constraints.maxHeight - mapHeight) / 2;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (details) {
            final mapped = Offset(
              (details.localPosition.dx - dx) / scale,
              (details.localPosition.dy - dy) / scale,
            );

            if (mapped.dx < 0 ||
                mapped.dy < 0 ||
                mapped.dx > design.width ||
                mapped.dy > design.height) {
              return;
            }

            for (final patch in data.patches.reversed) {
              if (patch.path.contains(mapped)) {
                onAreaTap(patch.area);
                return;
              }
            }
          },
          child: Stack(
            children: [
              Positioned(
                left: dx,
                top: dy,
                width: mapWidth,
                height: mapHeight,
                child: ColorFiltered(
                  colorFilter: _neutralBodyFilter,
                  child: Opacity(
                    opacity: 0.93,
                    child: Image.asset(data.assetPath, fit: BoxFit.fill),
                  ),
                ),
              ),
              Positioned(
                left: dx,
                top: dy,
                width: mapWidth,
                height: mapHeight,
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _MuscleMapOverlayPainter(
                      data: data,
                      selectedAreas: selectedAreas,
                      fullBodySelected: fullBodySelected,
                      palette: palette,
                    ),
                    size: Size(mapWidth, mapHeight),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MuscleMapOverlayPainter extends CustomPainter {
  const _MuscleMapOverlayPainter({
    required this.data,
    required this.selectedAreas,
    required this.fullBodySelected,
    required this.palette,
  });

  final _MuscleMapData data;
  final Set<String> selectedAreas;
  final bool fullBodySelected;
  final _MuscleMapPalette palette;

  bool _isPatchSelected(String area) {
    if (fullBodySelected) return true;
    return selectedAreas.contains(area);
  }

  @override
  void paint(Canvas canvas, Size size) {
    final sx = size.width / _MuscleMapRepository.designSize.width;
    final sy = size.height / _MuscleMapRepository.designSize.height;

    canvas.save();
    canvas.scale(sx, sy);

    final outlinePaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.4
      ..color = palette.tapOutline;
    final activePaint = Paint()
      ..style = PaintingStyle.fill
      ..color = palette.muscleSelected;
    final activeStroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8
      ..color = palette.muscleSelectedStroke;

    for (final patch in data.patches) {
      if (_isPatchSelected(patch.area)) {
        canvas.drawPath(patch.path, activePaint);
        canvas.drawPath(patch.path, activeStroke);
      } else {
        canvas.drawPath(patch.path, outlinePaint);
      }
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _MuscleMapOverlayPainter oldDelegate) {
    if (oldDelegate.data != data ||
        oldDelegate.fullBodySelected != fullBodySelected) {
      return true;
    }
    if (oldDelegate.selectedAreas.length != selectedAreas.length) return true;
    for (final item in selectedAreas) {
      if (!oldDelegate.selectedAreas.contains(item)) return true;
    }
    return false;
  }
}

class _MuscleMapPalette {
  const _MuscleMapPalette({
    required this.card,
    required this.border,
    required this.text,
    required this.muted,
    required this.muscleSelected,
    required this.muscleSelectedStroke,
    required this.tapOutline,
  });

  final Color card;
  final Color border;
  final Color text;
  final Color muted;
  final Color muscleSelected;
  final Color muscleSelectedStroke;
  final Color tapOutline;

  factory _MuscleMapPalette.fromTheme(ThemeData theme) {
    final scheme = theme.colorScheme;
    return _MuscleMapPalette(
      card: theme.cardColor,
      border: theme.dividerColor,
      text: scheme.onSurface,
      muted: AppTheme.muted,
      muscleSelected: scheme.primary.withValues(alpha: 0.34),
      muscleSelectedStroke: scheme.primary.withValues(alpha: 0.95),
      tapOutline: AppTheme.outline.withValues(alpha: 0.5),
    );
  }
}

class _MuscleMapData {
  const _MuscleMapData({required this.assetPath, required this.patches});

  final String assetPath;
  final List<_MusclePatch> patches;
}

class _MusclePatch {
  const _MusclePatch({required this.area, required this.path});

  final String area;
  final Path path;
}

class _MuscleMapRepository {
  static const designSize = Size(960, 1344);
  static const _frontBody = Rect.fromLTRB(131, 28, 824, 1313);
  static const _backBody = Rect.fromLTRB(119, 23, 819, 1313);

  static final front = _buildFront();
  static final back = _buildBack();

  static _MuscleMapData _buildFront() {
    final b = _frontBody;
    return _MuscleMapData(
      assetPath: 'assets/onboarding/focus/muscle_front.png',
      patches: [
        _MusclePatch(
          area: 'Shoulders',
          path: _combine([
            _poly(b, [
              const Offset(0.16, 0.18),
              const Offset(0.26, 0.12),
              const Offset(0.40, 0.12),
              const Offset(0.44, 0.20),
              const Offset(0.34, 0.25),
              const Offset(0.21, 0.24),
            ]),
            _poly(b, [
              const Offset(0.84, 0.18),
              const Offset(0.74, 0.12),
              const Offset(0.60, 0.12),
              const Offset(0.56, 0.20),
              const Offset(0.66, 0.25),
              const Offset(0.79, 0.24),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Arms',
          path: _combine([
            _poly(b, [
              const Offset(0.08, 0.25),
              const Offset(0.18, 0.22),
              const Offset(0.22, 0.33),
              const Offset(0.18, 0.43),
              const Offset(0.12, 0.54),
              const Offset(0.03, 0.54),
              const Offset(0.01, 0.42),
              const Offset(0.05, 0.30),
            ]),
            _poly(b, [
              const Offset(0.92, 0.25),
              const Offset(0.82, 0.22),
              const Offset(0.78, 0.33),
              const Offset(0.82, 0.43),
              const Offset(0.88, 0.54),
              const Offset(0.97, 0.54),
              const Offset(0.99, 0.42),
              const Offset(0.95, 0.30),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Chest',
          path: _combine([
            _poly(b, [
              const Offset(0.26, 0.22),
              const Offset(0.36, 0.19),
              const Offset(0.49, 0.22),
              const Offset(0.46, 0.32),
              const Offset(0.35, 0.34),
              const Offset(0.24, 0.30),
            ]),
            _poly(b, [
              const Offset(0.51, 0.22),
              const Offset(0.64, 0.19),
              const Offset(0.74, 0.22),
              const Offset(0.76, 0.30),
              const Offset(0.65, 0.34),
              const Offset(0.54, 0.32),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Abs',
          path: _combine([
            _roundRect(b, 0.39, 0.34, 0.22, 0.23, 18),
            _poly(b, [
              const Offset(0.39, 0.57),
              const Offset(0.61, 0.57),
              const Offset(0.54, 0.67),
              const Offset(0.46, 0.67),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Legs',
          path: _combine([
            _poly(b, [
              const Offset(0.25, 0.52),
              const Offset(0.44, 0.52),
              const Offset(0.43, 0.78),
              const Offset(0.35, 0.79),
              const Offset(0.30, 0.67),
              const Offset(0.25, 0.68),
            ]),
            _poly(b, [
              const Offset(0.56, 0.52),
              const Offset(0.75, 0.52),
              const Offset(0.75, 0.68),
              const Offset(0.70, 0.67),
              const Offset(0.65, 0.79),
              const Offset(0.57, 0.78),
            ]),
            _poly(b, [
              const Offset(0.32, 0.78),
              const Offset(0.43, 0.78),
              const Offset(0.41, 0.97),
              const Offset(0.35, 0.98),
              const Offset(0.30, 0.95),
            ]),
            _poly(b, [
              const Offset(0.57, 0.78),
              const Offset(0.68, 0.78),
              const Offset(0.70, 0.95),
              const Offset(0.65, 0.98),
              const Offset(0.59, 0.97),
            ]),
          ]),
        ),
      ],
    );
  }

  static _MuscleMapData _buildBack() {
    final b = _backBody;
    return _MuscleMapData(
      assetPath: 'assets/onboarding/focus/muscle_back.png',
      patches: [
        _MusclePatch(
          area: 'Shoulders',
          path: _combine([
            _poly(b, [
              const Offset(0.16, 0.17),
              const Offset(0.27, 0.13),
              const Offset(0.40, 0.14),
              const Offset(0.44, 0.22),
              const Offset(0.32, 0.26),
              const Offset(0.21, 0.24),
            ]),
            _poly(b, [
              const Offset(0.84, 0.17),
              const Offset(0.73, 0.13),
              const Offset(0.60, 0.14),
              const Offset(0.56, 0.22),
              const Offset(0.68, 0.26),
              const Offset(0.79, 0.24),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Back',
          path: _combine([
            _poly(b, [
              const Offset(0.30, 0.24),
              const Offset(0.50, 0.27),
              const Offset(0.45, 0.53),
              const Offset(0.29, 0.56),
              const Offset(0.23, 0.43),
            ]),
            _poly(b, [
              const Offset(0.50, 0.28),
              const Offset(0.70, 0.24),
              const Offset(0.77, 0.43),
              const Offset(0.71, 0.56),
              const Offset(0.55, 0.53),
            ]),
            _poly(b, [
              const Offset(0.38, 0.21),
              const Offset(0.62, 0.21),
              const Offset(0.56, 0.35),
              const Offset(0.44, 0.35),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Arms',
          path: _combine([
            _poly(b, [
              const Offset(0.08, 0.25),
              const Offset(0.19, 0.23),
              const Offset(0.23, 0.35),
              const Offset(0.19, 0.47),
              const Offset(0.11, 0.58),
              const Offset(0.03, 0.56),
              const Offset(0.02, 0.43),
              const Offset(0.05, 0.31),
            ]),
            _poly(b, [
              const Offset(0.92, 0.25),
              const Offset(0.81, 0.23),
              const Offset(0.77, 0.35),
              const Offset(0.81, 0.47),
              const Offset(0.89, 0.58),
              const Offset(0.97, 0.56),
              const Offset(0.98, 0.43),
              const Offset(0.95, 0.31),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Glutes',
          path: _combine([
            _poly(b, [
              const Offset(0.34, 0.50),
              const Offset(0.49, 0.50),
              const Offset(0.51, 0.60),
              const Offset(0.42, 0.65),
              const Offset(0.34, 0.60),
            ]),
            _poly(b, [
              const Offset(0.51, 0.50),
              const Offset(0.66, 0.50),
              const Offset(0.66, 0.60),
              const Offset(0.58, 0.65),
              const Offset(0.49, 0.60),
            ]),
          ]),
        ),
        _MusclePatch(
          area: 'Legs',
          path: _combine([
            _poly(b, [
              const Offset(0.30, 0.62),
              const Offset(0.45, 0.62),
              const Offset(0.43, 0.84),
              const Offset(0.33, 0.86),
              const Offset(0.27, 0.77),
            ]),
            _poly(b, [
              const Offset(0.55, 0.62),
              const Offset(0.70, 0.62),
              const Offset(0.73, 0.77),
              const Offset(0.67, 0.86),
              const Offset(0.57, 0.84),
            ]),
            _poly(b, [
              const Offset(0.33, 0.84),
              const Offset(0.43, 0.84),
              const Offset(0.41, 0.98),
              const Offset(0.34, 0.99),
              const Offset(0.30, 0.94),
            ]),
            _poly(b, [
              const Offset(0.57, 0.84),
              const Offset(0.67, 0.84),
              const Offset(0.70, 0.94),
              const Offset(0.66, 0.99),
              const Offset(0.59, 0.98),
            ]),
          ]),
        ),
      ],
    );
  }

  static Rect _rect(
    Rect frame,
    double left,
    double top,
    double width,
    double height,
  ) {
    return Rect.fromLTWH(
      frame.left + frame.width * left,
      frame.top + frame.height * top,
      frame.width * width,
      frame.height * height,
    );
  }

  static Offset _point(Rect frame, Offset point) {
    return Offset(
      frame.left + frame.width * point.dx,
      frame.top + frame.height * point.dy,
    );
  }

  static Path _combine(List<Path> parts) {
    final out = Path();
    for (final path in parts) {
      out.addPath(path, Offset.zero);
    }
    return out;
  }

  static Path _roundRect(
    Rect frame,
    double left,
    double top,
    double width,
    double height,
    double radius,
  ) {
    return Path()..addRRect(
      RRect.fromRectAndRadius(
        _rect(frame, left, top, width, height),
        Radius.circular(radius),
      ),
    );
  }

  static Path _poly(Rect frame, List<Offset> points) {
    final start = _point(frame, points.first);
    final path = Path()..moveTo(start.dx, start.dy);
    for (var i = 1; i < points.length; i += 1) {
      final p = _point(frame, points[i]);
      path.lineTo(p.dx, p.dy);
    }
    path.close();
    return path;
  }
}
