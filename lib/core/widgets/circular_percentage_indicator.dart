import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A custom circular percentage progress indicator using [CustomPainter].
class CircularPercentageIndicator extends StatelessWidget {
  final double progress;
  final double size;
  final double strokeWidth;
  final Color? progressColor;
  final Color? trackColor;
  final TextStyle? textStyle;

  const CircularPercentageIndicator({
    super.key,
    required this.progress,
    this.size = 100.0,
    this.strokeWidth = 8.0,
    this.progressColor,
    this.trackColor,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final effectiveProgressColor = progressColor ?? theme.colorScheme.primary;
    final effectiveTrackColor =
        trackColor ?? theme.colorScheme.outlineVariant.withValues(alpha: 0.35);

    final percentageText = (progress.clamp(0.0, 1.0) * 100).toInt();

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CustomPaint(
            size: Size(size, size),
            painter: _CircularPercentagePainter(
              progress: progress.clamp(0.0, 1.0),
              strokeWidth: strokeWidth,
              progressColor: effectiveProgressColor,
              trackColor: effectiveTrackColor,
            ),
          ),
          Text(
            '$percentageText%',
            style: textStyle ??
                theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: size * 0.22,
                  color: theme.colorScheme.onSurface,
                ),
          ),
        ],
      ),
    );
  }
}

class _CircularPercentagePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color progressColor;
  final Color trackColor;

  const _CircularPercentagePainter({
    required this.progress,
    required this.strokeWidth,
    required this.progressColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (math.min(size.width, size.height) - strokeWidth) / 2;

    // 1. Draw track ring
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    canvas.drawCircle(center, radius, trackPaint);

    // 2. Draw progress sweep arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..color = progressColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      const startAngle = -math.pi / 2;
      final sweepAngle = 2 * math.pi * progress;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _CircularPercentagePainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.strokeWidth != strokeWidth ||
        oldDelegate.progressColor != progressColor ||
        oldDelegate.trackColor != trackColor;
  }
}
