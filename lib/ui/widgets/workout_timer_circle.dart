import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/exercise.dart';
import '../../providers/workout_provider.dart';

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
const _kCyan = Color(0xFF00F5FF);
const _kNeonLime = Color(0xFFCCFF00);
const _kTrackColor = Color(0xFF1C1B1B);

/// A high-contrast, neon-glow timer circle that renders a custom arc
/// with a gradient sweep and an optional warn-pulse animation.
class WorkoutTimerCircle extends ConsumerStatefulWidget {
  const WorkoutTimerCircle({super.key});

  @override
  ConsumerState<WorkoutTimerCircle> createState() => _WorkoutTimerCircleState();
}

class _WorkoutTimerCircleState extends ConsumerState<WorkoutTimerCircle>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _pulseAnimation = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  void _handleWarning(bool isWarning) {
    if (isWarning && !_pulseController.isAnimating) {
      _pulseController.repeat(reverse: true);
    } else if (!isWarning && _pulseController.isAnimating) {
      _pulseController
        ..stop()
        ..value = 1.0;
    }
  }

  @override
  Widget build(BuildContext context) {
    final remainingTime = ref.watch(
      workoutProvider.select((s) => s.remainingTime),
    );
    final status = ref.watch(workoutProvider.select((s) => s.status));
    final isResting = ref.watch(workoutProvider.select((s) => s.isResting));
    final isWarmup = ref.watch(workoutProvider.select((s) => s.isWarmup));
    final routine = ref.watch(workoutProvider.select((s) => s.routine));
    final currentIndex = ref.watch(
      workoutProvider.select((s) => s.currentExerciseIndex),
    );

    if (routine == null || routine.exercises.isEmpty) {
      return const SizedBox.shrink();
    }

    final currentEx = routine.exercises[currentIndex];

    final int totalTime = isWarmup
        ? 5
        : (isResting
              ? currentEx.restTime
              : (currentEx.type == ExerciseType.time ? currentEx.value : 1));

    final double progress = totalTime > 0
        ? (remainingTime / totalTime).clamp(0.0, 1.0)
        : 0.0;

    final bool isWarning =
        remainingTime <= 5 &&
        remainingTime > 0 &&
        (isResting || currentEx.type == ExerciseType.time);

    _handleWarning(isWarning);

    final Color accentColor = isWarning ? _kNeonLime : _kCyan;

    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        final double scale = isWarning ? _pulseAnimation.value : 1.0;
        return Transform.scale(
          scale: scale,
          child: AspectRatio(
            aspectRatio: 1.0,
            child: Stack(
              fit: StackFit.expand,
              children: [
                TweenAnimationBuilder<double>(
                  tween: Tween<double>(begin: progress, end: progress),
                  duration: const Duration(seconds: 1),
                  curve: Curves.linear,
                  builder: (context, animatedProgress, _) {
                    return Stack(
                      fit: StackFit.expand,
                      children: [
                        // Neon glow layer (slightly larger, blurred)
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CustomPaint(
                            painter: _NeonArcPainter(
                              progress: animatedProgress,
                              accentColor: accentColor.withValues(
                                alpha: 0.10,
                              ), // Max 10% opacity blur
                              strokeWidth: 12,
                              isGlowLayer: true,
                            ),
                          ),
                        ),
                        // Main arc layer
                        Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: CustomPaint(
                            painter: _NeonArcPainter(
                              progress: animatedProgress,
                              accentColor: accentColor,
                              strokeWidth: 3, // Thin 3px max stroke
                              isGlowLayer: false,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                // Center content
                Center(
                  child: _buildCenterContent(
                    context,
                    currentEx,
                    isResting,
                    remainingTime,
                    status,
                    isWarning,
                    accentColor,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildCenterContent(
    BuildContext context,
    Exercise currentEx,
    bool isResting,
    int remainingTime,
    WorkoutStatus status,
    bool isWarning,
    Color accentColor,
  ) {
    // Rep-based: show a check icon + rep count
    if (!isResting && currentEx.type == ExerciseType.reps) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.check_circle_outline, size: 56, color: _kCyan),
          const SizedBox(height: 8),
          Text(
            '${currentEx.value}',
            style: const TextStyle(
              fontFamily: 'monospace',
              fontSize: 52,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -2,
            ),
          ),
          const Text(
            'REPS',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Color(0xFF6B7280),
              letterSpacing: 4,
            ),
          ),
        ],
      );
    }

    // Time-based: show MM:SS
    final minutes = (remainingTime / 60).floor();
    final seconds = remainingTime % 60;
    final timeString =
        '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 58,
            fontWeight: FontWeight.w900,
            color: accentColor,
            letterSpacing: isWarning ? 4 : 0,
            fontFeatures: const [FontFeature.tabularFigures()],
          ),
          child: Text(timeString),
        ),
        if (status == WorkoutStatus.paused)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              'PAUSED',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Color(0xFF6B7280),
                letterSpacing: 4,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Custom Painter — Neon Arc
// ─────────────────────────────────────────────

class _NeonArcPainter extends CustomPainter {
  const _NeonArcPainter({
    required this.progress,
    required this.accentColor,
    required this.strokeWidth,
    required this.isGlowLayer,
  });

  final double progress;
  final Color accentColor;
  final double strokeWidth;
  final bool isGlowLayer;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - strokeWidth / 2;
    const startAngle = -math.pi / 2; // 12 o'clock
    final sweepAngle = 2 * math.pi * progress;

    // ── Track (background ring) ───────────────
    final trackPaint = Paint()
      ..color = _kTrackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = isGlowLayer ? strokeWidth : strokeWidth
      ..strokeCap = StrokeCap.butt;

    if (!isGlowLayer) {
      canvas.drawCircle(center, radius, trackPaint);
    }

    if (progress <= 0) return;

    // ── Arc ───────────────────────────────────
    final rect = Rect.fromCircle(center: center, radius: radius);

    if (isGlowLayer) {
      // Soft glow: wide, blurred stroke with low opacity
      final glowPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [accentColor.withValues(alpha: 0.0), accentColor],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);

      canvas.drawArc(rect, startAngle, sweepAngle, false, glowPaint);
    } else {
      // Sharp arc with gradient from dim → full cyan
      final arcPaint = Paint()
        ..shader = SweepGradient(
          startAngle: startAngle,
          endAngle: startAngle + sweepAngle,
          colors: [accentColor.withValues(alpha: 0.3), accentColor],
          transform: const GradientRotation(-math.pi / 2),
        ).createShader(rect)
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(rect, startAngle, sweepAngle, false, arcPaint);

      // Leading dot — a bright point at the arc tip
      if (sweepAngle > 0.05) {
        final tipAngle = startAngle + sweepAngle;
        final tipX = center.dx + radius * math.cos(tipAngle);
        final tipY = center.dy + radius * math.sin(tipAngle);
        final dotPaint = Paint()
          ..color = accentColor
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(Offset(tipX, tipY), strokeWidth / 1.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(_NeonArcPainter old) =>
      old.progress != progress ||
      old.accentColor != accentColor ||
      old.strokeWidth != strokeWidth;
}
