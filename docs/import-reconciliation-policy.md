# Import reconciliation policy

This contract is deliberately independent of Timeline payloads and private
exports. Stable `sourceKey` values are opaque identifiers only.

## Deletion / authoritative policy

- A `partial` export never proves deletion. Missing keys are returned as
  `candidateSourceKeys` and existing records are retained.
- A destructive operation requires all three conditions:
  1. the input is explicitly declared `authoritativeSnapshot`;
  2. the caller selects `deleteMissing`; and
  3. the user explicitly confirms the destructive operation.
- If any condition is absent, no key is deleted. This is fail-safe for unknown
  export coverage and preserves user-owned corrections.
- The reconciliation result is a plan. Repository deletion must apply
  `deletedSourceKeys` atomically with the import transaction; candidates are
  never implicitly deleted.

## Affected-only analysis contract

`ImportImpact.canUseAffectedOnly` is true only when the changed time bounds are
known and the impact calculation is complete. Consumers must use a full,
deterministic rebuild when it is false. This prevents a partial impact estimate
from silently producing stale summaries, insights, or change points.

## Anonymous large-fixture evidence

The unit test uses 10,000 synthetic opaque keys and no coordinates, place names,
paths, hashes, timestamps, or Timeline fragments. It verifies deterministic
10-key deletion under an authoritative snapshot and is not evidence of the
real private 223 MB Timeline acceptance gate.
