/// Conservative classification of an import delta.
///
/// This is intentionally not a deletion policy. New records that overlap
/// existing history, and corrections to existing source-owned records, are
/// marked as requiring full reconciliation so callers cannot silently treat a
/// partial export as append-only.
enum ImportReconciliationKind { noChanges, appendOnly, overlap }

/// Whether an export is allowed to prove that an existing source record was
/// deleted.  A normal/partial export is never destructive.
enum ImportExportAuthority { partial, authoritativeSnapshot }

/// Destructive reconciliation is opt-in twice: the export must be declared
/// authoritative and the caller must explicitly confirm the operation.
enum DestructiveReconciliationPolicy { preserveMissing, deleteMissing }

class SourceReconciliation {
  const SourceReconciliation({
    required this.retainedSourceKeys,
    required this.deletedSourceKeys,
    required this.candidateSourceKeys,
    required this.destructive,
  });

  final Set<String> retainedSourceKeys;
  final Set<String> deletedSourceKeys;
  final Set<String> candidateSourceKeys;
  final bool destructive;
}

/// Reconcile stable source keys without ever treating a partial export as a
/// deletion proof. `existingSourceKeys` and `incomingSourceKeys` are opaque
/// stable IDs; no source payload or private data is required.
SourceReconciliation reconcileSourceKeys({
  required Iterable<String> existingSourceKeys,
  required Iterable<String> incomingSourceKeys,
  required ImportExportAuthority authority,
  DestructiveReconciliationPolicy policy =
      DestructiveReconciliationPolicy.preserveMissing,
  bool userConfirmed = false,
}) {
  final existing = existingSourceKeys.toSet();
  final incoming = incomingSourceKeys.toSet();
  final missing = existing.difference(incoming);
  final canDelete =
      authority == ImportExportAuthority.authoritativeSnapshot &&
      policy == DestructiveReconciliationPolicy.deleteMissing &&
      userConfirmed;
  return SourceReconciliation(
    retainedSourceKeys: canDelete ? existing.intersection(incoming) : existing,
    deletedSourceKeys: canDelete ? missing : const <String>{},
    candidateSourceKeys: canDelete ? const <String>{} : missing,
    destructive: canDelete,
  );
}

/// The minimum contract passed from import delta calculation to analysis.
/// Consumers may use affected-only analysis only when `isComplete` is true;
/// otherwise they must use the correctness-first full rebuild fallback.
class ImportImpact {
  const ImportImpact({
    this.minChangedAt,
    this.maxChangedAt,
    this.affectedSourceKeys = const <String>{},
    this.isComplete = false,
  });

  final DateTime? minChangedAt;
  final DateTime? maxChangedAt;
  final Set<String> affectedSourceKeys;
  final bool isComplete;

  bool get canUseAffectedOnly =>
      isComplete && minChangedAt != null && maxChangedAt != null;
}

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
