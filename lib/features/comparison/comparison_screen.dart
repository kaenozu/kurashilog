import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/design_system.dart';
import '../../application/providers.dart';
import '../../application/use_cases/comparison_use_case.dart';
import '../../domain/models/comparison.dart';

/// 任意2期間比較画面（Issue #18）。
///
/// 期間A / 期間B を選択し、公平な比較条件（アライメント・充足度・品質）を
/// 明示したうえで結果を表示する。UI は集計ロジックを持たず、ドメインの
/// [PeriodComparison] をそのまま表示する。
class ComparisonScreen extends ConsumerWidget {
  const ComparisonScreen({super.key});

  static const supportedMetrics = [
    ComparisonMetricId.visitCount,
    ComparisonMetricId.uniquePlaces,
    ComparisonMetricId.dwellDuration,
    ComparisonMetricId.outsideHomeDays,
    ComparisonMetricId.movementDistance,
    ComparisonMetricId.movementDuration,
    ComparisonMetricId.recurringPlaceCount,
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = ref.watch(comparisonResultProvider);
    final presets = ref.watch(comparisonPresetsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('期間比較')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _PresetNoteCard(),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _PeriodPickRow(label: '期間A', which: _PeriodSlot.a),
                  const SizedBox(height: 16),
                  const _PeriodPickRow(label: '期間B', which: _PeriodSlot.b),
                  const SizedBox(height: 8),
                  Text('比較モード', style: Theme.of(context).textTheme.labelLarge),
                  const SizedBox(height: 4),
                  const _AlignmentSelector(),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: () => _runComparison(context, ref),
                    icon: const Icon(Icons.compare_arrows),
                    label: const Text('比較する'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          if (result.isLoading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (result.hasError)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text('比較に失敗しました: ${result.error}'),
              ),
            )
          else if (result.hasValue && result.value != null)
            _ComparisonResultView(
              comparison: result.value!,
              onSave: () => _savePreset(context, ref, result.value!),
            ),
          const SizedBox(height: 12),
          Text('保存済みの比較', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          presets.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Text('読み込みに失敗しました: $e'),
            data: (list) => list.isEmpty
                ? const Text('保存済みの比較はありません')
                : Column(
                    children: [
                      for (final preset in list) _PresetTile(preset: preset),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  void _runComparison(BuildContext context, WidgetRef ref) {
    final a = ref.read(periodAStateProvider);
    final b = ref.read(periodBStateProvider);
    final alignment = ref.read(comparisonAlignmentProvider);
    if (a == null || b == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('期間A と期間B の両方を選択してください')));
      return;
    }
    final request = ComparisonRequest(
      periodA: a,
      periodB: b,
      alignment: alignment,
      metrics: supportedMetrics.toSet(),
    );
    ref.read(comparisonRequestProvider.notifier).state = request;
    ref.invalidate(comparisonResultProvider);
  }

  Future<void> _savePreset(
    BuildContext context,
    WidgetRef ref,
    PeriodComparison comparison,
  ) async {
    final name = await _promptName(context, '比較を保存', '比較の名前');
    if (name == null || name.trim().isEmpty) return;
    try {
      await ref
          .read(comparisonUseCaseProvider)
          .savePreset(name: name.trim(), request: comparison.request);
      ref.invalidate(comparisonPresetsProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('比較を保存しました')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('保存に失敗しました')));
      }
    }
  }

  Future<String?> _promptName(
    BuildContext context,
    String title,
    String label,
  ) => showDialog<String>(
    context: context,
    builder: (context) => _NameDialog(title: title, label: label),
  );
}

class _NameDialog extends StatefulWidget {
  const _NameDialog({required this.title, required this.label});

  final String title;
  final String label;

  @override
  State<_NameDialog> createState() => _NameDialogState();
}

class _NameDialogState extends State<_NameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: TextField(
        controller: _controller,
        autofocus: true,
        decoration: InputDecoration(labelText: widget.label),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: () => Navigator.of(context).pop(_controller.text),
          child: const Text('保存'),
        ),
      ],
    );
  }
}

