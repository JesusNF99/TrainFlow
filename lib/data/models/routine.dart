import 'package:isar/isar.dart';
import 'exercise.dart';

part 'routine.g.dart';

/// Isar collection representing a workout routine.
///
/// Contains a list of embedded [Exercise] objects. Deleting a routine
/// automatically removes its exercises.
@collection
class Routine {
  Id id = Isar.autoIncrement;

  String? title;

  String? description;

  @Index()
  List<String> tags = [];

  List<Exercise> exercises = [];

  /// Serializes this routine to a JSON-compatible map, excluding the Isar
  /// [id] so the data can be imported as a fresh object.
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'tags': tags,
      'exercises': exercises.map((e) => e.toMap()).toList(),
    };
  }

  /// Creates a [Routine] from a JSON-compatible [map].
  ///
  /// Safely handles missing or malformed `tags` and `exercises` fields.
  static Routine fromMap(Map<String, dynamic> map) {
    final rt = Routine()
      ..title = map['title'] as String?
      ..description = map['description'] as String?;

    if (map['tags'] is List) {
      rt.tags = (map['tags'] as List).map((e) => e.toString()).toList();
    }

    if (map['exercises'] is List) {
      rt.exercises = (map['exercises'] as List)
          .whereType<Map<String, dynamic>>()
          .map((e) => Exercise.fromMap(e))
          .toList();
    }

    return rt;
  }
}
