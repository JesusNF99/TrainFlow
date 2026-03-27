import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/models/exercise.dart';
import '../data/models/routine.dart';
import '../services/audio_service.dart';

/// Current lifecycle status of the active workout session.
enum WorkoutStatus {
  idle,
  counting,
  paused,
  completed,
}

/// Immutable snapshot of the workout session displayed by the UI.
@immutable
class WorkoutState {
  final Routine? routine;
  final int currentExerciseIndex;
  final int remainingTime;
  final WorkoutStatus status;
  // Extra flag to track whether we're currently in the rest phase of the active exercise
  final bool isResting;
  final bool isWarmup;

  const WorkoutState({
    this.routine,
    this.currentExerciseIndex = 0,
    this.remainingTime = 0,
    this.status = WorkoutStatus.idle,
    this.isResting = false,
    this.isWarmup = false,
  });

  WorkoutState copyWith({
    Routine? routine,
    int? currentExerciseIndex,
    int? remainingTime,
    WorkoutStatus? status,
    bool? isResting,
    bool? isWarmup,
  }) {
    return WorkoutState(
      routine: routine ?? this.routine,
      currentExerciseIndex: currentExerciseIndex ?? this.currentExerciseIndex,
      remainingTime: remainingTime ?? this.remainingTime,
      status: status ?? this.status,
      isResting: isResting ?? this.isResting,
      isWarmup: isWarmup ?? this.isWarmup,
    );
  }
}

/// Riverpod [Notifier] that drives the entire workout timer engine.
///
/// Manages exercise progression, rest phases, warmup countdown, and
/// TTS/audio cues via [AudioService]. Uses a single [Timer.periodic] to
/// avoid CPU spikes (battery optimization).
class WorkoutController extends Notifier<WorkoutState> {
  Timer? _timer;

  @override
  WorkoutState build() {
    return const WorkoutState();
  }

  /// Cancels the active workout, stops any playing audio, and resets
  /// the state to [WorkoutStatus.idle].
  void abortWorkout() {
    _timer?.cancel();
    ref.read(audioServiceProvider).stopCountdownSequence();
    state = const WorkoutState();
  }

  /// Begins a new workout for the given [routine].
  ///
  /// Starts with a 5-second warmup phase, announces the first exercise
  /// name via TTS, and kicks off the countdown timer.
  void startWorkout(Routine routine) {
    if (routine.exercises.isEmpty) return;
    
    // Ensure we clear any existing timer before starting a new one
    _timer?.cancel();
    
    final firstExercise = routine.exercises.first;
    state = WorkoutState(
      routine: routine,
      currentExerciseIndex: 0,
      remainingTime: 5, // 5s preparation phase
      status: WorkoutStatus.counting,
      isResting: true, // we still show "rest"/preparation styling
      isWarmup: true,
    );
    
    // Announce simply the NEXT exercise name
    ref.read(audioServiceProvider).speak(firstExercise.name ?? '');
    
    _startTimer();
  }

  /// Toggles between [WorkoutStatus.counting] and [WorkoutStatus.paused].
  void togglePause() {
    // We can only toggle between counting and paused
    if (state.status == WorkoutStatus.counting) {
      _timer?.cancel();
      ref.read(audioServiceProvider).stopCountdownSequence();
      state = state.copyWith(status: WorkoutStatus.paused);
    } else if (state.status == WorkoutStatus.paused) {
      state = state.copyWith(status: WorkoutStatus.counting);
      _startTimer();
    }
  }

