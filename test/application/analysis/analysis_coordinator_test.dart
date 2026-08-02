import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/analysis/analysis_coordinator.dart';
import 'package:kurashilog/application/models/persistence_models.dart';
import 'package:kurashilog/infrastructure/database/app_database.dart';
import 'package:kurashilog/infrastructure/database/kurashilog_repository_impl.dart';

void main() {
  test('rebuildAll completes when visits exist', () async {
    final database = AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final repository = KurashilogRepositoryImpl(database);

    final at = DateTime.utc(2026, 7, 1, 3);
    await repository.insertNewRecords(
      visits: [
        StoredVisit(
          id: 0,
          sourceKey: 'visit-1',
          startAtUtc: at,
          endAtUtc: at.add(const Duration(hours: 1)),
          latE7: 356812360,
          lngE7: 1397671250,
        ),
        StoredVisit(
          id: 0,
          sourceKey: 'visit-2',
          startAtUtc: at.add(const Duration(days: 1)),
          endAtUtc: at.add(const Duration(days: 1, hours: 2)),
          latE7: 356812900,
          lngE7: 1397674000,
        ),
      ],
      movements: const [],
    );

    final coordinator = AnalysisCoordinator(repository: repository);
    await coordinator.rebuildAll();

    expect(await repository.countVisits(), 2);
    expect(await repository.allClusters(), isNotEmpty);
  });
}
