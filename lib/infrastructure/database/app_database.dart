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

  /// アプリ領域の DB を開く（テストではオーバーライドする）。
  static Future<AppDatabase> open() async {
    final dir = await getApplicationSupportDirectory();
    await dir.create(recursive: true);
    final file = File(p.join(dir.path, 'kurashilog.sqlite'));
    return AppDatabase(NativeDatabase.createInBackground(file));
  }

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
    },
  );
}
