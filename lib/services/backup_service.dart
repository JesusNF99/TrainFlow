import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/isar_service.dart';
import '../data/models/routine.dart';

/// Handles JSON-based backup and restore of [Routine] data.
///
/// Export serializes all routines (excluding Isar IDs) to a shareable
/// `.json` file. Import parses a user-picked file and persists the
/// routines back into Isar.
class BackupService {
  /// Creates a [BackupService] bound to the given [Isar] instance.
  BackupService(this._isar);

  final Isar _isar;

  /// Exports all persisted routines as a JSON file and opens the
  /// platform share sheet so the user can save or send the backup.
  Future<void> exportRoutines() async {
    // 1. Fetch all routines from Isar
    final routines = await _isar.routines.where().findAll();
    
    // 2. Convert to JSON format (excluding ids so they act as fresh data on restore)
    final List<Map<String, dynamic>> mapList = routines.map((r) => r.toMap()).toList();
    final jsonString = jsonEncode(mapList);

    // 3. Write to a temporary file
    final tempDir = await getTemporaryDirectory();
    final file = File('${tempDir.path}/trainflow_backup.json');
    await file.writeAsString(jsonString);

    // 4. Trigger share sheet with the temp file
    await SharePlus.instance.share(ShareParams(
      files: [XFile(file.path)],
      text: 'TrainFlow Backup',
    ));
  }

  /// Opens a file picker for `.json` files, parses the selected backup,
  /// validates its structure, and persists the routines into Isar.
  ///
  /// Throws an [Exception] if the file format is invalid so the UI layer
  /// can display an appropriate error message.
  Future<void> importRoutines() async {
    // 1. Open FilePicker (allowing ONLY .json)
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['json'],
    );

    if (result == null || result.files.single.path == null) {
      return; // the user canceled the picker
    }

    // 2. Read and robustly parse JSON
    try {
      final file = File(result.files.single.path!);
      final jsonString = await file.readAsString();
      final decoded = jsonDecode(jsonString);

      if (decoded is! List) {
        throw const FormatException('Invalid backup format: Expected a List of routines.');
      }

      final routinesToSave = <Routine>[];
      for (final item in decoded) {
        if (item is! Map<String, dynamic>) continue;
        
        // Use fromMap to validate map structure implicitly
        final routine = Routine.fromMap(item);
        routinesToSave.add(routine);
      }

      // 3. Persist the new objects back into Isar
      await _isar.writeTxn(() async {
        await _isar.routines.putAll(routinesToSave);
      });

    } catch (e) {
      // 4. Defensive generic catch ensuring we halt import flow and re-throw
      //    so we can show the proper SnackBar up in the UI layer.
      throw Exception('Invalid backup file. Could not restore.');
    }
  }
}

/// Riverpod provider for [BackupService], wired to the app's Isar instance.
final backupServiceProvider = Provider<BackupService>((ref) {
  final isar = ref.watch(isarProvider);
  return BackupService(isar);
});
