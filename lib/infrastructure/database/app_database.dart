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
    UserMilestones,
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
  int get schemaVersion => 4;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await m.addColumn(placeClusters, placeClusters.privacyMode);
        await customStatement(
          "UPDATE place_clusters SET privacy_mode = 'exclude' "
          'WHERE excluded = 1',
        );
      }
      if (from < 3) {
        await m.createTable(userMilestones);
      }
      if (from < 4) {
        await _addTimelineImportColumnIfMissing(
          'updated_visits',
          'INTEGER NOT NULL DEFAULT 0',
        );
        await _addTimelineImportColumnIfMissing(
          'updated_movements',
          'INTEGER NOT NULL DEFAULT 0',
        );
        await _addTimelineImportColumnIfMissing(
          'reconciliation_kind',
          "TEXT NOT NULL DEFAULT 'noChanges'",
        );
        await _addTimelineImportColumnIfMissing(
          'requires_full_reconciliation',
          'INTEGER NOT NULL DEFAULT 0',
        );
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA journal_mode = wal;');
      await customStatement('PRAGMA synchronous = normal;');
    },
  );

  Future<void> _addTimelineImportColumnIfMissing(
    String name,
    String definition,
  ) async {
    final columns = await customSelect(
      'PRAGMA table_info(timeline_imports)',
    ).get();
    if (!columns.any((row) => row.data['name'] == name)) {
      await customStatement(
        'ALTER TABLE timeline_imports ADD COLUMN $name $definition',
      );
    }
  }
}
