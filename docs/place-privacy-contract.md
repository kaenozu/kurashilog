# Place privacy contract

Place corrections remain traceable to source records while safe projections control what is displayed or shared.

- `visible` keeps the user label and precise in-app map point.
- `hideName` keeps the place in analysis but replaces its name and removes its category.
- `blurMap` keeps the label but quantizes the in-app map point.
- `exclude` removes the place from analysis and all projections.
- Unknown, corrupted, or future `privacyMode` values fail closed to `exclude`; they never reveal a name, category, or precise map point.
- Base-place names are redacted in sharing projections even when visible in the app.
- Sharing projections never contain coordinates, stable keys, cluster IDs, source records, or private labels.
- Legacy `excluded=true` rows migrate to `privacyMode=exclude`.
- Legacy `excluded=false` rows retain the safe default `privacyMode=visible` during the v1-to-v2 migration.
- One-to-one reclustering inherits label and privacy mode; split or merged clusters do not duplicate a correction.
