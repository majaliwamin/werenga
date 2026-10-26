import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_tokens.dart';

class EightPointStar extends StatelessWidget {
  const EightPointStar({
    super.key,
    this.size = 16,
    this.color = AppColors.gold,
    this.innerRatio = 0.44,
  });

  final double size;
  final Color color;
  final double innerRatio;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size.square(size),
      painter: _StarPainter(color: color, innerRatio: innerRatio),
    );
  }
}

class _StarPainter extends CustomPainter {
  const _StarPainter({required this.color, required this.innerRatio});

  final Color color;
  final double innerRatio;

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero);
    final outer = size.shortestSide / 2;
    final inner = outer * innerRatio;
    final path = Path();
    for (var index = 0; index < 16; index++) {
      final angle = -math.pi / 2 + index * math.pi / 8;
      final radius = index.isEven ? outer : inner;
      final point = Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _StarPainter oldDelegate) {
    return oldDelegate.color != color || oldDelegate.innerRatio != innerRatio;
  }
}

class ArabesqueDivider extends StatelessWidget {
  const ArabesqueDivider({
    super.key,
    this.color,
    this.starSize = 10,
    this.width,
  });

  final Color? color;
  final double starSize;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final lineColor = (color ?? context.palette.gold).withValues(alpha: 0.55);
    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _line(lineColor),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: EightPointStar(
            size: starSize,
            color: (color ?? context.palette.gold),
          ),
        ),
        _line(lineColor),
      ],
    );
    if (width == null) return content;
    return SizedBox(width: width, child: content);
  }

  Widget _line(Color color) {
    return Expanded(
      child: Container(
        height: 1,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color.withValues(alpha: 0), color],
          ),
        ),
      ),
    );
  }
}

class IslamicPatternPainter extends CustomPainter {
  const IslamicPatternPainter({
    required this.color,
    this.cell = 92,
    this.strokeWidth = 1,
  });

  final Color color;
  final double cell;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    final dotPaint = Paint()..color = color;

    for (var y = -cell; y < size.height + cell; y += cell) {
      for (var x = -cell; x < size.width + cell; x += cell) {
        final center = Offset(x + cell / 2, y + cell / 2);
        final half = cell * 0.28;
        final rect = Rect.fromCenter(
          center: center,
          width: half * 2,
          height: half * 2,
        );
        canvas.drawRect(rect, paint);
        canvas.save();
        canvas.translate(center.dx, center.dy);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(center: Offset.zero, width: half * 2, height: half * 2),
          paint,
        );
        canvas.restore();
        canvas.drawCircle(center, half * 0.55, paint);
        canvas.drawCircle(center, 1.5, dotPaint);
        canvas.drawCircle(Offset(center.dx + cell / 2, center.dy), 1, dotPaint);
        canvas.drawCircle(Offset(center.dx, center.dy + cell / 2), 1, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant IslamicPatternPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.cell != cell ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class ParchmentBackground extends StatelessWidget {
  const ParchmentBackground({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final isDark = context.isDark;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [palette.background, palette.backgroundAlt],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: IslamicPatternPainter(
                  color: palette.pattern.withValues(alpha: isDark ? 0.05 : 0.045),
                ),
              ),
            ),
          ),
          Positioned(
            top: -160,
            left: -80,
            right: -80,
            height: 380,
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      palette.gold.withValues(alpha: isDark ? 0.07 : 0.10),
                      palette.gold.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Positioned.fill(child: child),
        ],
      ),
    );
  }
}

class MihrabArch extends StatelessWidget {
  const MihrabArch({
    super.key,
    this.color,
    this.strokeWidth = 1.2,
    this.opacity = 1,
  });

  final Color? color;
  final double strokeWidth;
  final double opacity;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _MihrabArchPainter(
        color: (color ?? context.palette.gold).withValues(alpha: opacity),
        strokeWidth: strokeWidth,
      ),
    );
  }
}

class _MihrabArchPainter extends CustomPainter {
  const _MihrabArchPainter({required this.color, required this.strokeWidth});

  final Color color;
  final double strokeWidth;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    Path arch(double inset, double springing, double apex) {
      final left = w * inset;
      final right = w * (1 - inset);
      return Path()
        ..moveTo(left, h)
        ..lineTo(left, h * springing)
        ..cubicTo(
          left,
          h * (springing - 0.18),
          w * (inset + 0.16),
          h * (apex + 0.10),
          w * 0.5,
          h * apex,
        )
        ..cubicTo(
          w * (1 - inset - 0.16),
          h * (apex + 0.10),
          right,
          h * (springing - 0.18),
          right,
          h * springing,
        )
        ..lineTo(right, h);
    }

    canvas.drawPath(arch(0.04, 0.50, 0.035), paint);
    canvas.drawPath(
      arch(0.10, 0.54, 0.075),
      Paint()
        ..color = color.withValues(alpha: 0.45)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth,
    );

    final starCenter = Offset(w * 0.5, h * (0.035 + 0.055));
    canvas.drawCircle(
      starCenter,
      w * 0.012,
      Paint()..color = color.withValues(alpha: 0.9),
    );

    final columnPaint = Paint()
      ..color = color.withValues(alpha: 0.3)
      ..strokeWidth = strokeWidth;
    canvas.drawLine(
      Offset(w * 0.04, h * 0.84),
      Offset(w * 0.10, h * 0.84),
      columnPaint,
    );
    canvas.drawLine(
      Offset(w * 0.90, h * 0.84),
      Offset(w * 0.96, h * 0.84),
      columnPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _MihrabArchPainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.strokeWidth != strokeWidth;
  }
}

