import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';

void main() {
  test('v1 legacy exclusions migrate to fail-closed privacy modes', () async {
    final directory = await Directory.systemTemp.createTemp(
      'kurashilog-privacy-migration-',
    );
    addTearDown(() => directory.delete(recursive: true));
    final path = '${directory.path}${Platform.pathSeparator}kurashilog.sqlite';

    final seed = await AppDatabase.openAtPath(path);
    await seed.customStatement('DROP TABLE place_clusters');
    await seed.customStatement('''
      CREATE TABLE place_clusters (
        id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT,
        stable_key TEXT NOT NULL UNIQUE,
        centroid_lat_e7 INTEGER NOT NULL,
        centroid_lng_e7 INTEGER NOT NULL,
        radius_m REAL NOT NULL,
        visit_count INTEGER NOT NULL,
        dwell_seconds INTEGER NOT NULL,
        first_at INTEGER NOT NULL,
        last_at INTEGER NOT NULL,
        label_id INTEGER,
        excluded INTEGER NOT NULL DEFAULT 0 CHECK (excluded IN (0, 1))
      )
    ''');
    await seed.customStatement('''
      INSERT INTO place_clusters (
        stable_key,
        centroid_lat_e7,
        centroid_lng_e7,
        radius_m,
        visit_count,
        dwell_seconds,
        first_at,
        last_at,
        excluded
      ) VALUES
        ('legacy-private', 356800000, 1397600000, 100, 1, 3600, 0, 0, 1),
        ('legacy-visible', 356900000, 1397700000, 100, 1, 3600, 0, 0, 0)
    ''');
    await seed.customStatement('PRAGMA user_version = 1');
    await seed.close();

    final migrated = await AppDatabase.openAtPath(path);
    addTearDown(migrated.close);

    final rows = await migrated.customSelect('''
      SELECT stable_key, excluded, privacy_mode
      FROM place_clusters
      ORDER BY stable_key
    ''').get();

    expect(rows, hasLength(2));
    expect(rows[0].read<String>('stable_key'), 'legacy-private');
    expect(rows[0].read<int>('excluded'), 1);
    expect(rows[0].read<String>('privacy_mode'), 'exclude');
    expect(rows[1].read<String>('stable_key'), 'legacy-visible');
    expect(rows[1].read<int>('excluded'), 0);
    expect(rows[1].read<String>('privacy_mode'), 'visible');
  });
}
