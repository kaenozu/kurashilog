import 'package:flutter/material.dart';

abstract final class KurashilogSpacing {
  static const double xxs = 4;
  static const double xs = 8;
  static const double sm = 12;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;
}

abstract final class KurashilogRadius {
  static const double small = 8;
  static const double medium = 16;
  static const double large = 24;
  static const double pill = 999;
}

abstract final class KurashilogSize {
  static const double minimumTapTarget = 48;
  static const double contentMaxWidth = 1120;
}

@immutable
class KurashilogJournalColors extends ThemeExtension<KurashilogJournalColors> {
  const KurashilogJournalColors({
    required this.paper,
    required this.paperElevated,
    required this.inkMuted,
    required this.positive,
    required this.caution,
    required this.private,
    required this.mapWater,
  });

  final Color paper;
  final Color paperElevated;
  final Color inkMuted;
  final Color positive;
  final Color caution;
  final Color private;
  final Color mapWater;

  factory KurashilogJournalColors.fromScheme(ColorScheme scheme) =>
      KurashilogJournalColors(
        paper: scheme.surface,
        paperElevated: scheme.surfaceContainerLow,
        inkMuted: scheme.onSurfaceVariant,
        positive: scheme.tertiary,
        caution: scheme.secondary,
        private: scheme.error,
        mapWater: scheme.primaryContainer.withValues(alpha: 0.55),
      );

  @override
  KurashilogJournalColors copyWith({
    Color? paper,
    Color? paperElevated,
    Color? inkMuted,
    Color? positive,
    Color? caution,
    Color? private,
    Color? mapWater,
  }) => KurashilogJournalColors(
    paper: paper ?? this.paper,
    paperElevated: paperElevated ?? this.paperElevated,
    inkMuted: inkMuted ?? this.inkMuted,
    positive: positive ?? this.positive,
    caution: caution ?? this.caution,
    private: private ?? this.private,
    mapWater: mapWater ?? this.mapWater,
  );

  @override
  KurashilogJournalColors lerp(
    covariant KurashilogJournalColors? other,
    double t,
  ) {
    if (other == null) return this;
    return KurashilogJournalColors(
      paper: Color.lerp(paper, other.paper, t)!,
      paperElevated: Color.lerp(paperElevated, other.paperElevated, t)!,
      inkMuted: Color.lerp(inkMuted, other.inkMuted, t)!,
      positive: Color.lerp(positive, other.positive, t)!,
      caution: Color.lerp(caution, other.caution, t)!,
      private: Color.lerp(private, other.private, t)!,
      mapWater: Color.lerp(mapWater, other.mapWater, t)!,
    );
  }
}

extension KurashilogThemeContext on BuildContext {
  KurashilogJournalColors get journalColors =>
      Theme.of(this).extension<KurashilogJournalColors>() ??
      KurashilogJournalColors.fromScheme(Theme.of(this).colorScheme);
}

enum JournalCardKind { hero, insight, map, mini }

enum JournalStateTone { neutral, loading, insufficient, error, private }

class JournalSectionHeader extends StatelessWidget {
  const JournalSectionHeader({
    required this.title,
    super.key,
    this.eyebrow,
    this.supportingText,
    this.trailing,
  });

  final String title;
  final String? eyebrow;
  final String? supportingText;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              if (eyebrow != null)
                Text(
                  eyebrow!.toUpperCase(),
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              Semantics(
                header: true,
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    height: 1.2,
                  ),
                ),
              ),
              if (supportingText != null) ...<Widget>[
                const SizedBox(height: KurashilogSpacing.xs),
                Text(
                  supportingText!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: context.journalColors.inkMuted,
                  ),
                ),
              ],
            ],
          ),
        ),
        if (trailing != null) ...<Widget>[
          const SizedBox(width: KurashilogSpacing.md),
          trailing!,
        ],
      ],
    );
  }
}

