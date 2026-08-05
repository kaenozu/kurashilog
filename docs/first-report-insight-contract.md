# First report insight contract

The first report is deterministic and privacy-safe.

- It emits at most five cards and does not invent filler when evidence is insufficient.
- Coverage and data quality are always shown before trend claims.
- Base, private, and explicitly excluded clusters cannot appear in ranked place copy.
- Place ties are resolved by stable cluster ID so the same input produces the same result.
- Evidence stores stable references such as `cluster:<id>` or metric keys; it does not store coordinates, raw Timeline records, or private labels.
- `quiteLow` and `historyOnly` quality suppress change claims while factual coverage and eligible place counts may still be shown.
- Existing home and month-story selection APIs remain available for backward compatibility.
