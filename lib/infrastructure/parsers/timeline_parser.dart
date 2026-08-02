import '../../domain/models/normalized_record.dart';

/// キャンセル要求。
class CancellationToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() => _cancelled = true;
}

/// インポートの警告（破棄したレコードなどの理由）。
class ImportWarning {
  const ImportWarning(this.code, this.message, {this.count = 1});

  final String code;
  final String message;
  final int count;

  ImportWarning mergedWith(ImportWarning other) =>
      ImportWarning(code, message, count: count + other.count);
}

/// プレビュー結果（設計書 5.1 手順 3。DB を変更しない）。
class PreviewResult {
  const PreviewResult({
    required this.schemaType,
    required this.minAt,
    required this.maxAt,
    required this.approxRecordCount,
    this.warnings = const [],
    this.errorCode,
    this.errorMessage,
  });

  final String schemaType;
  final DateTime? minAt;
  final DateTime? maxAt;
  final int approxRecordCount;
  final List<ImportWarning> warnings;
  final String? errorCode;
  final String? errorMessage;

  bool get isOk => errorCode == null;
}

/// タイムライン解析のパーサーインターフェース（設計書 5.2）。
///
/// パーサーは正規化 DTO（[NormalizedRecord]）を返し、
/// 画面・DB モデルを直接生成しない。
abstract interface class TimelineParser {
  String get schemaType;

  /// プレビュー：対象期間と概算レコード数を取得する。DB は変更しない。
  Future<PreviewResult> preview(
    Stream<List<int>> source,
    CancellationToken token,
  );

  /// 本取込：正規化レコードをストリームで返す。
  Stream<NormalizedRecord> parse(
    Stream<List<int>> source,
    CancellationToken token,
  );
}

/// パーサーが失敗したことを表す例外。既存データは変更しない。
class ImportParseException implements Exception {
  const ImportParseException(this.code, this.message);

  /// IMP-002（未対応形式） / IMP-003（破損 JSON） 等。
  final String code;
  final String message;

  @override
  String toString() => 'ImportParseException($code): $message';
}
