import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../application/use_cases/import_use_case.dart';
import 'import_flow_controller.dart';

/// インポート画面（設計書 SC-03 インポート / SC-04 インポート結果）。
class ImportFlowScreen extends ConsumerWidget {
  const ImportFlowScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(importFlowProvider);

    return PopScope(
      canPop:
          state.phase == ImportPhase.idle || state.phase == ImportPhase.done,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) {
          ref.read(importFlowProvider.notifier).cancel();
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('タイムラインを取り込む'),
          automaticallyImplyLeading: state.phase == ImportPhase.importing
              ? false
              : true,
        ),
        body: switch (state.phase) {
          ImportPhase.idle => _IdleBody(
            onStart: () {
              ref.read(importFlowProvider.notifier).startFromPicker();
            },
          ),
          ImportPhase.previewing => const _LoadingBody(label: 'ファイルを確認しています…'),
          ImportPhase.previewReady => _PreviewBody(
            preview: state.preview!,
            existingLatestAt: state.existingLatestAt,
            onCancel: () => ref.read(importFlowProvider.notifier).dismiss(),
            onImport: () => ref.read(importFlowProvider.notifier).startImport(),
          ),
          ImportPhase.importing => _ImportingBody(
            progress: state.progress,
            onCancel: () => ref.read(importFlowProvider.notifier).cancel(),
          ),
          ImportPhase.done => _ResultBody(
            result: state.result!,
            onClose: () async {
              await ref.read(importFlowProvider.notifier).dismiss();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
          ImportPhase.error => _ErrorBody(
            code: state.errorCode,
            message: state.errorMessage,
            onRetry: () {
              final path = state.cachePath;
              if (path != null) {
                ref.read(importFlowProvider.notifier).preview(path);
              }
            },
            onClose: () async {
              await ref.read(importFlowProvider.notifier).dismiss();
              if (context.mounted) Navigator.of(context).pop();
            },
          ),
        },
      ),
    );
  }
}

class _IdleBody extends StatelessWidget {
  const _IdleBody({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(
            Icons.file_upload_outlined,
            size: 56,
            color: Color(0xFF2E6B4F),
          ),
          const SizedBox(height: 16),
          Text(
            '書き出したタイムライン JSON を選んでください',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Text(
            'Google マップのタイムラインから書き出した\n「Records.json」または同形式のファイルに対応しています。\nデータは端末内だけで処理され、送信されません。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 24),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.folder_open),
            label: const Text('ファイルを選択'),
          ),
        ],
      ),
    );
  }
}

class _LoadingBody extends StatelessWidget {
  const _LoadingBody({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          const SizedBox(height: 16),
          Text(label),
        ],
      ),
    );
  }
}

class _PreviewBody extends StatelessWidget {
  const _PreviewBody({
    required this.preview,
    required this.onCancel,
    required this.onImport,
    this.existingLatestAt,
  });

  final ImportPreview preview;
  final VoidCallback onCancel;
  final VoidCallback onImport;
  final DateTime? existingLatestAt;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy年M月d日');
    final period = preview.minAt != null && preview.maxAt != null
        ? '${fmt.format(preview.minAt!.toLocal())} 〜 ${fmt.format(preview.maxAt!.toLocal())}'
        : '不明';

    // AC6: 既存データの最新記録日とファイル終端の差 = 未反映期間。
    // 既存データが無い（初回取込）場合は「全期間が新規」と表示する。
    String? unreportedLabel;
    if (preview.maxAt != null) {
      if (existingLatestAt == null) {
        unreportedLabel = '全期間（初回の取り込み）';
      } else if (preview.maxAt!.isAfter(existingLatestAt!)) {
        final days = _localDateOnly(
          preview.maxAt!,
        ).difference(_localDateOnly(existingLatestAt!)).inDays;
        unreportedLabel = days > 0
            ? '$days 日分（${fmt.format(existingLatestAt!.toLocal())} より後）'
            : '0 日';
      }
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('取り込み内容の確認', style: theme.textTheme.titleMedium),
                const SizedBox(height: 12),
                _row(theme, '形式', 'タイムライン（Records.json）'),
                _row(theme, '対象期間', period),
                if (unreportedLabel != null)
                  _row(theme, '未反映期間', unreportedLabel),
                _row(theme, '概算レコード数', '${preview.recordCount} 件'),
                _row(
                  theme,
                  'ファイルサイズ',
                  '${(preview.fileSizeBytes / 1024 / 1024).toStringAsFixed(1)} MB',
                ),
                if (preview.warnings.isNotEmpty) ...[
                  const Divider(height: 24),
                  Text(
                    '注意',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 4),
                  for (final w in preview.warnings)
                    Text(
                      '・${w.message}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          '差分が自動的に取り込まれ、重複は登録されません。既存のデータは変更されません。',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: 24),
        FilledButton(onPressed: onImport, child: const Text('この内容で取り込む')),
        TextButton(onPressed: onCancel, child: const Text('キャンセル')),
      ],
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );
}

class _ImportingBody extends StatelessWidget {
  const _ImportingBody({required this.progress, required this.onCancel});

