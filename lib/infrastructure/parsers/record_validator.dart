import '../../domain/models/distance_method.dart';
import '../../domain/models/normalized_record.dart';
import '../../domain/services/distance_service.dart';
import '../../application/models/persistence_models.dart';
import 'timeline_parser.dart';

/// 検証結果。
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

/// レコード検証（設計書 5.4 検証規則）。
///
/// - 座標が範囲外 → レコードを破棄し warning。
/// - 開始 > 終了 → 補正せず破棄。
/// - 開始 = 終了 → 訪問は破棄、移動は距離 0 なら破棄。
/// - 速度が非現実的 → レコードは保持可能だが距離集計から除外し品質低下。
/// - 必須トップレベルキーなし → ファイル全体を unsupported で終了（検出側）。
/// - 未知フィールド → 無視し、パーサーバージョンと警告件数を記録。
class RecordValidator {
  const RecordValidator({this.distanceService = const DistanceService()});

  final DistanceService distanceService;

  Future<ValidationResult> validate(
    Stream<NormalizedRecord> records,
    CancellationToken token,
  ) async {
    final visits = <StoredVisit>[];
    final movements = <StoredMovement>[];
    final warningMap = <String, ImportWarning>{};

    void warn(String code, String message) {
      warningMap[code] = (warningMap[code] ?? ImportWarning(code, message))
          .mergedWith(ImportWarning(code, message));
    }

    await for (final record in records) {
      if (token.isCancelled) {
        throw const ImportParseException('IMP-005', 'キャンセルされました');
      }
      switch (record) {
        case NormalizedVisit():
          final v = _validateVisit(record, warn);
          if (v != null) visits.add(v);
        case NormalizedMovement():
          final m = _validateMovement(record, warn);
          if (m != null) movements.add(m);
      }
    }

    return ValidationResult(
      visits: visits,
      movements: movements,
      warnings: warningMap.values.toList(),
    );
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

    // 異常速度: レコードは保持し、日常移動集計から除外（設計書 6.2）。
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
