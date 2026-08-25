from pathlib import Path

path = Path('lib/application/use_cases/import_use_case.dart')
text = path.read_text()
old = """      // Source corrections change the same derived surfaces as additions.
      // Rebuild on either kind of material delta so updated records never
      // leave stale clusters, summaries, or insights behind.
      final changedRecordCount =
          addedVisits + addedMovements + updatedVisits + updatedMovements;
      if (changedRecordCount > 0) {
        onProgress?.call(
          const ImportProgress(ImportStage.clustering, percent: 75),
        );
        await analysis.rebuildAll();
      }
"""
new = """      // Source corrections change the same derived surfaces as additions.
      // A previous attempt may also have committed source-owned rows and then
      // failed during analysis. In that retry, sourceKey upsert reports zero
      // delta even though derived state still needs repair. Because an exact
      // completed file hash returned above, any non-empty import reaching this
      // point is safe to rebuild: it is either a material delta or recovery of
      // an incomplete/overlapping import.
      final changedRecordCount =
          addedVisits + addedMovements + updatedVisits + updatedMovements;
      final hasValidatedSourceRecords = sourceMinAt != null || sourceMaxAt != null;
      if (changedRecordCount > 0 || hasValidatedSourceRecords) {
        onProgress?.call(
          const ImportProgress(ImportStage.clustering, percent: 75),
        );
        await analysis.rebuildAll();
      }
"""
if old not in text:
    raise SystemExit('analysis rebuild block not found')
path.write_text(text.replace(old, new, 1))
