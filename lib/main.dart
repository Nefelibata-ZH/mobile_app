import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'app/app.dart';
import 'providers/ai_config_provider.dart';
import 'services/database_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await DatabaseService.instance.init();

  final ProviderContainer container = ProviderContainer();
  // Hydrate the AI settings from secure storage before the first screen
  // reads them, so the voice-capture sheet can decide whether the mic
  // entry should be enabled on first frame.
  await container.read(aiConfigProvider.notifier).load();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ExpenseTrackerApp(),
    ),
  );
}
