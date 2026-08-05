import 'package:flutter/material.dart';

import '../../infrastructure/platform/app_platform.dart';

enum OnboardingSetupStatus {
  ready,
  openingSettings,
  waitingForReturn,
  returnedFromSettings,
  fallbackInstructions,
  error,
}

class OnboardingSetupPanel extends StatelessWidget {
  const OnboardingSetupPanel({
    required this.status,
    required this.onOpenSettings,
    required this.onChooseFile,
    super.key,
    this.destination,
  });

  final OnboardingSetupStatus status;
  final LocationSettingsDestination? destination;
  final VoidCallback? onOpenSettings;
  final VoidCallback? onChooseFile;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 12),
      children: <Widget>[
        Semantics(
          header: true,
          child: Text(
            'タイムラインを準備しましょう',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Androidの公開設定画面を開いたあと、Google マップから手動で書き出したJSONを選びます。メーカーやAndroidの版により設定画面の場所は異なります。',
          style: theme.textTheme.bodyLarge,
        ),
        const SizedBox(height: 20),
        _SetupStep(
          number: 1,
          title: '位置情報の設定を確認',
          body: _settingsBody,
          action: FilledButton.icon(
            onPressed: status == OnboardingSetupStatus.openingSettings
                ? null
                : onOpenSettings,
            icon: status == OnboardingSetupStatus.openingSettings
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.settings_outlined),
            label: const Text('位置情報設定を開く'),
          ),
        ),
        const SizedBox(height: 12),
        _SetupStep(
          number: 2,
          title: 'タイムラインを書き出す',
          body:
              'Google マップのタイムラインでバックアップまたはエクスポートを実行します。特定の内部画面へ直接移動せず、表示された公開設定から操作してください。',
        ),
        const SizedBox(height: 12),
        _SetupStep(
          number: 3,
          title: 'JSONファイルを選ぶ',
          body:
              'ファイル名やJSONの構造を覚える必要はありません。対応形式かどうかはアプリが確認し、キャンセル・破損・非対応・重複を安全に扱います。',
          action: OutlinedButton.icon(
            onPressed: onChooseFile,
            icon: const Icon(Icons.folder_open_outlined),
            label: const Text('ファイルを選ぶ'),
          ),
        ),
        const SizedBox(height: 24),
        const _AnonymousSample(),
      ],
    );
  }

  String get _settingsBody => switch (status) {
    OnboardingSetupStatus.ready =>
      '設定を開いたあと、このアプリへ戻ると次の操作を案内します。',
    OnboardingSetupStatus.openingSettings => 'Androidの設定画面を開いています。',
    OnboardingSetupStatus.waitingForReturn => '設定を確認したら、このアプリへ戻ってください。',
    OnboardingSetupStatus.returnedFromSettings =>
      '設定から戻りました。次はタイムラインを書き出し、JSONファイルを選んでください。',
    OnboardingSetupStatus.fallbackInstructions =>
      destination == LocationSettingsDestination.generalSettings
          ? '端末固有の制限により一般設定を開きました。「位置情報」または「Google」を探してタイムラインを確認してください。'
          : '位置情報設定を直接開けませんでした。Androidの設定から「位置情報」または「Google」を探してください。',
    OnboardingSetupStatus.error =>
      '設定画面を開けませんでした。Androidの設定アプリを手動で開いても、ファイル選択から続行できます。',
  };
}

class _SetupStep extends StatelessWidget {
  const _SetupStep({
    required this.number,
    required this.title,
    required this.body,
    this.action,
  });

  final int number;
  final String title;
  final String body;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: '手順$number、$title。$body',
      child: ExcludeSemantics(
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    CircleAvatar(
                      radius: 16,
                      backgroundColor: scheme.primaryContainer,
                      foregroundColor: scheme.onPrimaryContainer,
                      child: Text('$number'),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                          const SizedBox(height: 4),
                          Text(body),
                        ],
                      ),
                    ),
                  ],
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: 12),
                  action!,
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _AnonymousSample extends StatelessWidget {
  const _AnonymousSample();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      container: true,
      label:
          '匿名サンプル。今月は外出した日が12日。よく行った場所は公園。前の期間より休日の行動範囲が広がりました。',
      child: ExcludeSemantics(
        child: Card(
          color: theme.colorScheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '取り込むと、こんな生活まとめが見られます',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
                const SizedBox(height: 12),
                const _SampleFact(icon: Icons.calendar_today, text: '今月は外出した日が12日'),
                const _SampleFact(icon: Icons.place_outlined, text: 'よく行った場所は公園'),
                const _SampleFact(
                  icon: Icons.trending_up,
                  text: '前の期間より休日の行動範囲が広がりました',
                ),
                const SizedBox(height: 8),
                Text(
                  'これは匿名の完成例です。実データや位置情報は含みません。',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSecondaryContainer,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SampleFact extends StatelessWidget {
  const _SampleFact({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSecondaryContainer;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: TextStyle(color: color))),
        ],
      ),
    );
  }
}
