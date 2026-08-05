import '../models/persistence_models.dart';

/// A conservative import plan derived without inspecting private record data.
enum IncrementalImportMode {
  /// The exact file has already completed successfully. No parse or analysis.
  identicalFile,

  /// The export starts after the last completed source range.
  appendOnly,

  /// The export overlaps existing provenance. Source keys remain authoritative,
  /// but deletions/corrections require a separate reconciliation pass.
  overlapping,

  /// No completed provenance exists yet.
  initial,
}

class IncrementalImportPlan {
  const IncrementalImportPlan({
    required this.mode,
    required this.skipParsing,
    required this.requiresAuthoritativeReconciliation,
    this.previousSourceMaxAt,
  });

  final IncrementalImportMode mode;
  final bool skipParsing;
  final bool requiresAuthoritativeReconciliation;
  final DateTime? previousSourceMaxAt;
}

class IncrementalImportPlanner {
  const IncrementalImportPlanner();

  IncrementalImportPlan plan({
    required String fileHash,
    required ImportedFileRecord? exactCompletedImport,
    required ImportedFileRecord? latestCompletedImport,
    required DateTime? incomingSourceMinAt,
  }) {
    if (exactCompletedImport != null &&
        exactCompletedImport.fileHash == fileHash &&
        exactCompletedImport.isCompleted) {
      return IncrementalImportPlan(
        mode: IncrementalImportMode.identicalFile,
        skipParsing: true,
        requiresAuthoritativeReconciliation: false,
        previousSourceMaxAt: latestCompletedImport?.sourceMaxAt,
      );
    }

    final previousMax = latestCompletedImport?.sourceMaxAt;
    if (latestCompletedImport == null || previousMax == null) {
      return const IncrementalImportPlan(
        mode: IncrementalImportMode.initial,
        skipParsing: false,
        requiresAuthoritativeReconciliation: false,
      );
    }

    if (incomingSourceMinAt != null && !incomingSourceMinAt.isBefore(previousMax)) {
      return IncrementalImportPlan(
        mode: IncrementalImportMode.appendOnly,
        skipParsing: false,
        requiresAuthoritativeReconciliation: false,
        previousSourceMaxAt: previousMax,
      );
    }

    return IncrementalImportPlan(
      mode: IncrementalImportMode.overlapping,
      skipParsing: false,
      requiresAuthoritativeReconciliation: true,
      previousSourceMaxAt: previousMax,
    );
  }
}

class IncrementalInsertSummary {
  const IncrementalInsertSummary({
    required this.addedVisits,
    required this.addedMovements,
    this.earliestAddedAt,
    this.latestAddedAt,
  });

  final int addedVisits;
  final int addedMovements;
  final DateTime? earliestAddedAt;
  final DateTime? latestAddedAt;

  int get totalAdded => addedVisits + addedMovements;
  bool get changed => totalAdded > 0;
}
