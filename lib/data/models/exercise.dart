import 'package:isar/isar.dart';

part 'exercise.g.dart';

/// Defines how an exercise's [Exercise.value] is interpreted.
enum ExerciseType { reps, time }

/// Isar embedded object representing a single exercise within a [Routine].
///
/// - [type] determines whether [value] represents repetitions or seconds.
/// - [restTime] is the pause (in seconds) after this exercise completes.
/// - [soundAlert] controls whether an audio cue fires at the end.
@embedded
class Exercise {
  int? id;

  String? name;

  @Enumerated(EnumType.name)
  ExerciseType type = ExerciseType.time;

  int value = 0;

  int restTime = 0;

  bool soundAlert = true;

  /// Serializes this exercise to a JSON-compatible map for backup export.
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'type': type.name,
      'value': value,
      'restTime': restTime,
      'soundAlert': soundAlert,
    };
  }

  /// Creates an [Exercise] from a JSON-compatible [map].
  ///
  /// Falls back to sensible defaults when fields are missing or malformed.
  static Exercise fromMap(Map<String, dynamic> map) {
    ExerciseType parsedType = ExerciseType.time;
    final typeStr = map['type'] as String?;
    if (typeStr != null) {
      try {
        parsedType = ExerciseType.values.byName(typeStr);
      } catch (_) {}
    }
    return Exercise()
      ..name = map['name'] as String?
      ..type = parsedType
      ..value = map['value'] as int? ?? 0
      ..restTime = map['restTime'] as int? ?? 0
      ..soundAlert = map['soundAlert'] as bool? ?? true;
  }
}
