# Place privacy contract

Place corrections remain traceable to source records while safe projections control what is displayed or shared.

- `visible` keeps the user label and precise in-app map point.
- `hideName` keeps the place in analysis but replaces its name and removes its category.
- `blurMap` keeps the label but quantizes the in-app map point.
- `exclude` removes the place from analysis and all projections.
- Base-place names are redacted in sharing projections even when visible in the app.
- Sharing projections never contain coordinates, stable keys, cluster IDs, source records, or private labels.
- Legacy `excluded=true` rows migrate to `privacyMode=exclude`.
- One-to-one reclustering inherits label and privacy mode; split or merged clusters do not duplicate a correction.
