import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/application/providers.dart';
import 'package:kurashilog/features/onboarding/onboarding_screen.dart';
import 'package:kurashilog/features/onboarding/onboarding_setup_panel.dart';
import 'package:kurashilog/infrastructure/platform/app_platform.dart';

void main() {
  testWidgets('returning from location settings exposes the next action', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          platformProvider.overrideWithValue(
            _FakePlatform(LocationSettingsDestination.locationSources),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    await _goToSetup(tester);
    await tester.tap(find.text('位置情報設定を開く'));
    await tester.pump();
    expect(find.text('設定を確認したら、このアプリへ戻ってください。'), findsOneWidget);

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pump();

    expect(find.textContaining('設定から戻りました'), findsOneWidget);
    expect(find.widgetWithText(OutlinedButton, 'ファイルを選ぶ'), findsOneWidget);
  });

  testWidgets('general settings result shows manufacturer-safe fallback copy', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          platformProvider.overrideWithValue(
            _FakePlatform(LocationSettingsDestination.generalSettings),
          ),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    await _goToSetup(tester);
    await tester.tap(find.text('位置情報設定を開く'));
    await tester.pump();

    expect(find.textContaining('一般設定を開きました'), findsOneWidget);
    expect(find.textContaining('メーカー'), findsOneWidget);
    expect(find.textContaining('内部画面'), findsOneWidget);
  });

  testWidgets('platform failure is redacted and file selection remains available', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: <Override>[
          platformProvider.overrideWithValue(_FailingPlatform()),
        ],
        child: const MaterialApp(home: OnboardingScreen()),
      ),
    );

    await _goToSetup(tester);
    await tester.tap(find.text('位置情報設定を開く'));
    await tester.pump();

    expect(find.textContaining('設定画面を開けませんでした'), findsOneWidget);
    expect(find.textContaining('secret-content-uri'), findsNothing);
    expect(find.widgetWithText(OutlinedButton, 'ファイルを選ぶ'), findsOneWidget);
  });

  testWidgets('anonymous sample and controls survive 200 percent text', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      const MaterialApp(
        home: MediaQuery(
          data: MediaQueryData(textScaler: TextScaler.linear(2)),
          child: OnboardingSetupPanel(
            status: OnboardingSetupStatus.returnedFromSettings,
            onOpenSettings: null,
            onChooseFile: null,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.scrollUntilVisible(
      find.text('これは匿名の完成例です。実データや位置情報は含みません。'),
      320,
      scrollable: find.byType(Scrollable),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('匿名の完成例'), findsOneWidget);
    expect(find.text('よく行った場所は公園'), findsOneWidget);
    expect(
      find.bySemanticsLabel(
        RegExp('匿名サンプル.*よく行った場所は公園'),
      ),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}

Future<void> _goToSetup(WidgetTester tester) async {
  await tester.tap(find.text('次へ'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('次へ'));
  await tester.pumpAndSettle();
  expect(find.text('タイムラインを準備しましょう'), findsOneWidget);
}

class _FakePlatform extends AppPlatform {
  _FakePlatform(this.destination);

  final LocationSettingsDestination destination;

  @override
  Future<LocationSettingsDestination> openLocationSettings() async => destination;
}

class _FailingPlatform extends AppPlatform {
  @override
  Future<LocationSettingsDestination> openLocationSettings() {
    throw PlatformException(
      code: 'INTERNAL',
      message: 'secret-content-uri',
    );
  }
}
