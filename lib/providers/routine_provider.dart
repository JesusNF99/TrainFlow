import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';

import '../data/isar_service.dart';
import '../data/models/routine.dart';

// ---------------------------------------------------------------------------
// Repository
// ---------------------------------------------------------------------------

/// Handles all CRUD operations for [Routine] objects in the Isar database.
/// Exercise objects are @embedded so they live inside their parent Routine —
/// deleting a Routine automatically removes its exercises.
class RoutineRepository {
  const RoutineRepository(this._isar);

  final Isar _isar;


  /// Persists an existing [Routine] (including its embedded exercises).
  Future<void> save(Routine routine) async {
    await _isar.writeTxn(() async {
      await _isar.routines.put(routine);
    });
  }

  /// Deletes a [Routine] by its [id]. Embedded exercises are removed implicitly.
  Future<void> delete(int id) async {
    await _isar.writeTxn(() async {
      await _isar.routines.delete(id);
    });
  }

  /// Returns a [Stream] that emits the full routine list whenever Isar changes.
  Stream<List<Routine>> watchAll() {
    return _isar.routines
        .where()
        .watch(fireImmediately: true);
  }

  /// Returns one [Routine] by id (nullable if not found).
  Future<Routine?> findById(int id) => _isar.routines.get(id);
}

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

/// Exposes the [RoutineRepository] to the widget tree.
final routineRepositoryProvider = Provider<RoutineRepository>((ref) {
  final isar = ref.watch(isarProvider);
  return RoutineRepository(isar);
});

/// Reactive stream of all routines; rebuilds any consumer when the list changes.
/// Uses Isar's built-in `.watch()` for zero-polling real-time updates.
final routineListProvider = StreamProvider<List<Routine>>((ref) {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.watchAll();
});

/// Provides a single [Routine] by id, useful for the editor screen.
final routineByIdProvider =
    FutureProvider.family<Routine?, int>((ref, id) async {
  final repo = ref.watch(routineRepositoryProvider);
  return repo.findById(id);
});
