import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/use_cases/milestones_use_case.dart';
import '../../domain/change_detection/change_point.dart';
import '../../domain/models/comparison.dart';
import '../comparison/comparison_screen.dart';

final milestoneReviewProvider = FutureProvider.autoDispose<MilestoneReviewData>(
  (ref) => ref.watch(milestonesUseCaseProvider).loadReview(),
);

class MilestonesScreen extends ConsumerWidget {
  const MilestonesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final review = ref.watch(milestoneReviewProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('生活の変化・節目')),
      body: review.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('読み込みに失敗しました: $error')),
        data: (data) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(milestoneReviewProvider);
            await ref.read(milestoneReviewProvider.future);
          },
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text('変化の候補', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              const Text('位置履歴から理由を推測せず、行動パターンの変化だけを表示します。'),
              const SizedBox(height: 12),
              if (data.candidates.isEmpty)
                const Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Text('十分に継続した変化の候補はありません。記録が増えると再評価されます。'),
                  ),
                )
              else
                for (final candidate in data.candidates)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: ChangeCandidateCard(
                      candidate: candidate,
                      onCreateMilestone: () =>
                          _createMilestone(context, ref, candidate),
                      onIgnore: () => _ignoreCandidate(context, ref, candidate),
                    ),
                  ),
              const SizedBox(height: 20),
              Text('記録した節目', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              if (data.milestones.isEmpty)
                const Text('まだ節目は記録されていません。')
              else
                for (final milestone in data.milestones)
                  _MilestoneTile(
                    milestone: milestone,
                    onEdit: () => _editMilestone(context, ref, milestone),
                    onDelete: () => _deleteMilestone(context, ref, milestone),
                    onCompare: () =>
                        _compareAroundMilestone(context, ref, milestone),
                  ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _createMilestone(
    BuildContext context,
    WidgetRef ref,
    ChangePointCandidate candidate,
  ) async {
    final boundary = candidate.after.startInclusive;
    final initialRange = LocalDateRange(
      startInclusive: boundary,
      endExclusive: boundary.addDays(1),
      timeZoneId: candidate.after.timeZoneId,
    );
    final result = await showDialog<MilestoneEditorResult>(
      context: context,
      builder: (_) => MilestoneEditorDialog(initialRange: initialRange),
    );
    if (result == null || !context.mounted) return;
    try {
      await ref
          .read(milestonesUseCaseProvider)
          .createMilestone(
            candidate: candidate,
            title: result.title,
            range: result.range,
            note: result.note,
          );
      ref.invalidate(milestoneReviewProvider);
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('節目として記録しました')));
      }
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('節目を保存できませんでした')));
      }
    }
  }

  Future<void> _ignoreCandidate(
    BuildContext context,
    WidgetRef ref,
    ChangePointCandidate candidate,
  ) async {
    await ref.read(milestonesUseCaseProvider).ignoreCandidate(candidate);
    ref.invalidate(milestoneReviewProvider);
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('この候補を非表示にしました')));
    }
  }

  Future<void> _editMilestone(
    BuildContext context,
    WidgetRef ref,
    LifeMilestone milestone,
  ) async {
    final result = await showDialog<MilestoneEditorResult>(
      context: context,
      builder: (_) => MilestoneEditorDialog(
        initialRange: milestone.range,
        initialTitle: milestone.title,
        initialNote: milestone.note,
      ),
    );
    if (result == null) return;
    try {
      await ref
          .read(milestonesUseCaseProvider)
          .updateMilestone(
            milestone: milestone,
            title: result.title,
            range: result.range,
            note: result.note,
          );
      ref.invalidate(milestoneReviewProvider);
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('節目を更新できませんでした')));
      }
    }
  }

  Future<void> _deleteMilestone(
    BuildContext context,
    WidgetRef ref,
    LifeMilestone milestone,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('節目を削除'),
        content: Text('「${milestone.title}」を削除しますか？'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await ref.read(milestonesUseCaseProvider).deleteMilestone(milestone.id);
    ref.invalidate(milestoneReviewProvider);
  }

  void _compareAroundMilestone(
    BuildContext context,
    WidgetRef ref,
    LifeMilestone milestone,
  ) {
    final request = ref
        .read(milestonesUseCaseProvider)
        .comparisonRequestForMilestone(milestone);
    ref.read(periodAStateProvider.notifier).state = request.periodA;
    ref.read(periodBStateProvider.notifier).state = request.periodB;
    ref.read(comparisonAlignmentProvider.notifier).state = request.alignment;
    ref.read(comparisonRequestProvider.notifier).state = request;
    ref.invalidate(comparisonResultProvider);
    ref.read(appTabProvider.notifier).state = 2;
    Navigator.of(context).pop();
  }
}

