import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/kurashilog_app.dart';
import 'application/providers.dart';
import 'infrastructure/database/app_database_handle.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final databaseHandle = await AppDatabaseHandle.open();
  runApp(
    ProviderScope(
      overrides: [appDatabaseHandleProvider.overrideWithValue(databaseHandle)],
      child: const KurashilogApp(),
    ),
  );
}