  final ImportProgress? progress;
  final VoidCallback onCancel;

  static const _stageLabels = {
    ImportStage.parsing: 'ファイルを解析しています…',
    ImportStage.validating: 'レコードを検証しています…',
    ImportStage.clustering: '地点を集計しています…',
    ImportStage.summarizing: '日次・月次の集計を更新しています…',
    ImportStage.insights: '気づきを生成しています…',
  };

  @override
  Widget build(BuildContext context) {
    final stage = progress?.stage ?? ImportStage.parsing;
    final percent = progress?.percent ?? 0;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          LinearProgressIndicator(value: percent / 100),
          const SizedBox(height: 24),
          Text(
            _stageLabels[stage] ?? '処理中…',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.titleSmall,
          ),
          const SizedBox(height: 8),
          Text(
            '処理中に画面を閉じても、既存のデータは安全です。',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          OutlinedButton(onPressed: onCancel, child: const Text('キャンセル')),
        ],
      ),
    );
  }
}

class _ResultBody extends StatelessWidget {
  const _ResultBody({required this.result, required this.onClose});

  final ImportResult result;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fmt = DateFormat('yyyy年M月d日');
    final period = result.sourceMinAt != null && result.sourceMaxAt != null
        ? '${fmt.format(result.sourceMinAt!.toLocal())} 〜 ${fmt.format(result.sourceMaxAt!.toLocal())}'
        : '不明';

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        const Icon(Icons.check_circle, size: 56, color: Color(0xFF2E6B4F)),
        const SizedBox(height: 12),
        Text(
          '取り込みが完了しました',
          textAlign: TextAlign.center,
          style: theme.textTheme.titleLarge,
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _row(theme, '追加した訪問', '${result.addedVisits} 件'),
                _row(theme, '追加した移動', '${result.addedMovements} 件'),
                _row(theme, '対象期間', period),
              ],
            ),
          ),
        ),
        if (result.warnings.isNotEmpty) ...[
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '警告',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  for (final w in result.warnings)
                    Text('・${w.message}', style: theme.textTheme.bodySmall),
                ],
              ),
            ),
          ),
        ],
        const SizedBox(height: 24),
        FilledButton(onPressed: onClose, child: const Text('ホームを見る')),
      ],
    );
  }

  Widget _row(ThemeData theme, String label, String value) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        SizedBox(
          width: 110,
          child: Text(
            label,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(child: Text(value, style: theme.textTheme.bodyMedium)),
      ],
    ),
  );
}

class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.code,
    required this.message,
    required this.onRetry,
    required this.onClose,
  });

  final String? code;
  final String? message;
  final VoidCallback onRetry;
  final VoidCallback onClose;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Icon(Icons.error_outline, size: 56, color: Color(0xFFB3261E)),
          const SizedBox(height: 12),
          Text(
            '取り込めませんでした',
            textAlign: TextAlign.center,
            style: theme.textTheme.titleLarge,
          ),
          const SizedBox(height: 8),
          Text(
            message ?? '不明なエラーです',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium,
          ),
          const SizedBox(height: 4),
          if (code != null)
            Text(
              'エラーコード: $code',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          const SizedBox(height: 8),
          Text(
            '既存のデータは変更されていません。',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodySmall,
          ),
          const SizedBox(height: 24),
          if (code != 'IMP-001' && code != 'IMP-002')
            FilledButton(onPressed: onRetry, child: const Text('再試行')),
          TextButton(onPressed: onClose, child: const Text('閉じる')),
        ],
      ),
    );
  }
}

/// 未反映期間の算出に使う、ローカル日付のみの正規化。
DateTime _localDateOnly(DateTime value) {
  final local = value.toLocal();
  return DateTime(local.year, local.month, local.day);
}
