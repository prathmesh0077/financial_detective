import 'dart:math';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

/// Custom circular gauge using CustomPainter for Truth Score display
class CircularGauge extends StatefulWidget {
  final int score;
  final double size;
  final double strokeWidth;
  final String? label;
  final bool animate;

  const CircularGauge({
    super.key,
    required this.score,
    this.size = 180,
    this.strokeWidth = 12,
    this.label,
    this.animate = true,
  });

  @override
  State<CircularGauge> createState() => _CircularGaugeState();
}

class _CircularGaugeState extends State<CircularGauge>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _animation = Tween<double>(
      begin: 0,
      end: widget.score / 100,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    ));
    if (widget.animate) {
      _controller.forward();
    } else {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(CircularGauge oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.score != widget.score) {
      _animation = Tween<double>(
        begin: _animation.value,
        end: widget.score / 100,
      ).animate(CurvedAnimation(
        parent: _controller,
        curve: Curves.easeOutCubic,
      ));
      _controller
        ..reset()
        ..forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentScore = (_animation.value * 100).round();
        return SizedBox(
          width: widget.size,
          height: widget.size,
          child: Stack(
            alignment: Alignment.center,
            children: [
              CustomPaint(
                size: Size(widget.size, widget.size),
                painter: _GaugePainter(
                  progress: _animation.value,
                  strokeWidth: widget.strokeWidth,
                  color: AppColors.scoreColor(widget.score),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$currentScore',
                    style: TextStyle(
                      fontSize: widget.size * 0.25,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimary,
                      height: 1,
                    ),
                  ),
                  Text(
                    '/100',
                    style: TextStyle(
                      fontSize: widget.size * 0.09,
                      color: AppColors.textTertiary,
                    ),
                  ),
                  if (widget.label != null) ...[
                    const SizedBox(height: 4),
                    SizedBox(
                      width: widget.size - 40, // Padding offset
                      child: Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            widget.score >= 75
                                ? Icons.verified
                                : widget.score >= 50
                                    ? Icons.info
                                    : Icons.warning,
                            color: AppColors.scoreColor(widget.score),
                            size: widget.size * 0.07,
                          ),
                          const SizedBox(width: 4),
                          Flexible(
                            child: Text(
                              widget.label!,
                              style: TextStyle(
                                fontSize: widget.size * 0.065,
                                color: AppColors.scoreColor(widget.score),
                                fontWeight: FontWeight.w600,
                              ),
                              overflow: TextOverflow.ellipsis,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _GaugePainter extends CustomPainter {
  final double progress;
  final double strokeWidth;
  final Color color;

  _GaugePainter({
    required this.progress,
    required this.strokeWidth,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Background arc
    final bgPaint = Paint()
      ..color = AppColors.border
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -pi * 0.75,
      pi * 1.5,
      false,
      bgPaint,
    );

    // Progress arc
    if (progress > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: -pi * 0.75,
          endAngle: pi * 0.75,
          colors: [
            color.withValues(alpha: 0.6),
            color,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75,
        pi * 1.5 * progress,
        false,
        progressPaint,
      );

      // Glow effect
      final glowPaint = Paint()
        ..color = color.withValues(alpha: 0.15)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth + 10
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -pi * 0.75,
        pi * 1.5 * progress,
        false,
        glowPaint,
      );
    }

    // Tick marks
    final tickPaint = Paint()
      ..color = AppColors.textTertiary.withValues(alpha: 0.3)
      ..strokeWidth = 1;

    for (var i = 0; i <= 10; i++) {
      final angle = -pi * 0.75 + (pi * 1.5 * i / 10);
      final outer = Offset(
        center.dx + (radius + strokeWidth / 2 + 4) * cos(angle),
        center.dy + (radius + strokeWidth / 2 + 4) * sin(angle),
      );
      final inner = Offset(
        center.dx + (radius + strokeWidth / 2 + 8) * cos(angle),
        center.dy + (radius + strokeWidth / 2 + 8) * sin(angle),
      );
      canvas.drawLine(outer, inner, tickPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _GaugePainter oldDelegate) =>
      oldDelegate.progress != progress || oldDelegate.color != color;
}
