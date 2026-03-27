import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../data/models/exercise.dart';
import '../../data/models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../providers/workout_provider.dart';
import '../widgets/add_exercise_sheet.dart';
import 'workout_screen.dart';

/// Routine Editor Screen — create or edit a [Routine] and its [Exercise] list.
///
/// Receives a [routineId] that was already persisted (even if blank).
/// Uses [PopScope] to guard unsaved changes with a discard dialog.
class RoutineEditorScreen extends ConsumerStatefulWidget {
  const RoutineEditorScreen({super.key, this.routineId});

  final int? routineId;

  @override
  ConsumerState<RoutineEditorScreen> createState() =>
      _RoutineEditorScreenState();
}

class _RoutineEditorScreenState extends ConsumerState<RoutineEditorScreen> {
  // Form controllers
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _tagsController = TextEditingController();

  // Local mutable copy of the routine being edited
  Routine? _routine;
  List<Exercise> _exercises = [];

  bool _isDirty = false;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadRoutine();
    // Mark dirty on any text change
    _titleController.addListener(_markDirty);
    _descController.addListener(_markDirty);
    _tagsController.addListener(_markDirty);
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _tagsController.dispose();
    super.dispose();
  }

  void _markDirty() => setState(() => _isDirty = true);

  Future<void> _loadRoutine() async {
    if (widget.routineId == null) {
      if (!mounted) return;
      setState(() {
        _routine = Routine();
        _isLoading = false;
        _isDirty = true; // fresh but needs saving
      });
      return;
    }
    final routine = await ref
        .read(routineRepositoryProvider)
        .findById(widget.routineId!);
    if (!mounted) return;
    setState(() {
      _routine = routine;
      if (routine != null) {
        _titleController.text = routine.title ?? '';
        _descController.text = routine.description ?? '';
        _tagsController.text = routine.tags.join(', ');
        _exercises = List<Exercise>.from(routine.exercises);
      }
      _isLoading = false;
      _isDirty = false; // fresh load — not dirty yet
    });
  }

  List<String> _parseTags(String raw) {
    return raw
        .split(',')
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toList();
  }

  Future<void> _save() async {
    if (_routine == null) return;
    setState(() => _isSaving = true);

    _routine!
      ..title = _titleController.text.trim().isEmpty
          ? 'Sin título'
          : _titleController.text.trim()
      ..description = _descController.text.trim()
      ..tags = _parseTags(_tagsController.text)
      ..exercises = _exercises;

    await ref.read(routineRepositoryProvider).save(_routine!);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isDirty = false;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Rutina guardada'),
        backgroundColor: AppColors.surface,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (!_isDirty) return true;
    final discard = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Descartar cambios'),
        content: Text(
          '¿Descartar los cambios sin guardar?',
          style: AppTextStyles.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Seguir editando',
              style: TextStyle(color: AppColors.cyan),
            ),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Descartar',
              style: TextStyle(
                color: AppColors.danger,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
    return discard ?? false;
  }

  Future<void> _addExercise() async {
    final result = await showModalBottomSheet<Exercise>(
      context: context,
      isScrollControlled: true,
      backgroundColor: const Color(0xFF1E1E1E),
      elevation: 8,
      builder: (_) => const AddExerciseSheet(),
    );
    if (result != null) {
      setState(() {
        _exercises = [..._exercises, result];
        _isDirty = true;
      });
    }
  }

  void _removeExercise(int index) {
    setState(() {
      _exercises = List.from(_exercises)..removeAt(index);
      _isDirty = true;
    });
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (newIndex > oldIndex) newIndex--;
      final exercise = _exercises.removeAt(oldIndex);
      _exercises.insert(newIndex, exercise);
      _isDirty = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_isDirty,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final discard = await _onWillPop();
        if (discard && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        appBar: AppBar(
          backgroundColor: AppColors.background,
          title: Text(
            _routine?.title?.isNotEmpty == true
                ? _routine!.title!.toUpperCase()
                : 'NUEVA RUTINA',
            style: AppTextStyles.titleLarge,
          ),
          leading: BackButton(
            color: AppColors.onBackground,
            onPressed: () async {
              final shouldPop = await _onWillPop();
              if (shouldPop && context.mounted) {
                Navigator.of(context).pop();
              }
            },
          ),
          actions: [
            if (_routine != null && _exercises.isNotEmpty && !_isDirty)
              IconButton(
                icon: const Icon(Icons.play_arrow, color: AppColors.cyan),
                tooltip: 'Start Workout',
                onPressed: () {
                  HapticFeedback.lightImpact();
                  ref.read(workoutProvider.notifier).startWorkout(_routine!);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const WorkoutScreen()),
                  );
                },
              ),
            if (_isSaving)
              const Padding(
                padding: EdgeInsets.all(16),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    color: AppColors.cyan,
                    strokeWidth: 2,
                  ),
                ),
              )
            else
              TextButton(
                onPressed: _isDirty
                    ? () {
                        HapticFeedback.mediumImpact();
                        _save();
                      }
                    : null,
                child: Text(
                  'GUARDAR',
                  style: TextStyle(
                    color: _isDirty ? AppColors.cyan : AppColors.muted,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
              ),
          ],
        ),
        body: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.cyan),
              )
            : Column(
                children: [
                  // Header form
                  _HeaderForm(
                    titleController: _titleController,
                    descController: _descController,
                    tagsController: _tagsController,
                  ),
                  const SizedBox(height: 16),
                  // Exercise list header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                    child: Row(
                      children: [
                        Text('EJERCICIOS', style: AppTextStyles.labelSmall),
                        const Spacer(),
                        Text(
                          '${_exercises.length}',
                          style: AppTextStyles.labelSmall.copyWith(
                            color: AppColors.cyan,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Reorderable exercise list or empty state
                  Expanded(
                    child: _exercises.isEmpty
                        ? _ExerciseEmptyState(
                            onAdd: () {
                              HapticFeedback.lightImpact();
                              _addExercise();
                            },
                          )
                        : ReorderableListView.builder(
                            padding: const EdgeInsets.only(bottom: 100),
                            proxyDecorator: _proxyDecorator,
                            onReorder: _onReorder,
                            itemCount: _exercises.length,
                            itemBuilder: (ctx, index) {
                              final ex = _exercises[index];
                              return _ExerciseTile(
                                // Unique key is critical for ReorderableListView performance
                                key: ValueKey(
                                  '${ex.name}-$index-${widget.routineId}',
                                ),
                                exercise: ex,
                                index: index,
                                onDelete: () => _removeExercise(index),
                              );
                            },
                          ),
                  ),
                ],
              ),
        bottomNavigationBar: Padding(
          padding: EdgeInsets.only(
            left: 16.0,
            right: 16.0,
            bottom: MediaQuery.of(context).padding.bottom + 16.0,
            top: 8.0,
          ),
          child: OutlinedButton.icon(
            onPressed: () {
              HapticFeedback.lightImpact();
              _addExercise();
            },
            icon: const Icon(Icons.add),
            label: const Text(
              'EJERCICIO',
              style: TextStyle(fontWeight: FontWeight.w700, letterSpacing: 1.5),
            ),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
          ),
        ),
      ),
    );
  }

  /// Elevates the dragged card with a stronger cyan glow.
  Widget _proxyDecorator(Widget child, int index, Animation<double> animation) {
    return AnimatedBuilder(
      animation: animation,
      builder: (ctx, _) => Material(
        color: Colors.transparent,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: AppShadows.cyanGlowStrong,
          ),
          child: child,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Header form
// ---------------------------------------------------------------------------

class _HeaderForm extends StatelessWidget {
  const _HeaderForm({
    required this.titleController,
    required this.descController,
    required this.tagsController,
  });

  final TextEditingController titleController;
  final TextEditingController descController;
  final TextEditingController tagsController;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      child: Column(
        children: [
          TextFormField(
            controller: titleController,
            style: AppTextStyles.displayLarge.copyWith(color: AppColors.cyan),
            decoration: const InputDecoration(hintText: 'TÍTULO DE LA RUTINA'),
            textCapitalization: TextCapitalization.characters,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: descController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onBackground,
            ),
            decoration: const InputDecoration(
              labelText: 'Descripción (opcional)',
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          TextFormField(
            controller: tagsController,
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.onBackground,
            ),
            decoration: const InputDecoration(
              labelText: 'Etiquetas (separadas por coma)',
              hintText: 'fuerza, cardio, piernas...',
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise tile
// ---------------------------------------------------------------------------

class _ExerciseTile extends StatelessWidget {
  const _ExerciseTile({
    super.key,
    required this.exercise,
    required this.index,
    required this.onDelete,
  });

  final Exercise exercise;
  final int index;
  final VoidCallback onDelete;

  String get _typeLabel {
    final val = exercise.value;
    return exercise.type == ExerciseType.time ? '${val}s' : '$val reps';
  }

  String get _restLabel => exercise.restTime > 0
      ? 'Descanso: ${exercise.restTime}s'
      : 'Sin descanso';

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainer,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0x14FFFFFF), // 8% white
          width: 1,
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.background,
            border: Border.all(color: AppColors.cyan.withValues(alpha: 0.5)),
          ),
          child: Center(
            child: Text(
              '${index + 1}',
              style: const TextStyle(
                color: AppColors.cyan,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ),
        ),
        title: Text(
          exercise.name ?? 'Ejercicio',
          style: AppTextStyles.titleMedium,
        ),
        subtitle: Text(
          '$_typeLabel  ·  $_restLabel',
          style: AppTextStyles.labelSmall,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              icon: const Icon(
                Icons.delete_outline,
                color: AppColors.danger,
                size: 20,
              ),
              onPressed: onDelete,
              tooltip: 'Eliminar ejercicio',
            ),
            // Drag handle (ReorderableListView uses this automatically)
            ReorderableDragStartListener(
              index: index,
              child: Listener(
                onPointerDown: (_) => HapticFeedback.selectionClick(),
                child: const Icon(Icons.drag_handle, color: AppColors.muted),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Exercise empty state
// ---------------------------------------------------------------------------

class _ExerciseEmptyState extends StatelessWidget {
  const _ExerciseEmptyState({required this.onAdd});
  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.playlist_add_rounded,
            size: 56,
            color: AppColors.cyan.withValues(alpha: 0.3),
          ),
          const SizedBox(height: 16),
          Text(
            'Sin ejercicios',
            style: AppTextStyles.titleMedium.copyWith(color: AppColors.muted),
          ),
          const SizedBox(height: 8),
          Text(
            'Toca el botón + para agregar ejercicios.',
            style: AppTextStyles.bodyMedium,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
