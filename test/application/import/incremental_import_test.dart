import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/import/incremental_import.dart';
import 'package:kurashilog/application/models/persistence_models.dart';

void main() {
  const planner = IncrementalImportPlanner();

  test('exact completed hash skips parsing and analysis', () {
    final record = imported(
      hash: 'same',
      min: DateTime.utc(2026, 1, 1),
      max: DateTime.utc(2026, 2, 1),
    );
    final plan = planner.plan(
      fileHash: 'same',
      exactCompletedImport: record,
      latestCompletedImport: record,
      incomingSourceMinAt: DateTime.utc(2026, 1, 1),
    );

    expect(plan.mode, IncrementalImportMode.identicalFile);
    expect(plan.skipParsing, isTrue);
    expect(plan.requiresAuthoritativeReconciliation, isFalse);
  });

  test('newer disjoint range is append-only', () {
    final previous = imported(
      hash: 'old',
      min: DateTime.utc(2026, 1, 1),
      max: DateTime.utc(2026, 2, 1),
    );
    final plan = planner.plan(
      fileHash: 'new',
      exactCompletedImport: null,
      latestCompletedImport: previous,
      incomingSourceMinAt: DateTime.utc(2026, 2, 1),
    );

    expect(plan.mode, IncrementalImportMode.appendOnly);
    expect(plan.skipParsing, isFalse);
    expect(plan.requiresAuthoritativeReconciliation, isFalse);
  });

  test('overlapping different export is never treated as append-only', () {
    final previous = imported(
      hash: 'old',
      min: DateTime.utc(2026, 1, 1),
      max: DateTime.utc(2026, 3, 1),
    );
    final plan = planner.plan(
      fileHash: 'new',
      exactCompletedImport: null,
      latestCompletedImport: previous,
      incomingSourceMinAt: DateTime.utc(2026, 2, 1),
    );

    expect(plan.mode, IncrementalImportMode.overlapping);
    expect(plan.requiresAuthoritativeReconciliation, isTrue);
  });

  test('missing provenance remains an initial import', () {
    final plan = planner.plan(
      fileHash: 'first',
      exactCompletedImport: null,
      latestCompletedImport: null,
      incomingSourceMinAt: null,
    );
    expect(plan.mode, IncrementalImportMode.initial);
  });

  test('insert summary reports whether analysis work is required', () {
    const unchanged = IncrementalInsertSummary(
      addedVisits: 0,
      addedMovements: 0,
    );
    final changed = IncrementalInsertSummary(
      addedVisits: 1,
      addedMovements: 2,
      earliestAddedAt: DateTime.utc(2026, 4, 1),
      latestAddedAt: DateTime.utc(2026, 4, 3),
    );

    expect(unchanged.changed, isFalse);
    expect(changed.changed, isTrue);
    expect(changed.totalAdded, 3);
  });
}

ImportedFileRecord imported({
  required String hash,
  required DateTime min,
  required DateTime max,
}) => ImportedFileRecord(
  id: 1,
  fileHash: hash,
  schemaType: 'records',
  startedAt: min,
  completedAt: max,
  sourceMinAt: min,
  sourceMaxAt: max,
  status: 'completed',
);
