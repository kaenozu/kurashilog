# Insight evidence navigation contract

Issue #21 insights must not stop at a derived number. Evidence references are resolved to source-backed days and opened through the existing day-detail flow. If a place is hidden, blurred, or excluded, the day-detail projection must apply the same privacy policy before displaying a name or map coordinate.

The evidence UI must therefore preserve these invariants:

- insight evidence resolves to dates that actually contain supporting visits or movements;
- evidence navigation opens the existing day-detail screen rather than a synthetic record view;
- `hideName` redacts the displayed place name;
- `blurMap` exposes only the projected map point;
- `exclude` does not expose that place through day-detail evidence;
- raw private coordinates or Timeline payloads are never copied into insight metadata.
