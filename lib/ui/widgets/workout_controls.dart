import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/workout_provider.dart';

const _kCyan = Color(0xFF00F5FF);
const _kSlate = Color(0xFF6B7280);

/// Cyber-minimalist playback controls with neon-glow FAB.
class WorkoutControls extends ConsumerWidget {
  const WorkoutControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final status = ref.watch(workoutProvider.select((s) => s.status));
    final isCompleted = status == WorkoutStatus.completed;

    if (isCompleted) return const SizedBox.shrink();

    final isCounting = status == WorkoutStatus.counting;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // ── Previous ────────────────────────────
        _GhostIconButton(
          icon: Icons.skip_previous_rounded,
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.read(workoutProvider.notifier).previousExercise();
          },
        ),

        // ── Play / Pause ─────────────────────────
        _NeonFab(
          icon: isCounting ? Icons.pause_rounded : Icons.play_arrow_rounded,
          onPressed: () {
            HapticFeedback.lightImpact();
            ref.read(workoutProvider.notifier).togglePause();
          },
        ),

        // ── Next ─────────────────────────────────
        _GhostIconButton(
          icon: Icons.skip_next_rounded,
          onPressed: () {
            HapticFeedback.mediumImpact();
            ref.read(workoutProvider.notifier).nextExercise();
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Ghost Icon Button (Previous / Next)
// ─────────────────────────────────────────────

class _GhostIconButton extends StatelessWidget {
  const _GhostIconButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      icon: Icon(icon),
      iconSize: 40,
      color: _kSlate,
      splashColor: _kCyan.withValues(alpha: 0.15),
      highlightColor: _kCyan.withValues(alpha: 0.08),
    );
  }
}

// ─────────────────────────────────────────────
//  Neon FAB (Play / Pause)
// ─────────────────────────────────────────────

class _NeonFab extends StatelessWidget {
  const _NeonFab({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 80,
      height: 80,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: const Color(0xFF131313),
        border: Border.all(color: _kCyan.withValues(alpha: 0.3), width: 1.5),
        boxShadow: [
          // Ambient glow
          BoxShadow(
            color: _kCyan.withValues(alpha: 0.12),
            blurRadius: 16,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onPressed,
          splashColor: _kCyan.withValues(alpha: 0.2),
          child: Icon(icon, color: _kCyan, size: 40),
        ),
      ),
    );
  }
}
