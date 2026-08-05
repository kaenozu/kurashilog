import 'package:flutter/material.dart';

import 'design_system.dart';

/// デザインシステム（設計書 6.2 / 7.3）。
///
/// - 暖色寄りのニュートラル背景 + 深緑アクセント
/// - Material 3
/// - ダークモード対応（色を直接指定せず Theme Extension で管理）
class KurashilogTheme {
  KurashilogTheme._();

  /// 深緑アクセント（シード色）。
  static const Color seedGreen = Color(0xFF2E6B4F);

  /// 暖色寄りニュートラル（ライト）。
  static const Color warmNeutral = Color(0xFFFBF7F2);

  /// ダーク用ニュートラル。
  static const Color darkNeutral = Color(0xFF171512);

  static ThemeData light() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.light,
      surface: warmNeutral,
    );
    return _base(scheme);
  }

  static ThemeData dark() {
    final scheme = ColorScheme.fromSeed(
      seedColor: seedGreen,
      brightness: Brightness.dark,
      surface: darkNeutral,
    );
    return _base(scheme);
  }

  static ThemeData _base(ColorScheme scheme) {
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: scheme.surface,
      extensions: <ThemeExtension<dynamic>>[
        KurashilogJournalColors.fromScheme(scheme),
      ],
    );

    return base.copyWith(
      textTheme: base.textTheme.copyWith(
        displaySmall: base.textTheme.displaySmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.1,
        ),
        headlineSmall: base.textTheme.headlineSmall?.copyWith(
          fontWeight: FontWeight.w700,
          height: 1.2,
        ),
        bodyLarge: base.textTheme.bodyLarge?.copyWith(height: 1.55),
        bodyMedium: base.textTheme.bodyMedium?.copyWith(height: 1.5),
      ),
      cardTheme: CardThemeData(
        elevation: 0,
        color: scheme.surfaceContainerLow,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KurashilogRadius.medium),
        ),
        margin: EdgeInsets.zero,
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: scheme.surfaceContainer,
        indicatorColor: scheme.primaryContainer,
      ),
      chipTheme: base.chipTheme.copyWith(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KurashilogRadius.small),
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: scheme.surface,
        surfaceTintColor: Colors.transparent,
        centerTitle: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(KurashilogRadius.sm),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          minimumSize: const Size(0, KurashilogSize.minimumTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KurashilogRadius.pill),
          ),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(0, KurashilogSize.minimumTapTarget),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(KurashilogRadius.pill),
          ),
        ),
      ),
    );
  }
}
