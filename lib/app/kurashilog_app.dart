import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../application/providers.dart';
import '../features/import_timeline/import_flow_controller.dart';
import '../features/import_timeline/import_flow_screen.dart';
import '../features/onboarding/onboarding_screen.dart';
import 'main_shell.dart';
import 'theme.dart';

/// アプリのルート。
class KurashilogApp extends ConsumerWidget {
  const KurashilogApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'くらしログ',
      debugShowCheckedModeBanner: false,
      theme: KurashilogTheme.light(),
      darkTheme: KurashilogTheme.dark(),
      home: const _RootGate(),
    );
  }
}

/// オンボーディング未完了なら説明、完了ならメインシェル。
class _RootGate extends ConsumerStatefulWidget {
  const _RootGate();

  @override
  ConsumerState<_RootGate> createState() => _RootGateState();
}

class _RootGateState extends ConsumerState<_RootGate>
    with WidgetsBindingObserver {
  bool _checkingShare = false;
  bool _initialShareScheduled = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkSharedFile();
    }
    if (state == AppLifecycleState.detached) {
      ref.read(appDatabaseProvider).close();
    }
  }

  Future<void> _checkSharedFile() async {
    if (_checkingShare || !mounted) return;
    _checkingShare = true;
    try {
      final notifier = ref.read(importFlowProvider.notifier);
      final opened = await notifier.startFromShare();
      if (opened && mounted) {
        await Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const ImportFlowScreen()));
      }
    } finally {
      _checkingShare = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final done = ref.watch(_onboardingDoneProvider);
    if (!_initialShareScheduled && done.valueOrNull == true) {
      _initialShareScheduled = true;
      WidgetsBinding.instance.addPostFrameCallback((_) => _checkSharedFile());
    }

    return done.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => const Scaffold(body: SizedBox()),
      data: (isDone) => isDone ? const MainShell() : const OnboardingScreen(),
    );
  }
}

final _onboardingDoneProvider = FutureProvider.autoDispose<bool>(
  (ref) => ref.watch(settingsUseCaseProvider).isOnboardingDone(),
);
