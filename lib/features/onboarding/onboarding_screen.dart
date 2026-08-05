import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/main_shell.dart';
import '../../application/providers.dart';
import '../../infrastructure/platform/app_platform.dart';
import '../import_timeline/import_flow_screen.dart';
import 'onboarding_setup_panel.dart';

/// 初回説明とタイムライン準備導線（設計書 SC-01 / FR-001）。
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen>
    with WidgetsBindingObserver {
  final _controller = PageController();
  int _page = 0;
  OnboardingSetupStatus _setupStatus = OnboardingSetupStatus.ready;
  LocationSettingsDestination? _settingsDestination;
  bool _waitingForSettingsReturn = false;

  static const _introPages = <_OnboardingPageData>[
    _OnboardingPageData(
      icon: Icons.security,
      title: '端末内だけで処理されます',
      body:
          '取り込んだ位置履歴は、この端末の中だけで分析されます。アプリはインターネットへ接続せず、データを外部へ送信しません。',
    ),
    _OnboardingPageData(
      icon: Icons.auto_stories_outlined,
      title: '生活の変化を振り返れます',
      body:
          '外出した日、よく行った場所、前の期間との違いを、根拠とデータ品質を添えて表示します。記録が足りない場合は無理に断定しません。',
    ),
  ];

  static const int _pageCount = 3;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _controller.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed || !_waitingForSettingsReturn) {
      return;
    }
    _waitingForSettingsReturn = false;
    if (!mounted) return;
    setState(() {
      _setupStatus =
          _settingsDestination == LocationSettingsDestination.generalSettings
          ? OnboardingSetupStatus.fallbackInstructions
          : OnboardingSetupStatus.returnedFromSettings;
    });
  }

  Future<void> _openLocationSettings() async {
    setState(() => _setupStatus = OnboardingSetupStatus.openingSettings);
    try {
      final destination = await ref
          .read(platformProvider)
          .openLocationSettings();
      if (!mounted) return;
      setState(() {
        _settingsDestination = destination;
        _waitingForSettingsReturn = true;
        _setupStatus =
            destination == LocationSettingsDestination.generalSettings
            ? OnboardingSetupStatus.fallbackInstructions
            : OnboardingSetupStatus.waitingForReturn;
      });
    } on PlatformException {
      if (!mounted) return;
      setState(() {
        _waitingForSettingsReturn = false;
        _setupStatus = OnboardingSetupStatus.error;
      });
    }
  }

  Future<void> _openImportFlow() async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(builder: (_) => const ImportFlowScreen()),
    );
  }

  Future<void> _completeOnboarding() async {
    await ref.read(settingsUseCaseProvider).setOnboardingDone();
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute<void>(builder: (_) => const MainShell()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Expanded(
              child: PageView.builder(
                controller: _controller,
                itemCount: _pageCount,
                onPageChanged: (index) => setState(() => _page = index),
                itemBuilder: (context, index) {
                  if (index == _pageCount - 1) {
                    return OnboardingSetupPanel(
                      status: _setupStatus,
                      destination: _settingsDestination,
                      onOpenSettings: _openLocationSettings,
                      onChooseFile: _openImportFlow,
                    );
                  }
                  return _IntroPage(data: _introPages[index]);
                },
              ),
            ),
            Semantics(
              label: '${_page + 1} / $_pageCountページ',
              child: ExcludeSemantics(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: <Widget>[
                    for (var index = 0; index < _pageCount; index++)
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        margin: const EdgeInsets.symmetric(horizontal: 4),
                        width: _page == index ? 24 : 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: _page == index
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _page < _pageCount - 1
                      ? () => _controller.nextPage(
                          duration: const Duration(milliseconds: 250),
                          curve: Curves.easeOut,
                        )
                      : _completeOnboarding,
                  child: Text(
                    _page < _pageCount - 1 ? '次へ' : 'ホームへ進む',
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _IntroPage extends StatelessWidget {
  const _IntroPage({required this.data});

  final _OnboardingPageData data;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: MediaQuery.sizeOf(context).height - 220,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            ExcludeSemantics(
              child: Icon(
                data.icon,
                size: 96,
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 32),
            Semantics(
              header: true,
              child: Text(
                data.title,
                textAlign: TextAlign.center,
                style: theme.textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              data.body,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
          ],
        ),
      ),
    );
  }
}

class _OnboardingPageData {
  const _OnboardingPageData({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;
}
