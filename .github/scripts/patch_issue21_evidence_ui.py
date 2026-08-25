from pathlib import Path

# Apply privacy projection to day-detail visits.
path = Path('lib/application/use_cases/dashboard_use_case.dart')
text = path.read_text()
old = """    final clusters = await repository.allClusters();
    final nameById = {for (final c in clusters) c.id: c.displayName};

    final entries = <DayTimelineEntry>[];
"""
new = """    final clusters = await repository.allClusters();
    const privacy = PlacePrivacyProjector();
    final projectionById = {
      for (final cluster in clusters) cluster.id: privacy.forApp(cluster),
    };

    final entries = <DayTimelineEntry>[];
"""
if old not in text:
    raise SystemExit('dashboard cluster projection anchor not found')
text = text.replace(old, new, 1)
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
    raise SystemExit('dashboard visit projection anchor not found')
path.write_text(text)

# Expose an explicit evidence action on month-story insight cards.
path = Path('lib/features/month_story/month_story_screen.dart')
text = path.read_text()
old = """import '../../shared/widgets.dart';
"""
new = """import '../../shared/widgets.dart';
import 'insight_evidence_screen.dart';
"""
if old not in text:
    raise SystemExit('month-story import anchor not found')
text = text.replace(old, new, 1)
old = """                child: Text(insight.body),
"""
new = """                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(insight.body),
                    if (insight.evidence.isNotEmpty) ...[
                      const SizedBox(height: KurashilogSpacing.sm),
                      Align(
                        alignment: Alignment.centerRight,
                        child: TextButton.icon(
                          icon: const Icon(Icons.fact_check_outlined),
                          label: const Text('根拠を見る'),
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => InsightEvidenceScreen(
                                yearMonth: data.yearMonth,
                                insight: insight,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
"""
if old not in text:
    raise SystemExit('month-story insight child anchor not found')
path.write_text(text)
