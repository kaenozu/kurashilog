import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/use_cases/settings_use_case.dart';
import '../import_timeline/import_flow_screen.dart';
import '../onboarding/onboarding_screen.dart';

/// 設定・データ管理（設計書 SC-09 / FR-120）。
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(_settingsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('設定・データ管理')),
      body: settings.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('読み込みに失敗しました: $e')),
        data: (s) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.today),
                    title: const Text('週の開始曜日'),
                    trailing: SegmentedButton<WeekStart>(
                      segments: const [
                        ButtonSegment(
                          value: WeekStart.monday,
                          label: Text('月曜'),
                        ),
                        ButtonSegment(
                          value: WeekStart.sunday,
                          label: Text('日曜'),
                        ),
                      ],
                      selected: {s.weekStart},
                      onSelectionChanged: (v) async {
                        await ref
                            .read(settingsUseCaseProvider)
                            .setWeekStart(v.first);
                        ref.invalidate(_settingsProvider);
                      },
                    ),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.straighten),
                    title: const Text('距離単位'),
                    trailing: SegmentedButton<DistanceUnit>(
                      segments: const [
                        ButtonSegment(
                          value: DistanceUnit.km,
                          label: Text('km'),
                        ),
                        ButtonSegment(value: DistanceUnit.m, label: Text('m')),
                      ],
                      selected: {s.distanceUnit},
                      onSelectionChanged: (v) async {
                        await ref
                            .read(settingsUseCaseProvider)
                            .setDistanceUnit(v.first);
                        ref.invalidate(_settingsProvider);
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.file_upload_outlined),
                    title: const Text('データを再取り込み'),
                    subtitle: const Text('新しいタイムライン JSON を追加します'),
                    onTap: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => const ImportFlowScreen(),
                        ),
                      );
                    },
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.delete_forever_outlined),
                    title: const Text('すべてのデータを削除'),
                    subtitle: const Text('位置履歴・ラベル・分析結果を端末から消去します'),
                    textColor: Theme.of(context).colorScheme.error,
                    onTap: () => _confirmDelete(context, ref),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ExpansionTile(
                leading: const Icon(Icons.privacy_tip_outlined),
                title: const Text('プライバシーについて'),
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '・位置履歴は端末内だけで処理され、ネットワークへ送信されません。\n'
                    '・アプリは通信権限（INTERNET）を持ちません。\n'
                    '・元の JSON ファイルは保存せず、解析後に一時ファイルを削除します。\n'
                    '・OS のバックアップ対象から位置データを除外しています。',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Card(
              child: ListTile(
                leading: const Icon(Icons.school_outlined),
                title: const Text('オンボーディングを再表示'),
                onTap: () async {
                  await ref.read(settingsUseCaseProvider).resetOnboarding();
                  if (context.mounted) {
                    Navigator.of(context).pushReplacement(
                      MaterialPageRoute(
                        builder: (_) => const _OnboardingRedirect(),
                      ),
                    );
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('すべてのデータを削除'),
        content: const Text(
          '位置履歴・地点ラベル・分析結果をすべて削除します。\n'
          'この操作は取り消せません。よろしいですか？',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('キャンセル'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
            ),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('削除する'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    await ref.read(dataManagementUseCaseProvider).deleteAllUserData();
    ref.read(dashboardRefreshProvider.notifier).state++;
    if (context.mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('すべてのデータを削除しました')));
    }
  }
}

final _settingsProvider = FutureProvider.autoDispose<AppSettingsData>(
  (ref) => ref.watch(settingsUseCaseProvider).load(),
);

class _OnboardingRedirect extends ConsumerWidget {
  const _OnboardingRedirect();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final done = ref.watch(_onboardingDoneProvider);
    return done.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const Scaffold(body: SizedBox()),
      data: (done) {
        if (!done) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (!context.mounted) return;
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const OnboardingScreen()),
            );
          });
        }
        return const Scaffold(body: SizedBox());
      },
    );
  }
}

final _onboardingDoneProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(settingsUseCaseProvider).isOnboardingDone(),
);
