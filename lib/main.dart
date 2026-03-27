import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/app_theme.dart';
import 'data/isar_service.dart';
import 'ui/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize offline-first database (Isar)
  final isarInstance = await IsarService.init();

  runApp(
    ProviderScope(
      overrides: [
        isarProvider.overrideWithValue(isarInstance),
      ],
      child: const TrainFlowApp(),
    ),
  );
}

class TrainFlowApp extends StatelessWidget {
  const TrainFlowApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TrainFlow',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(),
      home: const HomeScreen(),
    );
  }
}
