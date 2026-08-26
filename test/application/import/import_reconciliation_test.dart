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

  test('partial export never deletes missing source keys', () {
    final result = reconcileSourceKeys(
      existingSourceKeys: const {'a', 'b'},
      incomingSourceKeys: const {'a'},
      authority: ImportExportAuthority.partial,
      policy: DestructiveReconciliationPolicy.deleteMissing,
      userConfirmed: true,
    );

    expect(result.deletedSourceKeys, isEmpty);
    expect(result.candidateSourceKeys, {'b'});
    expect(result.retainedSourceKeys, {'a', 'b'});
    expect(result.destructive, isFalse);
  });

  test('authoritative deletion requires explicit policy and confirmation', () {
    final result = reconcileSourceKeys(
      existingSourceKeys: const {'a', 'b'},
      incomingSourceKeys: const {'a'},
      authority: ImportExportAuthority.authoritativeSnapshot,
      policy: DestructiveReconciliationPolicy.deleteMissing,
      userConfirmed: true,
    );

    expect(result.deletedSourceKeys, {'b'});
    expect(result.candidateSourceKeys, isEmpty);
    expect(result.retainedSourceKeys, {'a'});
    expect(result.destructive, isTrue);
  });

  test('incomplete impact forces full-analysis fallback', () {
    expect(
      ImportImpact(
        minChangedAt: DateTime.utc(2026, 1, 1),
        maxChangedAt: DateTime.utc(2026, 1, 2),
        isComplete: false,
      ).canUseAffectedOnly,
      isFalse,
    );
    expect(
      ImportImpact(
        minChangedAt: DateTime.utc(2026, 1, 1),
        maxChangedAt: DateTime.utc(2026, 1, 2),
        affectedSourceKeys: {'opaque-key'},
        isComplete: true,
      ).canUseAffectedOnly,
      isTrue,
    );
  });

  test('anonymous large fixture remains deterministic and bounded', () {
    final existing = List<String>.generate(10000, (i) => 'source-$i');
    final incoming = List<String>.generate(9990, (i) => 'source-$i');
    final result = reconcileSourceKeys(
      existingSourceKeys: existing,
      incomingSourceKeys: incoming,
      authority: ImportExportAuthority.authoritativeSnapshot,
      policy: DestructiveReconciliationPolicy.deleteMissing,
      userConfirmed: true,
    );

    expect(result.deletedSourceKeys, {
      'source-9990',
      'source-9991',
      'source-9992',
      'source-9993',
      'source-9994',
      'source-9995',
      'source-9996',
      'source-9997',
      'source-9998',
      'source-9999',
    });
    expect(result.retainedSourceKeys, hasLength(9990));
  });
}
