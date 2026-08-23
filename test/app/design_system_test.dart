import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/app/design_system.dart';
import 'package:kurashilog/app/theme.dart';
import 'package:kurashilog/domain/models/summaries.dart';
import 'package:kurashilog/features/dashboard/home_screen.dart';

void main() {
  test('light and dark themes expose the journal extension', () {
    final light = KurashilogTheme.light();
    final dark = KurashilogTheme.dark();

    expect(light.brightness, Brightness.light);
    expect(dark.brightness, Brightness.dark);
    expect(light.extension<KurashilogJournalColors>(), isNotNull);
    expect(dark.extension<KurashilogJournalColors>(), isNotNull);
    expect(
      light.extension<KurashilogJournalColors>()!.paper,
      isNot(dark.extension<KurashilogJournalColors>()!.paper),
    );
  });

  test('spacing and tap target contracts remain stable', () {
    expect(<double>[
      KurashilogSpacing.xxs,
      KurashilogSpacing.xs,
      KurashilogSpacing.sm,
      KurashilogSpacing.md,
      KurashilogSpacing.lg,
      KurashilogSpacing.xl,
      KurashilogSpacing.xxl,
    ], orderedEquals(<double>[4, 8, 12, 16, 24, 32, 48]));
    expect(KurashilogSize.minimumTapTarget, 48);
    expect(KurashilogRadius.large, greaterThan(KurashilogRadius.medium));
  });

  test('home metric hierarchy gives the primary metric the hero role', () {
    expect(journalKindForMetric(MetricIcon.walking), JournalCardKind.hero);
    expect(journalKindForMetric(MetricIcon.route), JournalCardKind.mini);
    expect(journalKindForMetric(MetricIcon.place), JournalCardKind.mini);
    expect(journalKindForMetric(MetricIcon.explore), JournalCardKind.mini);
  });

  testWidgets('all card kinds render without uniform visual density', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KurashilogTheme.light(),
        home: Scaffold(
          body: ListView(
            children: <Widget>[
              for (final kind in JournalCardKind.values)
                JournalCard(
                  kind: kind,
                  title: kind.name,
                  subtitle: '匿名fixture',
                  semanticLabel: '${kind.name}カード。匿名fixture',
                  onTap: () {},
                  child: const Text('根拠を表示します'),
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final kind in JournalCardKind.values) {
      expect(
        find.bySemanticsLabel('${kind.name}カード。匿名fixture'),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });

  testWidgets('states expose labels and loading or error as live regions', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: KurashilogTheme.dark(),
        home: Scaffold(
          body: ListView(
            children: <Widget>[
              for (final tone in JournalStateTone.values)
                JournalStatePanel(
                  tone: tone,
                  title: tone.name,
                  message: '状態の説明',
                ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    for (final tone in JournalStateTone.values) {
      expect(find.bySemanticsLabel('${tone.name}。状態の説明'), findsOneWidget);
    }
  });

  testWidgets('state action keeps independent button semantics and tap', (
    tester,
  ) async {
    var tapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: KurashilogTheme.light(),
        home: Scaffold(
          body: JournalStatePanel(
            tone: JournalStateTone.error,
            title: '読み込みに失敗しました',
            message: '時間をおいて再試行してください',
            action: FilledButton(
              onPressed: () => tapped = true,
              child: const Text('再試行'),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.bySemanticsLabel('読み込みに失敗しました。時間をおいて再試行してください'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel('再試行'), findsOneWidget);

    await tester.tap(find.widgetWithText(FilledButton, '再試行'));
    await tester.pump();
    expect(tapped, isTrue);
  });

  testWidgets('360px at 200 percent text remains scrollable and usable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(360, 800);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      MaterialApp(
        theme: KurashilogTheme.light(),
        home: MediaQuery(
          data: const MediaQueryData(textScaler: TextScaler.linear(2)),
          child: Scaffold(
            body: ListView(
              padding: const EdgeInsets.all(KurashilogSpacing.md),
              children: <Widget>[
                const JournalSectionHeader(
                  eyebrow: '2026年の生活まとめ',
                  title: 'とても長い日本語の章タイトルでも読み続けられます',
                  supportingText: 'データ品質と対象期間を省略せずに説明します。',
                ),
                const SizedBox(height: KurashilogSpacing.lg),
                JournalCard(
                  kind: JournalCardKind.hero,
                  title: '今月の生活の変化',
                  subtitle: '事実と弱い推定を区別します',
                  child: FilledButton(
                    onPressed: () {},
                    child: const Text('根拠を見る'),
                  ),
                ),
                const SizedBox(height: KurashilogSpacing.lg),
                JournalStatePanel(
                  tone: JournalStateTone.error,
                  title: '読み込みに失敗しました',
                  message: '説明を省略せずに表示し、操作を残します',
                  action: FilledButton(
                    onPressed: () {},
                    child: const Text('もう一度試す'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('根拠を見る'), findsOneWidget);
    final size = tester.getSize(find.widgetWithText(FilledButton, '根拠を見る'));
    expect(size.height, greaterThanOrEqualTo(48));

    await tester.scrollUntilVisible(
      find.widgetWithText(FilledButton, 'もう一度試す'),
      200,
    );
    final actionSize = tester.getSize(
      find.widgetWithText(FilledButton, 'もう一度試す'),
    );
    expect(actionSize.height, greaterThanOrEqualTo(48));
    expect(find.bySemanticsLabel('もう一度試す'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