  /// Advances to the next phase: warmup → active, active → rest, or
  /// rest → next exercise. Completes the workout after the last exercise.
  void nextExercise() {
    ref.read(audioServiceProvider).stopCountdownSequence();
    final routine = state.routine;
    if (routine == null) return;

    final currentEx = routine.exercises[state.currentExerciseIndex];

    if (state.isWarmup) {
      // Warmup finished, start the actual first exercise
      state = state.copyWith(
        isWarmup: false,
        isResting: false,
        remainingTime: currentEx.type == ExerciseType.time ? currentEx.value : 0,
        status: WorkoutStatus.counting,
      );
      _startTimer();
      return;
    }

    // If finishing an active exercise and it has a rest period, transition to rest phase
    if (!state.isResting && currentEx.restTime > 0) {
      state = state.copyWith(
        remainingTime: currentEx.restTime,
        status: WorkoutStatus.counting,
        isResting: true,
      );
      
      if (state.currentExerciseIndex < routine.exercises.length - 1) {
        final nextEx = routine.exercises[state.currentExerciseIndex + 1];
        ref.read(audioServiceProvider).speak('Descanso. Siguiente: ${nextEx.name}');
      } else {
        ref.read(audioServiceProvider).speak('Descanso');
      }
      
      _startTimer();
      return;
    }

    // Move to the next exercise
    if (state.currentExerciseIndex < routine.exercises.length - 1) {
      final nextIndex = state.currentExerciseIndex + 1;
      final nextEx = routine.exercises[nextIndex];
      
      state = state.copyWith(
        currentExerciseIndex: nextIndex,
        remainingTime: nextEx.type == ExerciseType.time ? nextEx.value : 0,
        status: WorkoutStatus.counting,
        isResting: false,
      );
      
      if (currentEx.restTime == 0) {
        ref.read(audioServiceProvider).speak(nextEx.name ?? '');
      }
      
      _startTimer();
    } else {
      // Workout is complete
      _timer?.cancel();
      // Ensure we explicitly stop trusting the resting tick
      state = state.copyWith(
        status: WorkoutStatus.completed,
        remainingTime: 0,
        isResting: false,
        isWarmup: false,
      );
      ref.read(audioServiceProvider).speak('Entrenamiento completado');
    }
  }

  /// Returns to the previous phase: rest → active (same exercise),
  /// or active → previous exercise's last phase.
  void previousExercise() {
    ref.read(audioServiceProvider).stopCountdownSequence();
    final routine = state.routine;
    if (routine == null) return;

    final currentEx = routine.exercises[state.currentExerciseIndex];

    // If we are currently resting, go back to the active phase of the CURRENT exercise
    if (state.isResting) {
      if (state.isWarmup) {
        // Just restart the warmup
        state = state.copyWith(
          remainingTime: 5,
        );
        ref.read(audioServiceProvider).speak(currentEx.name ?? '');
        _startTimer();
        return;
      }
      state = state.copyWith(
        remainingTime: currentEx.type == ExerciseType.time ? currentEx.value : 0,
        status: WorkoutStatus.counting,
        isResting: false,
      );
      _startTimer();
      return;
    }

    // If we are active but not at the first exercise, go to the LAST phase of the PREVIOUS exercise
    if (state.currentExerciseIndex > 0) {
      final prevIndex = state.currentExerciseIndex - 1;
      final prevEx = routine.exercises[prevIndex];

      // If previous exercise has rest, go to its rest phase, else go to its active phase
      if (prevEx.restTime > 0) {
        state = state.copyWith(
          currentExerciseIndex: prevIndex,
          remainingTime: prevEx.restTime,
          status: WorkoutStatus.counting,
          isResting: true,
        );
      } else {
        state = state.copyWith(
          currentExerciseIndex: prevIndex,
          remainingTime: prevEx.type == ExerciseType.time ? prevEx.value : 0,
          status: WorkoutStatus.counting,
          isResting: false,
        );
      }
      _startTimer();
    } else {
      // If we are at the very first exercise, just restart it
      state = state.copyWith(
        remainingTime: currentEx.type == ExerciseType.time ? currentEx.value : 0,
        status: WorkoutStatus.counting,
        isResting: false,
      );
      _startTimer();
    }
  }

  void _startTimer() {
    // Battery Optimization: Ensure no multiple overlapping timers
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), _tick);
  }

  void _tick(Timer timer) {
    if (state.status != WorkoutStatus.counting) return;

    final routine = state.routine;
    if (routine == null) return;
    
    final currentEx = routine.exercises[state.currentExerciseIndex];

    // For rep-based exercises, if we are not resting, the timer simply stays where it is
    // and effectively "pauses" at 0 until the user manually triggers nextExercise().
    if (!state.isResting && currentEx.type == ExerciseType.reps) {
      return; 
    }

    if (state.remainingTime > 0) {
      final newTime = state.remainingTime - 1;
      state = state.copyWith(remainingTime: newTime);
      
      if (newTime == 3) {
        ref.read(audioServiceProvider).playCountdownSequence();
      }
    } else {
      // Automatically trigger the next exercise/rest block when it hits 0
      nextExercise();
    }
  }
}

/// Global Riverpod provider exposing the [WorkoutController] and its
/// current [WorkoutState] to the widget tree.
final workoutProvider = NotifierProvider<WorkoutController, WorkoutState>(
  WorkoutController.new,
);