class RecordingCoverArt extends StatelessWidget {
  const RecordingCoverArt({
    super.key,
    required this.seed,
    this.size = 64,
    this.large = false,
    this.radius,
    this.glow = false,
  });

  final String seed;
  final double size;
  final bool large;
  final double? radius;
  final bool glow;

  @override
  Widget build(BuildContext context) {
    final variant = seed.codeUnits.fold<int>(0, (sum, unit) => sum + unit) % 3;
    final colors = switch (variant) {
      1 => const [AppColors.forest, AppColors.emeraldNight],
      2 => const [Color(0xFF0E5550), Color(0xFF052A25)],
      _ => const [AppColors.forestLight, AppColors.emeraldDeep],
    };
    final borderRadius = BorderRadius.circular(radius ?? size * 0.22);
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        border: Border.all(
          color: AppColors.gold.withValues(alpha: 0.55),
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: colors,
        ),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: AppColors.gold.withValues(alpha: 0.18),
                  blurRadius: size * 0.18,
                  spreadRadius: size * 0.01,
                ),
              ]
            : null,
      ),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: CustomPaint(
          painter: _CoverPainter(large: large),
        ),
      ),
    );
  }
}

class _CoverPainter extends CustomPainter {
  const _CoverPainter({required this.large});

  final bool large;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final gold = AppColors.gold;
    final line = Paint()
      ..color = gold.withValues(alpha: 0.38)
      ..style = PaintingStyle.stroke
      ..strokeWidth = large ? 1.4 : 1;

    final inset = w * 0.08;
    final frame = Rect.fromLTWH(
      inset,
      inset,
      w - inset * 2,
      h - inset * 2,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(frame, Radius.circular(w * 0.14)),
      line,
    );

    if (large) {
      final lattice = Paint()
        ..color = gold.withValues(alpha: 0.10)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1;
      for (var index = 0; index < 2; index++) {
        final rect = Rect.fromCenter(
          center: Offset(w / 2, h * 0.47),
          width: w * (0.66 - index * 0.18),
          height: h * (0.66 - index * 0.18),
        );
        canvas.save();
        canvas.translate(w / 2, h * 0.47);
        canvas.rotate(math.pi / 4);
        canvas.drawRect(
          Rect.fromCenter(
            center: Offset.zero,
            width: rect.width,
            height: rect.height,
          ),
          lattice,
        );
        canvas.restore();
        canvas.drawCircle(Offset(w / 2, h * 0.47), rect.width * 0.52, lattice);
      }
    }

    final arch = Path()
      ..moveTo(w * 0.20, h * 0.86)
      ..lineTo(w * 0.20, h * 0.50)
      ..cubicTo(w * 0.20, h * 0.33, w * 0.34, h * 0.20, w * 0.5, h * 0.12)
      ..cubicTo(w * 0.66, h * 0.20, w * 0.80, h * 0.33, w * 0.80, h * 0.50)
      ..lineTo(w * 0.80, h * 0.86);
    canvas.drawPath(arch, line);

    final starSize = w * (large ? 0.34 : 0.30);
    final center = Offset(w / 2, h * (large ? 0.48 : 0.45));
    _drawStar(canvas, center, starSize / 2, gold);
    _drawStar(
      canvas,
      center,
      starSize / 3.1,
      AppColors.emeraldNight.withValues(alpha: 0.9),
    );
    canvas.drawCircle(
      center,
      starSize * 0.085,
      Paint()..color = gold,
    );

    final book = Paint()
      ..color = gold.withValues(alpha: 0.55)
      ..style = PaintingStyle.stroke
      ..strokeWidth = large ? 1.6 : 1.1
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(
      Path()
        ..moveTo(w * 0.33, h * 0.90)
        ..quadraticBezierTo(w * 0.42, h * 0.84, w * 0.5, h * 0.90)
        ..quadraticBezierTo(w * 0.58, h * 0.84, w * 0.67, h * 0.90),
      book,
    );
    canvas.drawLine(
      Offset(w * 0.5, h * 0.90),
      Offset(w * 0.5, h * 0.94),
      book,
    );

    final dot = Paint()..color = gold.withValues(alpha: 0.65);
    canvas.drawCircle(Offset(w * 0.14, h * 0.14), large ? 1.6 : 1.2, dot);
    canvas.drawCircle(Offset(w * 0.86, h * 0.14), large ? 1.6 : 1.2, dot);
    canvas.drawCircle(Offset(w * 0.14, h * 0.86), large ? 1.6 : 1.2, dot);
    canvas.drawCircle(Offset(w * 0.86, h * 0.86), large ? 1.6 : 1.2, dot);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Color color) {
    final path = Path();
    for (var index = 0; index < 16; index++) {
      final angle = -math.pi / 2 + index * math.pi / 8;
      final pointRadius = index.isEven ? radius : radius * 0.44;
      final point = Offset(
        center.dx + pointRadius * math.cos(angle),
        center.dy + pointRadius * math.sin(angle),
      );
      if (index == 0) {
        path.moveTo(point.dx, point.dy);
      } else {
        path.lineTo(point.dx, point.dy);
      }
    }
    path.close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CoverPainter oldDelegate) {
    return oldDelegate.large != large;
  }
}