enum _PeriodSlot { a, b }

final periodAStateProvider = StateProvider<LocalDateRange?>((ref) => null);
final periodBStateProvider = StateProvider<LocalDateRange?>((ref) => null);
final comparisonAlignmentProvider = StateProvider<ComparisonAlignment>(
  (ref) => ComparisonAlignment.exact,
);
final comparisonRequestProvider = StateProvider<ComparisonRequest?>(
  (ref) => null,
);

/// 選択済みリクエストの比較結果。リクエスト未選択時は null。
final comparisonResultProvider = FutureProvider<PeriodComparison?>((ref) async {
  final request = ref.watch(comparisonRequestProvider);
  if (request == null) return null;
  return ref.watch(comparisonUseCaseProvider).run(request);
});

/// 保存済みプリセット一覧。
final comparisonPresetsProvider = FutureProvider<List<SavedComparisonPreset>>(
  (ref) => ref.watch(comparisonUseCaseProvider).loadPresets(),
);

class _PresetNoteCard extends ConsumerWidget {
  const _PresetNoteCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final today = LocalDate(now.year, now.month, now.day);
    return Card(
      color: Theme.of(context).colorScheme.secondaryContainer,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'クイック選択（今日: ${today.toIso8601String()}）',
              style: Theme.of(context).textTheme.titleSmall,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _QuickPresetButton(
                  label: '今年と去年（経過日数一致）',
                  make: (now) {
                    final a = LocalDateRange(
                      startInclusive: LocalDate(now.year, 1, 1),
                      endExclusive: LocalDate(
                        now.year,
                        now.month,
                        now.day,
                      ).addDays(1),
                      timeZoneId: now.timeZoneName,
                    );
                    final b = LocalDateRange(
                      startInclusive: LocalDate(now.year - 1, 1, 1),
                      endExclusive: LocalDate(
                        now.year - 1,
                        now.month,
                        now.day,
                      ).addDays(1),
                      timeZoneId: now.timeZoneName,
                    );
                    return (a: a, b: b, alignment: ComparisonAlignment.exact);
                  },
                ),
                _QuickPresetButton(
                  label: '先月と先々月',
                  make: (now) {
                    final prev = DateTime(now.year, now.month - 1, 1);
                    final prevPrev = DateTime(now.year, now.month - 2, 1);
                    final a = LocalDateRange.month(
                      year: prev.year,
                      month: prev.month,
                      timeZoneId: now.timeZoneName,
                    );
                    final b = LocalDateRange.month(
                      year: prevPrev.year,
                      month: prevPrev.month,
                      timeZoneId: now.timeZoneName,
                    );
                    return (
                      a: a,
                      b: b,
                      alignment: ComparisonAlignment.sameMonth,
                    );
                  },
                ),
                _QuickPresetButton(
                  label: '同じ季節（今年と去年）',
                  make: (now) {
                    final (season, year) = _seasonOf(
                      LocalDate(now.year, now.month, now.day),
                    );
                    final a = LocalDateRange.season(
                      seasonYear: year,
                      season: season,
                      timeZoneId: now.timeZoneName,
                    );
                    final b = LocalDateRange.season(
                      seasonYear: year - 1,
                      season: season,
                      timeZoneId: now.timeZoneName,
                    );
                    return (
                      a: a,
                      b: b,
                      alignment: ComparisonAlignment.sameSeason,
                    );
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

(ComparisonSeason, int) _seasonOf(LocalDate date) {
  if (date.month >= 3 && date.month <= 5) {
    return (ComparisonSeason.spring, date.year);
  }
  if (date.month >= 6 && date.month <= 8) {
    return (ComparisonSeason.summer, date.year);
  }
  if (date.month >= 9 && date.month <= 11) {
    return (ComparisonSeason.autumn, date.year);
  }
  return (ComparisonSeason.winter, date.month <= 2 ? date.year - 1 : date.year);
}

class _QuickPresetButton extends ConsumerWidget {
  const _QuickPresetButton({required this.label, required this.make});

  final String label;
  final ({LocalDateRange a, LocalDateRange b, ComparisonAlignment alignment})
  Function(DateTime now)
  make;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ActionChip(
      label: Text(label),
      onPressed: () {
        final preset = make(DateTime.now());
        ref.read(periodAStateProvider.notifier).state = preset.a;
        ref.read(periodBStateProvider.notifier).state = preset.b;
        ref.read(comparisonAlignmentProvider.notifier).state = preset.alignment;
        ref.read(comparisonRequestProvider.notifier).state = null;
        ref.invalidate(comparisonResultProvider);
      },
    );
  }
}

class _PeriodPickRow extends ConsumerWidget {
  const _PeriodPickRow({required this.label, required this.which});

  final String label;
  final _PeriodSlot which;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(
      which == _PeriodSlot.a ? periodAStateProvider : periodBStateProvider,
    );
    return Row(
      children: [
        SizedBox(
          width: 56,
          child: Text(label, style: Theme.of(context).textTheme.labelLarge),
        ),
        Expanded(
          child: OutlinedButton(
            onPressed: () => _pickRange(context, ref),
            child: Text(
              range == null
                  ? '期間を選択'
                  : '${range.startInclusive.toIso8601String()} 〜 '
                        '${range.endExclusive.addDays(-1).toIso8601String()} '
                        '（${range.calendarDays}日）',
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _pickRange(BuildContext context, WidgetRef ref) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(now.year + 1, 12, 31),
      initialDateRange: null,
      helpText: '$label の期間を選択',
    );
    if (picked == null) return;
    final range = LocalDateRange(
      startInclusive: LocalDate(
        picked.start.year,
        picked.start.month,
        picked.start.day,
      ),
      endExclusive: LocalDate(
        picked.end.year,
        picked.end.month,
        picked.end.day,
      ).addDays(1),
      timeZoneId: now.timeZoneName,
    );
    ref
            .read(
              (which == _PeriodSlot.a
                      ? periodAStateProvider
                      : periodBStateProvider)
                  .notifier,
            )
            .state =
        range;
  }
}

class _AlignmentSelector extends ConsumerWidget {
  const _AlignmentSelector();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alignment = ref.watch(comparisonAlignmentProvider);
    return SegmentedButton<ComparisonAlignment>(
      segments: const [
        ButtonSegment(
          value: ComparisonAlignment.exact,
          label: Text('そのまま'),
          icon: Icon(Icons.tune),
        ),
        ButtonSegment(
          value: ComparisonAlignment.sameElapsedDays,
          label: Text('経過日一致'),
          icon: Icon(Icons.calendar_today),
        ),
        ButtonSegment(
          value: ComparisonAlignment.sameMonth,
          label: Text('同月'),
          icon: Icon(Icons.calendar_month),
        ),
        ButtonSegment(
          value: ComparisonAlignment.sameSeason,
          label: Text('同季節'),
          icon: Icon(Icons.forest),
        ),
      ],
      selected: {alignment},
      onSelectionChanged: (selection) {
        ref.read(comparisonAlignmentProvider.notifier).state = selection.first;
      },
    );
  }
}

class _PresetTile extends ConsumerWidget {
  const _PresetTile({required this.preset});

  final SavedComparisonPreset preset;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = preset.request;
    return Card(
      child: ListTile(
        title: Text(preset.name),
        subtitle: Text(
          '${request.periodA.startInclusive.toIso8601String()}〜'
          '${request.periodB.startInclusive.toIso8601String()}',
        ),
        trailing: IconButton(
          icon: const Icon(Icons.delete_outline),
          tooltip: '削除',
          onPressed: () async {
            await ref.read(comparisonUseCaseProvider).deletePreset(preset.id);
            ref.invalidate(comparisonPresetsProvider);
          },
        ),
        onTap: () {
          ref.read(periodAStateProvider.notifier).state = request.periodA;
          ref.read(periodBStateProvider.notifier).state = request.periodB;
          ref.read(comparisonAlignmentProvider.notifier).state =
              request.alignment;
          ref.read(comparisonRequestProvider.notifier).state = request;
          ref.invalidate(comparisonResultProvider);
        },
      ),
    );
  }
}

class _ComparisonResultView extends ConsumerWidget {
  const _ComparisonResultView({required this.comparison, required this.onSave});

  final PeriodComparison comparison;
  final VoidCallback onSave;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final alignment = comparison.alignment;
    final qualityLabel = switch (comparison.overallQuality) {
      ComparisonQuality.comparable => '比較可能',
      ComparisonQuality.referenceOnly => '参考値',
      ComparisonQuality.insufficient => '比較不能',
    };

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const JournalSectionHeader(
          eyebrow: '期間比較',
          title: '比較のまとめ',
          supportingText: '実効期間と記録の充足度を確認してから、指標の変化を読み取れます。',
        ),
        const SizedBox(height: KurashilogSpacing.md),
        JournalCard(
          kind: JournalCardKind.hero,
          title: '比較結果',
          subtitle: qualityLabel,
          semanticLabel: '比較結果。データ品質は$qualityLabel',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RangeInfo(label: '期間A（実効）', range: alignment.effectiveA),
              const SizedBox(height: 4),
              _RangeInfo(label: '期間B（実効）', range: alignment.effectiveB),
              const SizedBox(height: KurashilogSpacing.sm),
              _CoverageRow(
                label: '期間A 充足度',
                range: alignment.effectiveA,
                coverage: comparison.coverageA,
              ),
              _CoverageRow(
                label: '期間B 充足度',
                range: alignment.effectiveB,
                coverage: comparison.coverageB,
              ),
              if (alignment.warnings.isNotEmpty) ...[
                const SizedBox(height: KurashilogSpacing.sm),
                for (final warning in alignment.warnings)
                  Text(
                    '・${warningDetail(warning)}',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onPrimaryContainer,
                    ),
                  ),
              ],
            ],
          ),
        ),
        const SizedBox(height: KurashilogSpacing.lg),
        const JournalSectionHeader(
          title: '指標の変化',
          supportingText: '同じ条件で集計した値と差分です。',
        ),
        const SizedBox(height: KurashilogSpacing.sm),
        for (final metric in comparison.metrics) ...[
          JournalCard(
            kind: JournalCardKind.insight,
            title: metricLabel(metric.id),
            semanticLabel: '${metricLabel(metric.id)}。期間Aと期間Bの比較',
            child: _MetricRow(metric: metric),
          ),
          const SizedBox(height: KurashilogSpacing.sm),
        ],
        FilledButton.tonalIcon(
          onPressed: onSave,
          icon: const Icon(Icons.bookmark_add_outlined),
          label: const Text('この比較を保存'),
        ),
      ],
    );
  }
}

