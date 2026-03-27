import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../data/models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../providers/workout_provider.dart';
import '../screens/routine_editor_screen.dart';
import '../screens/workout_screen.dart';

/// Displays a single [Routine] in the Home Screen list.
/// - Tap → Hero transition to [RoutineEditorScreen].
/// - Long-press → confirmation dialog → delete.
class RoutineCard extends ConsumerWidget {
  const RoutineCard({super.key, required this.routine});

  final Routine routine;

    // _confirmDelete and long press are removed in favor of Swipe-to-Delete.

  void _openEditor(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RoutineEditorScreen(routineId: routine.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final title = routine.title?.isNotEmpty == true ? routine.title! : 'Sin título';
    final exerciseCount = routine.exercises.length;
    final tags = routine.tags.take(3).toList();

    return Dismissible(
      key: ValueKey('dismiss-${routine.id}'),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
        decoration: BoxDecoration(
          color: AppColors.danger,
          borderRadius: BorderRadius.circular(8),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 24),
        child: const Icon(Icons.delete_outline, color: AppColors.onBackground, size: 28),
      ),
      confirmDismiss: (direction) async {
        return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text('Delete Routine?'),
            content: const Text('Are you sure you want to delete this routine? This cannot be undone.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: const Text('Cancel', style: TextStyle(color: AppColors.cyan)),
              ),
              TextButton(
                onPressed: () {
                  HapticFeedback.heavyImpact();
                  Navigator.of(ctx).pop(true);
                },
                child: const Text('Delete', style: TextStyle(color: AppColors.danger)),
              ),
            ],
          ),
        );
      },
      onDismissed: (_) async {
        await ref.read(routineRepositoryProvider).delete(routine.id);
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Rutina eliminada'),
            backgroundColor: AppColors.surface,
          ),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          _openEditor(context);
        },
        child: Hero(
          tag: 'routine-${routine.id}',
          child: Material(
            color: Colors.transparent,
            child: Container(
              margin: const EdgeInsets.only(bottom: 12, left: 16, right: 16),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surfaceContainer,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: const Color(0x14FFFFFF), // 8% white
                  width: 1,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // --- Content ---
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          title.toUpperCase(),
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.cyan,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),

                        // Exercise count (Small, Slate)
                        _ExerciseBadge(count: exerciseCount),

                        const SizedBox(height: 8),

                        // Tags row
                        if (tags.isNotEmpty)
                          Wrap(
                            spacing: 6,
                            runSpacing: 4,
                            children: tags
                                .map((tag) => _TagChip(label: tag))
                                .toList(),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (routine.exercises.isNotEmpty)
                    IconButton(
                      icon: const Icon(Icons.play_circle_outline),
                      color: AppColors.cyan,
                      iconSize: 32,
                      tooltip: 'Start Workout',
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        ref.read(workoutProvider.notifier).startWorkout(routine);
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                        );
                      },
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.chevron_right, color: AppColors.muted, size: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _TagChip extends StatelessWidget {
  const _TagChip({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: const Color(0x1800F5FF), // 9% cyan
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0x4400F5FF)),
      ),
      child: Text(label, style: AppTextStyles.labelSmall),
    );
  }
}

class _ExerciseBadge extends StatelessWidget {
  const _ExerciseBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$count ${count == 1 ? 'ejercicio' : 'ejercicios'}',
      style: AppTextStyles.labelSmall,
    );
  }
}
