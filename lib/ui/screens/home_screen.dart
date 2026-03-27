import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/app_theme.dart';
import '../../data/models/routine.dart';
import '../../providers/routine_provider.dart';
import '../../services/backup_service.dart';
import '../widgets/routine_card.dart';
import 'routine_editor_screen.dart';

/// Home Screen — lists all [Routine] objects from Isar.
/// The stream auto-updates when routines are added, edited, or deleted.
class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  Future<void> _createRoutine(BuildContext context, WidgetRef ref) async {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const RoutineEditorScreen(routineId: null),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final routinesAsync = ref.watch(routineListProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: AppColors.background,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'TRAINFLOW',
              style: AppTextStyles.displayLarge.copyWith(
                color: AppColors.cyan,
                fontSize: 22,
              ),
            ),
            Text('Mis rutinas', style: AppTextStyles.labelSmall),
          ],
        ),
        actions: [
          PopupMenuButton<int>(
            icon: const Icon(Icons.settings, color: AppColors.muted),
            color: AppColors.surface,
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: Color(0x3300F5FF)),
            ),
            onSelected: (value) async {
              final backupService = ref.read(backupServiceProvider);
              HapticFeedback.lightImpact();
              if (value == 0) {
                try {
                  await backupService.exportRoutines();
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Error: $e')));
                  }
                }
              } else if (value == 1) {
                try {
                  await backupService.importRoutines();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Backup restored successfully',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: AppColors.cyan,
                      ),
                    );
                  }
                } catch (e) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                          'Invalid backup file. Could not restore.',
                          style: TextStyle(color: Colors.white),
                        ),
                        backgroundColor: Colors.red.shade800,
                      ),
                    );
                  }
                }
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 0,
                child: Row(
                  children: [
                    Icon(Icons.upload_file, color: AppColors.cyan, size: 20),
                    SizedBox(width: 12),
                    Text('Export/Share', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
              const PopupMenuItem(
                value: 1,
                child: Row(
                  children: [
                    Icon(Icons.file_download, color: AppColors.cyan, size: 20),
                    SizedBox(width: 12),
                    Text('Import', style: TextStyle(color: Colors.white)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: routinesAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: AppColors.cyan),
        ),
        error: (err, _) =>
            Center(child: Text('Error: $err', style: AppTextStyles.bodyMedium)),
        data: (routines) => routines.isEmpty
            ? _EmptyState(onTap: () => _createRoutine(context, ref))
            : _RoutineList(routines: routines),
      ),
      floatingActionButton: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: AppShadows.cyanGlow,
        ),
        child: FloatingActionButton(
          onPressed: () {
            HapticFeedback.lightImpact();
            _createRoutine(context, ref);
          },
          tooltip: 'Nueva rutina',
          backgroundColor: AppColors.background,
          foregroundColor: AppColors.cyan,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: const BorderSide(color: Color(0x4D00F5FF), width: 1),
          ),
          child: const Icon(Icons.add, size: 28),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Private widgets
// ---------------------------------------------------------------------------

class _RoutineList extends StatelessWidget {
  const _RoutineList({required this.routines});

  final List<Routine> routines;

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.only(top: 8, bottom: 96),
      itemCount: routines.length,
      itemBuilder: (ctx, i) =>
          RoutineCard(key: ValueKey(routines[i].id), routine: routines[i]),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.fitness_center_rounded,
              size: 72,
              color: AppColors.cyan.withValues(alpha: 0.35),
            ),
            const SizedBox(height: 24),
            Text(
              'SIN RUTINAS',
              style: AppTextStyles.titleLarge.copyWith(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            Text(
              'Toca  +  para crear tu primera rutina\ny comenzar a entrenar.',
              textAlign: TextAlign.center,
              style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
            ),
            const SizedBox(height: 32),
            OutlinedButton.icon(
              onPressed: onTap,
              icon: const Icon(Icons.add, color: AppColors.cyan),
              label: const Text(
                'CREAR RUTINA',
                style: TextStyle(
                  color: AppColors.cyan,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.cyan),
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 14,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
