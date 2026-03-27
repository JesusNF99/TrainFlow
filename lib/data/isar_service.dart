import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'models/routine.dart';

part 'isar_service.g.dart';

/// Service class to handle initializing the Isar Database.
class IsarService {
  /// Initializes the Isar database. Call this in main() before runApp().
  /// Example:
  /// ```dart
  /// final isar = await IsarService.init();
  /// runApp(ProviderScope(
  ///   overrides: [
  ///     isarProvider.overrideWithValue(isar),
  ///   ],
  ///   child: const MyApp(),
  /// ));
  /// ```
  static Future<Isar> init() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [RoutineSchema], // Embedded types like ExerciseSchema are implicitly included
      directory: dir.path,
    );
  }
}

/// Riverpod provider for the main Isar instance.
/// Must be overridden in ProviderScope after Isar initialization.
@Riverpod(keepAlive: true)
Isar isar(IsarRef ref) {
  throw UnimplementedError('isarProvider must be overridden in ProviderScope');
}
