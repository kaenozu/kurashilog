# Life report card contract

This is the shared presentation-neutral contract for #17 insights and #20
report components. It does not add persistence or change the analysis
coordinator.

## `LifeReportCard`

Every card has:

- a deterministic `id` and explicit `kind`;
- structured `supportingFacts` rather than UI-owned aggregation;
- a calendar `period` using the existing start-inclusive/end-exclusive model;
- `ComparisonQuality` (`comparable`, `referenceOnly`, or `insufficient`);
- `ReportConfidence` (`fact`, `inference`, or `userConfirmed`);
- an `EvidenceRef` whose period matches the card period; and
- an explicit privacy projection state.

A card with insufficient evidence must not invent a conclusion. Callers should
omit it or provide an explicit `unavailableReason`. The five primary kinds are
`coverage`, `topPlace`, `largestChange`, `disappearedPlace`, and
`changePeriod`; `fallback` is reserved for a deterministic high-confidence
replacement.

## `EvidenceRef`

Evidence contains only stable metric, cluster, or source references and the
effective period. The references are resolved inside the app. Raw Timeline
payloads, coordinates, file paths, place names, detailed timestamps, and
private labels must not be placed in this model, logs, fixtures, PRs, or Issue
comments.

## Ownership rules

- Domain code supplies the facts, quality, confidence, privacy state, and
  evidence.
- Widgets render the contract and do not recompute metrics or privacy rules.
- #17 generators may create cards from anonymous deterministic fixtures.
- #19 change candidates may be adapted to `changePeriod`; they must not
  duplicate comparison math from #18.
- #21 and #22 may add persistence later, but this contract itself has no DB
  migration or cache requirement.
