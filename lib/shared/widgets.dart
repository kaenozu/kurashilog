import 'package:flutter/material.dart';

import '../domain/models/data_quality.dart';

/// 品質バッジ（設計書 7.3 / 6.2「色＋文言＋アイコン」）。
class QualityBadge extends StatelessWidget {
  const QualityBadge({super.key, required this.quality, this.compact = false});

  final DataQuality quality;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (bg, fg, icon) = switch (quality) {
      DataQuality.high => (
          scheme.primaryContainer,
          scheme.onPrimaryContainer,
          Icons.check_circle_outline,
        ),
      DataQuality.medium => (
          scheme.secondaryContainer,
          scheme.onSecondaryContainer,
          Icons.info_outline,
        ),
      DataQuality.low => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.update,
        ),
      DataQuality.quiteLow => (
          scheme.errorContainer,
          scheme.onErrorContainer,
          Icons.warning_amber_rounded,
        ),
      DataQuality.historyOnly => (
          scheme.surfaceContainerHighest,
          scheme.onSurfaceVariant,
          Icons.history,
        ),
    };

    final label = compact
        ? quality.label
        : '鮮度: ${quality.label}（${quality.description}）';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: fg),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: Theme.of(context)
                  .textTheme
                  .labelMedium
                  ?.copyWith(color: fg),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

/// 主要値カード（設計書 6.2「短い説明を添えたカード」）。
class MetricCard extends StatelessWidget {
  const MetricCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.deltaLabel,
    this.note,
  });

  final IconData icon;
  final String label;
  final String value;
  final String? deltaLabel;
  final String? note;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, size: 18, color: scheme.primary),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.labelLarge
                        ?.copyWith(color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: theme.textTheme.headlineSmall
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (deltaLabel != null) ...[
              const SizedBox(height: 4),
              Text(
                deltaLabel!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.primary),
              ),
            ],
            if (note != null) ...[
              const SizedBox(height: 2),
              Text(
                note!,
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: scheme.onSurfaceVariant),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// 空状態（設計書 6.2「空状態を専用画面として設計」）。
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(title, style: theme.textTheme.titleLarge),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
            ),
            if (action != null) ...[
              const SizedBox(height: 20),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
