# Import analysis retry recovery

Timeline source records are committed before derived analysis is rebuilt so an analysis crash does not discard successfully parsed source data. This creates one important retry case: the same file may upsert zero rows on the second attempt even though clusters, summaries, and insights still need rebuilding.

The import contract therefore rebuilds derived analysis whenever a non-completed import successfully validates source records, even when the source-key upsert reports no new or updated rows. An exact file hash already marked completed still returns early and does not rebuild.

The regression test exercises the complete sequence: first attempt commits source rows and fails during analysis; the second attempt sees a no-op source-key upsert, rebuilds analysis, and then completes without duplicating source records. Exact-head CI is the merge gate for this recovery path.

This recovery path does not authorize deletion reconciliation or destructive source synchronization. Those remain separate policy work under Issue #22.
