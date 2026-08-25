from pathlib import Path

path = Path('lib/application/use_cases/dashboard_use_case.dart')
text = path.read_text()
old = """      final dwell = v.endAtUtc.difference(v.startAtUtc).inMinutes;
      entries.add(
        DayTimelineEntry(
          kind: 'visit',
          startsAt: v.startAtUtc.toLocal(),
          endsAt: v.endAtUtc.toLocal(),
          placeName: v.clusterId != null ? nameById[v.clusterId] : null,
          dwellMinutes: dwell,
          latLng: (v.latE7, v.lngE7),
        ),
      );
"""
new = """      final projection = v.clusterId == null
          ? null
          : projectionById[v.clusterId];
      // A user-excluded cluster is absent from the app projection. Do not
      // resurrect its name or coordinates through day-detail drilldown.
      if (v.clusterId != null && projection == null) continue;
      final dwell = v.endAtUtc.difference(v.startAtUtc).inMinutes;
      final mapPoint = projection?.mapPoint;
      entries.add(
        DayTimelineEntry(
          kind: 'visit',
          startsAt: v.startAtUtc.toLocal(),
          endsAt: v.endAtUtc.toLocal(),
          placeName: projection?.displayName,
          dwellMinutes: dwell,
          latLng: mapPoint == null ? null : (mapPoint.latE7, mapPoint.lngE7),
        ),
      );
"""
if old not in text:
    raise SystemExit('day-detail visit block not found')
path.write_text(text.replace(old, new, 1))
