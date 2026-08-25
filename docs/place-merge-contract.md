# Manual same-place merge contract

Issue #21 allows a user to confirm that two nearby clusters represent the same real-world place.

- A merge is explicit and reversible; proximity alone never merges places.
- Merged clusters share the existing label ID and are normalized to one effective place ID for summaries and insights.
- The secondary cluster's prior label ID is retained in app settings so split can restore it without a database migration.
- Excluded clusters or clusters with different privacy modes are not eligible for merge.
- Privacy mode changes propagate across merged members so one member cannot expose a different privacy state.
- Source records and cluster stable keys remain intact, preserving traceability across re-analysis and re-import.

This contract intentionally stores no coordinates, place names, or private Timeline payload in merge metadata.