class JournalCard extends StatelessWidget {
  const JournalCard({
    required this.kind,
    required this.title,
    required this.child,
    super.key,
    this.subtitle,
    this.onTap,
    this.semanticLabel,
  });

  final JournalCardKind kind;
  final String title;
  final String? subtitle;
  final Widget child;
  final VoidCallback? onTap;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final padding = switch (kind) {
      JournalCardKind.hero => const EdgeInsets.all(KurashilogSpacing.lg),
      JournalCardKind.insight => const EdgeInsets.all(KurashilogSpacing.md),
      JournalCardKind.map => const EdgeInsets.all(KurashilogSpacing.sm),
      JournalCardKind.mini => const EdgeInsets.all(KurashilogSpacing.sm),
    };
    final radius = switch (kind) {
      JournalCardKind.hero => KurashilogRadius.large,
      JournalCardKind.insight => KurashilogRadius.medium,
      JournalCardKind.map => KurashilogRadius.medium,
      JournalCardKind.mini => KurashilogRadius.small,
    };
    final surface = switch (kind) {
      JournalCardKind.hero => scheme.primaryContainer,
      JournalCardKind.insight => context.journalColors.paperElevated,
      JournalCardKind.map => context.journalColors.mapWater,
      JournalCardKind.mini => scheme.surfaceContainerLowest,
    };

    final content = Material(
      color: surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radius),
        side: kind == JournalCardKind.mini
            ? BorderSide(color: scheme.outlineVariant)
            : BorderSide.none,
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: padding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                title,
                style: switch (kind) {
                  JournalCardKind.hero =>
                    Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      height: 1.15,
                    ),
                  JournalCardKind.insight => Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                  JournalCardKind.map =>
                    Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  JournalCardKind.mini => Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                },
              ),
              if (subtitle != null) ...<Widget>[
                const SizedBox(height: KurashilogSpacing.xs),
                Text(subtitle!),
              ],
              const SizedBox(height: KurashilogSpacing.md),
              child,
            ],
          ),
        ),
      ),
    );

    if (semanticLabel == null) return content;
    return Semantics(
      container: true,
      button: onTap != null,
      label: semanticLabel,
      child: ExcludeSemantics(child: content),
    );
  }
}

class JournalStatePanel extends StatelessWidget {
  const JournalStatePanel({
    required this.tone,
    required this.title,
    required this.message,
    super.key,
    this.action,
  });

  final JournalStateTone tone;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (icon, background, foreground, liveRegion) = switch (tone) {
      JournalStateTone.neutral => (
        Icons.auto_stories_outlined,
        scheme.surfaceContainerLow,
        scheme.onSurface,
        false,
      ),
      JournalStateTone.loading => (
        Icons.hourglass_top,
        scheme.primaryContainer,
        scheme.onPrimaryContainer,
        true,
      ),
      JournalStateTone.insufficient => (
        Icons.info_outline,
        scheme.secondaryContainer,
        scheme.onSecondaryContainer,
        false,
      ),
      JournalStateTone.error => (
        Icons.error_outline,
        scheme.errorContainer,
        scheme.onErrorContainer,
        true,
      ),
      JournalStateTone.private => (
        Icons.visibility_off_outlined,
        scheme.tertiaryContainer,
        scheme.onTertiaryContainer,
        false,
      ),
    };

    return Semantics(
      container: true,
      liveRegion: liveRegion,
      label: '$title。$message',
      child: ExcludeSemantics(
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(KurashilogRadius.medium),
          ),
          child: Padding(
            padding: const EdgeInsets.all(KurashilogSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: <Widget>[
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(icon, color: foreground),
                    const SizedBox(width: KurashilogSpacing.sm),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            title,
                            style: Theme.of(context).textTheme.titleMedium
                                ?.copyWith(
                                  color: foreground,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                          const SizedBox(height: KurashilogSpacing.xs),
                          Text(message, style: TextStyle(color: foreground)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (action != null) ...<Widget>[
                  const SizedBox(height: KurashilogSpacing.md),
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
