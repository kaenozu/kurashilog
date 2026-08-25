import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/import/import_reconciliation.dart';

void main() {
  test('classifies new records after the previous end as append-only', () {
    final result = classifyImportReconciliation(
      previousLatestAt: DateTime.utc(2026, 1, 10),
      addedMinAt: DateTime.utc(2026, 1, 11),
      addedMaxAt: DateTime.utc(2026, 1, 12),
      addedRecordCount: 2,
    );

    expect(result.kind, ImportReconciliationKind.appendOnly);
    expect(result.requiresFullReconciliation, isFalse);
  });

  test('classifies new records touching existing history as overlap', () {
    final result = classifyImportReconciliation(
      previousLatestAt: DateTime.utc(2026, 1, 10),
      addedMinAt: DateTime.utc(2026, 1, 9),
      addedMaxAt: DateTime.utc(2026, 1, 12),
      addedRecordCount: 2,
    );

    expect(result.kind, ImportReconciliationKind.overlap);
    expect(result.requiresFullReconciliation, isTrue);
  });

  test('does not infer reconciliation from a true no-op import', () {
    final result = classifyImportReconciliation(
      previousLatestAt: DateTime.utc(2026, 1, 10),
      addedMinAt: null,
      addedMaxAt: null,
      addedRecordCount: 0,
    );

    expect(result.kind, ImportReconciliationKind.noChanges);
    expect(result.requiresFullReconciliation, isFalse);
  });

  test('classifies source-owned corrections as overlap without additions', () {
    final result = classifyImportReconciliation(
      previousLatestAt: DateTime.utc(2026, 1, 10),
      addedMinAt: null,
      addedMaxAt: null,
      addedRecordCount: 0,
      updatedRecordCount: 1,
    );

    expect(result.kind, ImportReconciliationKind.overlap);
    expect(result.requiresFullReconciliation, isTrue);
  });
}
