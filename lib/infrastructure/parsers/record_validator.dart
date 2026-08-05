import '../../domain/models/distance_method.dart';
import '../../domain/models/normalized_record.dart';
import '../../domain/services/distance_service.dart';
import '../../application/models/persistence_models.dart';
import 'timeline_parser.dart';

/// Complete validation result for small inputs and compatibility callers.
class ValidationResult {
  const ValidationResult({
    required this.visits,
    required this.movements,
    required this.warnings,
  });

  final List<StoredVisit> visits;
  final List<StoredMovement> movements;
  final List<ImportWarning> warnings;

  int get totalRecords => visits.length + movements.length;
}

/// A bounded validation batch. Warnings are cumulative so the final batch is
/// the authoritative warning snapshot even when it contains no records.
class ValidationBatch {
  const ValidationBatch({
    required this.visits,
    required this.movements,
    required this.warnings,
    required this.processedRecords,
    required this.isFinal,
  });

  final List<StoredVisit> visits;
  final List<StoredMovement> movements;
  final List<ImportWarning> warnings;
  final int processedRecords;
  final bool isFinal;

  int get totalRecords => visits.length + movements.length;
}

/// Record validation with a bounded-memory streaming API.
class RecordValidator {
  const RecordValidator({this.distanceService = const DistanceService()});

  final DistanceService distanceService;

  Future<ValidationResult> validate(
    Stream<NormalizedRecord> records,
    CancellationToken token,
  ) async {
    final visits = <StoredVisit>[];
    final movements = <StoredMovement>[];
    var warnings = const <ImportWarning>[];
    await for (final batch in validateBatches(records, token)) {
      visits.addAll(batch.visits);
      movements.addAll(batch.movements);
      warnings = batch.warnings;
    }
    return ValidationResult(
      visits: visits,
      movements: movements,
      warnings: warnings,
    );
  }

  Stream<ValidationBatch> validateBatches(
    Stream<NormalizedRecord> records,
    CancellationToken token, {
    int batchSize = 500,
  }) async* {
    if (batchSize < 1) {
      throw ArgumentError.value(batchSize, 'batchSize', 'must be positive');
    }

    final visits = <StoredVisit>[];
    final movements = <StoredMovement>[];
    final warningMap = <String, ImportWarning>{};
    var processedRecords = 0;

    void warn(String code, String message) {
      warningMap[code] = (warningMap[code] ?? ImportWarning(code, message))
          .mergedWith(ImportWarning(code, message));
    }

    ValidationBatch snapshot({required bool isFinal}) => ValidationBatch(
      visits: List.unmodifiable(visits),
      movements: List.unmodifiable(movements),
      warnings: List.unmodifiable(warningMap.values),
      processedRecords: processedRecords,
      isFinal: isFinal,
    );

    await for (final record in records) {
      if (token.isCancelled) {
        throw const ImportParseException('IMP-005', 'キャンセルされました');
      }
      processedRecords++;
      switch (record) {
        case NormalizedVisit():
          final visit = _validateVisit(record, warn);
          if (visit != null) visits.add(visit);
        case NormalizedMovement():
          final movement = _validateMovement(record, warn);
          if (movement != null) movements.add(movement);
      }

      if (visits.length + movements.length >= batchSize) {
        yield snapshot(isFinal: false);
        visits.clear();
        movements.clear();
      }
    }

    yield snapshot(isFinal: true);
  }

  StoredVisit? _validateVisit(
    NormalizedVisit visit,
    void Function(String code, String message) warn,
  ) {
    if (!visit.latLng.isValid) {
      warn('VAL-001', '座標が範囲外の訪問を破棄しました');
      return null;
    }
    if (visit.endAtUtc.isBefore(visit.startAtUtc)) {
      warn('VAL-002', '開始時刻が終了より後の訪問を破棄しました');
      return null;
    }
    if (visit.endAtUtc == visit.startAtUtc) {
      warn('VAL-003', '滞在時間が 0 の訪問を破棄しました');
      return null;
    }
    return StoredVisit(
      id: 0,
      sourceKey: visit.sourceKey,
      startAtUtc: visit.startAtUtc,
      endAtUtc: visit.endAtUtc,
      latE7: visit.latLng.latE7,
      lngE7: visit.latLng.lngE7,
      accuracyM: visit.accuracyM,
      sourceLabel: visit.sourceLabel,
      confidence: visit.confidence,
    );
  }

  StoredMovement? _validateMovement(
    NormalizedMovement movement,
    void Function(String code, String message) warn,
  ) {
    if (movement.endAtUtc.isBefore(movement.startAtUtc)) {
      warn('VAL-002', '開始時刻が終了より後の移動を破棄しました');
      return null;
    }
    if (movement.endAtUtc == movement.startAtUtc &&
        movement.effectiveDistanceM == 0) {
      warn('VAL-003', '滞在時間が 0 の移動を破棄しました');
      return null;
    }

    var validDistance =
        movement.distanceMethod != DistanceMethod.unknown &&
        movement.distanceM != null;
    if (validDistance &&
        distanceService.isAbsurdSpeed(
          distanceM: movement.distanceM!,
          start: movement.startAtUtc,
          end: movement.endAtUtc,
        )) {
      validDistance = false;
      warn('VAL-004', '異常速度の移動を日常集計から除外しました');
    }

    return StoredMovement(
      id: 0,
      sourceKey: movement.sourceKey,
      startAtUtc: movement.startAtUtc,
      endAtUtc: movement.endAtUtc,
      distanceM: movement.distanceM,
      distanceMethod: movement.distanceMethod,
      activityType: movement.activityType,
      confidence: movement.confidence,
      startLatLng: movement.startLatLng,
      endLatLng: movement.endLatLng,
      path: movement.path,
      validDistance: validDistance,
    );
  }
}
