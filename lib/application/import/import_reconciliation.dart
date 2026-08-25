/// Conservative classification of an import delta.
///
/// This is intentionally not a deletion policy. New records that overlap
/// existing history, and corrections to existing source-owned records, are
/// marked as requiring full reconciliation so callers cannot silently treat a
/// partial export as append-only.
enum ImportReconciliationKind { noChanges, appendOnly, overlap }

class ImportReconciliation {
  const ImportReconciliation({
    required this.kind,
    required this.requiresFullReconciliation,
  });

  final ImportReconciliationKind kind;
  final bool requiresFullReconciliation;
}

ImportReconciliation classifyImportReconciliation({
  required DateTime? previousLatestAt,
  required DateTime? addedMinAt,
  required DateTime? addedMaxAt,
  required int addedRecordCount,
  int updatedRecordCount = 0,
}) {
  // Updating an existing sourceKey is a correction to already-imported
  // history. Even with no newly added records, it must not be reported as a
  // no-op because derived analysis needs to be rebuilt and callers may need a
  // broader reconciliation pass.
  if (updatedRecordCount > 0) {
    return const ImportReconciliation(
      kind: ImportReconciliationKind.overlap,
      requiresFullReconciliation: true,
    );
  }

  if (addedRecordCount <= 0 || addedMinAt == null || addedMaxAt == null) {
    return const ImportReconciliation(
      kind: ImportReconciliationKind.noChanges,
      requiresFullReconciliation: false,
    );
  }

  // A missing previous watermark means this is the first import. Equality is
  // conservative: a record touching the previous boundary may be a source
  // correction rather than a strictly new append.
  final overlaps =
      previousLatestAt != null && !addedMinAt.isAfter(previousLatestAt);
  if (overlaps) {
    return const ImportReconciliation(
      kind: ImportReconciliationKind.overlap,
      requiresFullReconciliation: true,
    );
  }

  return const ImportReconciliation(
    kind: ImportReconciliationKind.appendOnly,
    requiresFullReconciliation: false,
  );
}