class _RangeInfo extends StatelessWidget {
  const _RangeInfo({required this.label, required this.range});

  final String label;
  final LocalDateRange range;

  @override
  Widget build(BuildContext context) {
    return Text(
      '$label: ${range.startInclusive.toIso8601String()} 〜 '
      '${range.endExclusive.addDays(-1).toIso8601String()} '
      '（${range.calendarDays}日, $timeZoneLabel）',
      style: Theme.of(context).textTheme.bodySmall,
    );
  }

  String get timeZoneLabel => range.timeZoneId;
}

class _CoverageRow extends StatelessWidget {
  const _CoverageRow({
    required this.label,
    required this.range,
    required this.coverage,
  });

  final String label;
  final LocalDateRange range;
  final PeriodCoverage coverage;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final ratio = coverage.representedDayRatio;
    final labelText = Text(label, style: theme.textTheme.bodyMedium);
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
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.metric});

  final MetricComparison metric;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final a = metric.a;
    final b = metric.b;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'A: ${formatValue(a.raw)}${a.unit}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
              Expanded(
                child: Text(
                  'B: ${formatValue(b.raw)}${b.unit}',
                  style: theme.textTheme.bodyMedium,
                ),
              ),
            ],
          ),
          if (metric.rawDelta != null ||
              metric.normalizedDelta != null ||
              metric.percentageDelta != null) ...[
            const SizedBox(height: 4),
            Text(
              _deltaText(metric),
              style: theme.textTheme.bodySmall?.copyWith(
                color: _deltaColor(theme, metric.rawDelta),
              ),
            ),
          ],
          if (a.perRepresentedDay != null || b.perRepresentedDay != null)
            Text(
              '1日あたり: A ${formatValue(a.perRepresentedDay)} / '
              'B ${formatValue(b.perRepresentedDay)}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
        ],
      ),
    );
  }

  String _deltaText(MetricComparison metric) {
    final parts = <String>[];
    if (metric.rawDelta != null) {
      parts.add('差 ${_signed(metric.rawDelta!)}${metric.a.unit}');
    }
    if (metric.normalizedDelta != null) {
      parts.add('1日あたり差 ${_signed(metric.normalizedDelta!)}${metric.a.unit}');
    }
    if (metric.percentageDelta != null) {
      parts.add('割合 ${_signed(metric.percentageDelta! * 100)}%');
    }
    return parts.join(' / ');
  }

  String _signed(double value) {
    if (value == 0) return '±0';
    return value > 0 ? '+${_formatNumber(value)}' : _formatNumber(value);
  }
}

