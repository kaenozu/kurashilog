# Import performance and privacy contract

The production import pipeline validates and inserts records in bounded batches of 500 while one database transaction remains open. A parser, validator, database, or cancellation failure rolls record insertion back; batches are not partial-success boundaries.

Analysis (clustering, summaries, insights) runs after that transaction commits, so an analysis failure or crash leaves imported records in place and a retry needs no re-parse: sourceKey deduplication makes re-running the import idempotent.

## Privacy-safe measurements

Only the following aggregate values may be recorded during private-export acceptance:

- input bytes
- elapsed preview and import time
- peak working set / RSS
- normalized visit and movement counts
- total path-point count
- added visit and movement counts
- warning codes and aggregate counts

Never record JSON fragments, coordinates, place IDs, place names, exact source timestamps, file paths, or hashes that can be linked to a private export.

## Automated acceptance

Synthetic tests cross multiple 500-record boundaries, verify source order and idempotency, and force a parser failure after a full batch to prove transaction rollback. The private 223 MB export remains an environment-only final measurement and must not be committed.
