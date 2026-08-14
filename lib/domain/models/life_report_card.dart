import 'comparison.dart';

/// The stable kinds used by the first life-report presentation contract.
enum LifeReportCardKind {
  coverage,
  topPlace,
  largestChange,
  disappearedPlace,
  changePeriod,
  fallback,
}

/// Describes whether a card is a direct fact, an inference, or user meaning.
enum ReportConfidence { fact, inference, userConfirmed }

/// Describes how a card may be exposed by a privacy-safe projection.
enum ReportPrivacyState { visible, hidden, redacted, excluded }

/// A structured supporting value. UI copy is intentionally not persisted here.
final class ReportFact {
  const ReportFact({required this.label, required this.value, this.unit});

  final String label;
  final String value;
  final String? unit;
}

/// Stable, privacy-safe pointers to the records behind a report card.
///
/// References are identifiers only. They must be resolved inside the app and
/// must never be rendered as raw paths, coordinates, or source payloads.
final class EvidenceRef {
  factory EvidenceRef({
    required LocalDateRange period,
    String? metricKey,
    Iterable<String> clusterKeys = const <String>[],
    Iterable<String> sourceKeys = const <String>[],
  }) {
    final normalizedMetric = _optionalKey(metricKey);
    final normalizedClusters = _keys(clusterKeys, 'clusterKeys');
    final normalizedSources = _keys(sourceKeys, 'sourceKeys');
    if (normalizedMetric == null &&
        normalizedClusters.isEmpty &&
        normalizedSources.isEmpty) {
      throw ArgumentError(
        'EvidenceRef requires at least one stable metric, cluster, or source reference',
      );
    }
    return EvidenceRef._(
      period: period,
      metricKey: normalizedMetric,
      clusterKeys: normalizedClusters,
      sourceKeys: normalizedSources,
    );
  }

  const EvidenceRef._({
    required this.period,
    required this.metricKey,
    required this.clusterKeys,
    required this.sourceKeys,
  });

  final LocalDateRange period;
  final String? metricKey;
  final List<String> clusterKeys;
  final List<String> sourceKeys;

  bool get hasStableReference =>
      metricKey != null || clusterKeys.isNotEmpty || sourceKeys.isNotEmpty;
}

/// Immutable presentation-neutral contract shared by insights and UI cards.
///
/// A card is only valid when it has a period and evidence. If evidence is not
/// sufficient, callers should omit the card or provide an explicit
/// [unavailableReason] rather than inventing a conclusion.
final class LifeReportCard {
  factory LifeReportCard({
    required String id,
    required LifeReportCardKind kind,
    required String headline,
    Iterable<ReportFact> supportingFacts = const <ReportFact>[],
    required LocalDateRange period,
    required ComparisonQuality comparisonQuality,
    required ReportConfidence confidence,
    required EvidenceRef evidence,
    ReportPrivacyState privacyState = ReportPrivacyState.visible,
    String? unavailableReason,
  }) {
    final normalizedId = _requiredText(id, 'id');
    final normalizedHeadline = _requiredText(headline, 'headline');
    final normalizedReason = _optionalText(
      unavailableReason,
      'unavailableReason',
    );
    if (evidence.period != period) {
      throw ArgumentError.value(
        evidence.period,
        'evidence',
        'Evidence period must match the card period',
      );
    }
    return LifeReportCard._(
      id: normalizedId,
      kind: kind,
      headline: normalizedHeadline,
      supportingFacts: List<ReportFact>.unmodifiable(supportingFacts),
      period: period,
      comparisonQuality: comparisonQuality,
      confidence: confidence,
      evidence: evidence,
      privacyState: privacyState,
      unavailableReason: normalizedReason,
    );
  }

  const LifeReportCard._({
    required this.id,
    required this.kind,
    required this.headline,
    required this.supportingFacts,
    required this.period,
    required this.comparisonQuality,
    required this.confidence,
    required this.evidence,
    required this.privacyState,
    required this.unavailableReason,
  });

  final String id;
  final LifeReportCardKind kind;
  final String headline;
  final List<ReportFact> supportingFacts;
  final LocalDateRange period;
  final ComparisonQuality comparisonQuality;
  final ReportConfidence confidence;
  final EvidenceRef evidence;
  final ReportPrivacyState privacyState;
  final String? unavailableReason;
}

String _requiredText(String value, String name) {
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be empty');
  }
  return normalized;
}

String? _optionalText(String? value, String name) {
  if (value == null) return null;
  final normalized = value.trim();
  if (normalized.isEmpty) {
    throw ArgumentError.value(value, name, 'Must not be blank');
  }
  return normalized;
}

String? _optionalKey(String? value) =>
    value == null ? null : _requiredText(value, 'metricKey');

List<String> _keys(Iterable<String> values, String name) {
  final result = <String>[];
  for (final value in values) {
    result.add(_requiredText(value, name));
  }
  return List<String>.unmodifiable(result);
}