class ChangeCandidateCard extends StatelessWidget {
  const ChangeCandidateCard({
    super.key,
    required this.candidate,
    required this.onCreateMilestone,
    required this.onIgnore,
  });

  final ChangePointCandidate candidate;
  final VoidCallback onCreateMilestone;
  final VoidCallback onIgnore;

  @override
  Widget build(BuildContext context) {
    final boundary = candidate.after.startInclusive.toIso8601String();
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '$boundary ごろに行動パターンが変化しています',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '比較期間: ${candidate.before.startInclusive.toIso8601String()}〜'
              '${candidate.before.endExclusive.addDays(-1).toIso8601String()} / '
              '${candidate.after.startInclusive.toIso8601String()}〜'
              '${candidate.after.endExclusive.addDays(-1).toIso8601String()}',
            ),
            const SizedBox(height: 8),
            Text('変化スコア ${candidate.score.toStringAsFixed(2)}（確率ではありません）'),
            const SizedBox(height: 8),
            for (final evidence in candidate.evidence.take(3))
              Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('• '),
                    Expanded(child: Text(evidence.description)),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                FilledButton.icon(
                  onPressed: onCreateMilestone,
                  icon: const Icon(Icons.bookmark_add_outlined),
                  label: const Text('節目として記録'),
                ),
                TextButton(onPressed: onIgnore, child: const Text('今回は無視')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MilestoneTile extends StatelessWidget {
  const _MilestoneTile({
    required this.milestone,
    required this.onEdit,
    required this.onDelete,
    required this.onCompare,
  });

  final LifeMilestone milestone;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onCompare;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              milestone.title,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text(_rangeLabel(milestone.range)),
            if (milestone.note != null) ...[
              const SizedBox(height: 4),
              Text(milestone.note!),
            ],
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                TextButton.icon(
                  onPressed: onCompare,
                  icon: const Icon(Icons.compare_arrows),
                  label: const Text('前後を比較'),
                ),
                TextButton(onPressed: onEdit, child: const Text('編集')),
                TextButton(onPressed: onDelete, child: const Text('削除')),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class MilestoneEditorResult {
  const MilestoneEditorResult({
    required this.title,
    required this.range,
    this.note,
  });

  final String title;
  final LocalDateRange range;
  final String? note;
}

class MilestoneEditorDialog extends StatefulWidget {
  const MilestoneEditorDialog({
    super.key,
    required this.initialRange,
    this.initialTitle = '',
    this.initialNote,
  });

  final LocalDateRange initialRange;
  final String initialTitle;
  final String? initialNote;

  @override
  State<MilestoneEditorDialog> createState() => _MilestoneEditorDialogState();
}

class _MilestoneEditorDialogState extends State<MilestoneEditorDialog> {
  late final TextEditingController _titleController;
  late final TextEditingController _noteController;
  late LocalDateRange _range;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.initialTitle)
      ..addListener(_handleTitleChanged);
    _noteController = TextEditingController(text: widget.initialNote ?? '');
    _range = widget.initialRange;
  }

  @override
  void dispose() {
    _titleController
      ..removeListener(_handleTitleChanged)
      ..dispose();
    _noteController.dispose();
    super.dispose();
  }

  void _handleTitleChanged() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.initialTitle.isEmpty ? '節目として記録' : '節目を編集'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _titleController,
              autofocus: widget.initialTitle.isEmpty,
              decoration: const InputDecoration(labelText: '節目名'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _noteController,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'メモ（任意）'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _pickRange,
              icon: const Icon(Icons.date_range),
              label: Text(_rangeLabel(_range)),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('キャンセル'),
        ),
        FilledButton(
          onPressed: _titleController.text.trim().isEmpty
              ? null
              : () => Navigator.of(context).pop(
                  MilestoneEditorResult(
                    title: _titleController.text.trim(),
                    range: _range,
                    note: _noteController.text.trim().isEmpty
                        ? null
                        : _noteController.text.trim(),
                  ),
                ),
          child: const Text('保存'),
        ),
      ],
    );
  }

  Future<void> _pickRange() async {
    final initialStart = _toDateTime(_range.startInclusive);
    final initialEnd = _toDateTime(_range.endExclusive.addDays(-1));
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      initialDateRange: DateTimeRange(start: initialStart, end: initialEnd),
    );
    if (picked == null) return;
    setState(() {
      _range = LocalDateRange(
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
        timeZoneId: _range.timeZoneId,
      );
    });
  }
}

String _rangeLabel(LocalDateRange range) {
  final end = range.endExclusive.addDays(-1);
  if (end == range.startInclusive) {
    return range.startInclusive.toIso8601String();
  }
  return '${range.startInclusive.toIso8601String()}〜${end.toIso8601String()}';
}

DateTime _toDateTime(LocalDate date) =>
    DateTime(date.year, date.month, date.day);
