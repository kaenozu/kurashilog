from pathlib import Path

path = Path('lib/features/comparison/comparison_screen.dart')
text = path.read_text()
old = """    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: theme.textTheme.bodyMedium)),
          Text(
            '${coverage.representedDays}/${range.calendarDays}日 '
            '（${(ratio * 100).round()}%）',
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
"""
new = """    final labelText = Text(label, style: theme.textTheme.bodyMedium);
    final coverageText = Text(
      '${coverage.representedDays}/${range.calendarDays}日 '
      '（${(ratio * 100).round()}%）',
      textAlign: TextAlign.end,
      style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
    );
    final largeText = MediaQuery.textScalerOf(context).scale(1) >= 1.5;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: largeText
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                labelText,
                const SizedBox(height: 4),
                Align(alignment: Alignment.centerRight, child: coverageText),
              ],
            )
          : Row(
              children: [
                Expanded(child: labelText),
                const SizedBox(width: 8),
                coverageText,
              ],
            ),
    );
"""
if old not in text:
    raise SystemExit('expected coverage-row snippet not found')
path.write_text(text.replace(old, new, 1))
