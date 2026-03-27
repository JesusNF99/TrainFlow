import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../../data/models/exercise.dart';
import '../../providers/workout_provider.dart';
import '../widgets/workout_controls.dart';
import '../widgets/workout_timer_circle.dart';

// ─────────────────────────────────────────────
//  Design Tokens
// ─────────────────────────────────────────────
const _kObsidian = Color(0xFF131313);
const _kCyan = Color(0xFF00F5FF);
const _kWhite = Color(0xDEFFFFFF);
const _kSlate = Color(0xFFA0A0A0);

class WorkoutScreen extends ConsumerStatefulWidget {
  const WorkoutScreen({super.key});

  @override
  ConsumerState<WorkoutScreen> createState() => _WorkoutScreenState();
}

class _WorkoutScreenState extends ConsumerState<WorkoutScreen> {
  @override
  void initState() {
    super.initState();
    WakelockPlus.enable();
  }

  @override
  void dispose() {
    WakelockPlus.disable();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final routine = ref.watch(workoutProvider.select((s) => s.routine));
    final status = ref.watch(workoutProvider.select((s) => s.status));
    final currentIndex = ref.watch(
      workoutProvider.select((s) => s.currentExerciseIndex),
    );
    final isResting = ref.watch(workoutProvider.select((s) => s.isResting));
    final isWarmup = ref.watch(workoutProvider.select((s) => s.isWarmup));

    if (routine == null) {
      return const Scaffold(
        backgroundColor: _kObsidian,
        body: Center(
          child: Text(
            'SIN RUTINA ACTIVA',
            style: TextStyle(color: _kSlate, fontSize: 14, letterSpacing: 4),
          ),
        ),
      );
    }

    if (status == WorkoutStatus.completed) {
      return _buildCompletionView(context);
    }

    final currentEx = routine.exercises[currentIndex];
    final routineTitle = routine.title ?? 'Rutina sin título';
    final exerciseName = currentEx.name ?? 'Ejercicio Desconocido';
    final isRepBased = currentEx.type == ExerciseType.reps;

    String displayExerciseName = exerciseName;
    if (isResting && !isWarmup) {
      if (currentIndex + 1 < routine.exercises.length) {
        displayExerciseName =
            routine.exercises[currentIndex + 1].name ?? 'Ejercicio Desconocido';
      } else {
        displayExerciseName = 'COMPLETADO';
      }
    }

    return Scaffold(
      backgroundColor: _kObsidian,
      appBar: _buildAppBar(routineTitle),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0, vertical: 16.0),
          child: Column(
            children: [
              const Spacer(),

              // ── Exercise / Rest Label ──────────────────
              _ExerciseHeader(
                isResting: isResting,
                isWarmup: isWarmup,
                exerciseName: displayExerciseName,
              ),

              const Spacer(flex: 2),

              // ── Timer Circle ───────────────────────────
              const WorkoutTimerCircle(),

              const Spacer(),

              // ── Objective Chip ─────────────────────────
              if (!isResting)
                _ObjectiveChip(
                  label: isRepBased
                      ? 'OBJETIVO: ${currentEx.value} REPS'
                      : 'OBJETIVO: ${currentEx.value} SEG',
                ),

              const Spacer(flex: 2),

              // ── Controls ───────────────────────────────
              const WorkoutControls(),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(String title) {
    return AppBar(
      backgroundColor: _kObsidian,
      elevation: 0,
      centerTitle: true,
      leading: IconButton(
        icon: const Icon(Icons.close, color: _kSlate),
        onPressed: () {
          HapticFeedback.heavyImpact();
          _confirmExit(context);
        },
      ),
      title: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: _kSlate,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Completion View
  // ─────────────────────────────────────────────

  Widget _buildCompletionView(BuildContext context) {
    return Scaffold(
      backgroundColor: _kObsidian,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Trophy with neon glow
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: _kCyan, width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: _kCyan.withValues(alpha: 0.2),
                      blurRadius: 16,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.emoji_events_rounded,
                  size: 64,
                  color: _kCyan,
                ),
              ),
              const SizedBox(height: 40),
              const Text(
                '¡ENTRENAMIENTO\nFINALIZADO!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _kWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 2,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                '¡Gran trabajo hoy!',
                style: TextStyle(
                  color: _kSlate,
                  fontSize: 16,
                  letterSpacing: 1,
                ),
              ),
              const SizedBox(height: 56),
              // Cyber-styled button
              GestureDetector(
                onTap: () {
                  HapticFeedback.heavyImpact();
                  ref.read(workoutProvider.notifier).abortWorkout();
                  Navigator.of(context).pop();
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 16,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: _kCyan, width: 1.5),
                    boxShadow: [
                      BoxShadow(
                        color: _kCyan.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Text(
                    'VOLVER AL INICIO',
                    style: TextStyle(
                      color: _kCyan,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 3,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─────────────────────────────────────────────
  //  Exit Dialog
  // ─────────────────────────────────────────────

  Future<void> _confirmExit(BuildContext context) async {
    ref.read(workoutProvider.notifier).togglePause();

    final exit = await showDialog<bool>(
      context: context,
      barrierColor: Colors.black87,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF111111),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
          side: BorderSide(color: _kCyan.withValues(alpha: 0.4)),
        ),
        title: const Text(
          '¿FINALIZAR ENTRENAMIENTO?',
          style: TextStyle(
            color: _kWhite,
            fontSize: 14,
            fontWeight: FontWeight.w700,
            letterSpacing: 2,
          ),
        ),
        content: const Text(
          'Si sales ahora, perderás tu progreso actual.',
          style: TextStyle(color: _kSlate, fontSize: 14),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text(
              'CONTINUAR',
              style: TextStyle(color: _kSlate, letterSpacing: 1.5),
            ),
          ),
          TextButton(
            onPressed: () {
              HapticFeedback.heavyImpact();
              Navigator.of(context).pop(true);
            },
            child: const Text(
              'SALIR',
              style: TextStyle(
                color: _kCyan,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
          ),
        ],
      ),
    );

    if (exit == true && context.mounted) {
      ref.read(workoutProvider.notifier).abortWorkout();
      Navigator.of(context).pop();
    }
  }
}

// ─────────────────────────────────────────────
//  Exercise Header Widget
// ─────────────────────────────────────────────

class _ExerciseHeader extends StatelessWidget {
  const _ExerciseHeader({
    required this.isResting,
    required this.isWarmup,
    required this.exerciseName,
  });

  final bool isResting;
  final bool isWarmup;
  final String exerciseName;

  @override
  Widget build(BuildContext context) {
    if (isResting) {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            isWarmup ? 'PREPÁRATE' : 'DESCANSO',
            style: const TextStyle(
              color: _kCyan,
              fontSize: 32,
              fontWeight: FontWeight.w900,
              letterSpacing: 6,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'SIGUIENTE: ${exerciseName.toUpperCase()}',
            style: const TextStyle(
              color: _kSlate,
              fontSize: 12,
              letterSpacing: 3,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      );
    }

    return Text(
      exerciseName.toUpperCase(),
      style: const TextStyle(
        color: _kWhite,
        fontSize: 28,
        fontWeight: FontWeight.w900,
        letterSpacing: 4,
      ),
      textAlign: TextAlign.center,
    );
  }
}

// ─────────────────────────────────────────────
//  Objective Chip Widget
// ─────────────────────────────────────────────

class _ObjectiveChip extends StatelessWidget {
  const _ObjectiveChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: const Color(0x2600F5FF)), // 15% cyan border
        color: const Color(0xFF201F1F), // Surface Container
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: _kSlate,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 3,
        ),
      ),
    );
  }
}
