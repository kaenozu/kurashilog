# Durable change-point contract

Change-point candidates describe observed distribution changes; they do not infer a move, job change, health event, school change, or family event.

- Windows with insufficient coverage or too few active days are ignored.
- A candidate must persist across consecutive reliable windows.
- A one-window trip, vacation, or data anomaly followed by a return to the prior pattern is not a new life change.
- Nearby candidates are merged deterministically and retain the strongest evidence.
- Evidence is limited to changed dimensions and normalized scores.
- User-confirmed milestones are stored separately from generated candidates. Reanalysis may replace candidates but cannot silently overwrite a confirmed milestone.