Color _deltaColor(ThemeData theme, double? delta) {
  if (delta == null) return theme.colorScheme.onSurfaceVariant;
  if (delta > 0) return theme.colorScheme.primary;
  if (delta < 0) return theme.colorScheme.tertiary;
  return theme.colorScheme.onSurfaceVariant;
}

String formatValue(double? value) => value == null
    ? '—'
    : value == value.roundToDouble()
    ? _formatNumber(value)
    : value.toStringAsFixed(1);

String _formatNumber(double value) {
  if (value.abs() >= 10000) return value.toStringAsFixed(0);
  return value.toStringAsFixed(value == value.roundToDouble() ? 0 : 1);
}

String metricLabel(ComparisonMetricId id) => switch (id) {
  ComparisonMetricId.visitCount => '訪問回数',
  ComparisonMetricId.uniquePlaces => '訪問地点数',
  ComparisonMetricId.dwellDuration => '滞在時間',
  ComparisonMetricId.outsideHomeDays => '外出日数',
  ComparisonMetricId.movementDistance => '移動距離',
  ComparisonMetricId.movementDuration => '移動時間',
  ComparisonMetricId.recurringPlaceCount => '再来訪地点数',
  ComparisonMetricId.categoryDistribution => 'カテゴリ分布',
  ComparisonMetricId.weekdayDistribution => '曜日分布',
  ComparisonMetricId.timeOfDayDistribution => '時間帯分布',
  ComparisonMetricId.activityRadius => '行動半径',
};

String warningDetail(ComparisonWarningCode code) => switch (code) {
  ComparisonWarningCode.emptyPeriod => '空の期間が含まれています',
  ComparisonWarningCode.shortPeriod => '記録日数が少なすぎます',
  ComparisonWarningCode.insufficientCoverage => '記録不足のため参考値以下です',
  ComparisonWarningCode.coverageImbalance => '両期間の充足度に差があります',
  ComparisonWarningCode.weekdayCompositionMismatch => '曜日構成が異なります',
  ComparisonWarningCode.leapDayClamped => 'うるう年により月末日数が調整されました',
};
