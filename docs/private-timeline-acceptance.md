# Private Timeline acceptance

The remaining large-file gate uses a private Google Timeline export. The source file must stay outside the repository and must not be attached to an issue or pull request.

## Automated path

```powershell
pwsh ./tools/local_acceptance/Invoke-KurashilogPrivateTimelineAcceptance.ps1 `
  -TimelineJson D:\private\Timeline.json
```

The runner invokes `tool/acceptance/private_timeline_acceptance_test.dart` with the production schema detector, parser, validator, bounded import pipeline, SQLite repository, clustering, summaries, and insights.

It performs:

1. full Preview;
2. full Import into a temporary on-disk SQLite database;
3. visit, movement, and path-point counting;
4. second Import of the same file to prove zero additions;
5. periodic peak-RSS sampling;
6. privacy-safe JSON and Markdown report generation;
7. deletion of the temporary database.

## Evidence allowed in reports

- input byte count;
- schema type;
- Preview, Import, and re-Import elapsed milliseconds;
- peak RSS bytes;
- normalized visit and movement counts;
- total stored path-point count;
- added visit and movement counts;
- warning code and aggregate count;
- repository HEAD and PASS/BLOCKER.

## Evidence forbidden

- source JSON or fragments;
- the private file path;
- SHA or other source-file identifiers;
- coordinates;
- place names or place IDs;
- exact source timestamps;
- personal labels;
- screenshots containing private map or location information.

The wrapper replaces the private path in captured Flutter output and writes evidence only under `.acceptance/`, which is ignored by Git.

## Result interpretation

PASS means Preview and Import completed, the production analysis pipeline completed, the second Import added zero records, and a privacy-safe report was produced.

A PASS on the host process settles the 223MB parser/validator/DB/analysis memory gate. OEM file picker and physical-device UI remain separate environment checks because they exercise Android document-provider behavior rather than the import core.
