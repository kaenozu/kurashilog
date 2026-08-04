import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'tables.dart';

part 'app_database.g.dart';

/// アプリのデータベース（設計書 4.1 / 12 ビルド・リリース設計）。
@DriftDatabase(
  tables: [
    TimelineImports,
    Visits,
    Movements,
    PlaceClusters,
    PlaceLabels,
    DailySummaries,
    MonthlySummaries,
    Insights,
    AppSettings,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase(super.e);

  static Future<String> defaultPath() async {
    final directory = await getApplicationSupportDirectory();
    await directory.create(recursive: true);
    return p.join(directory.path, 'kurashilog.sqlite');
  }

  /// アプリ領域のDBを開く（テストではパスを指定できる）。
  static Future<AppDatabase> open() async => openAtPath(await defaultPath());

  static Future<AppDatabase> openAtPath(String path) async {
    final file = File(path);
    await file.parent.create(recursive: true);
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = wal;');
      await customStatement('PRAGMA synchronous = normal;');
    },
  );
}
