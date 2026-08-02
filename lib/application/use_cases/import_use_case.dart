import 'dart:io';

import 'package:crypto/crypto.dart';

import '../../infrastructure/parsers/record_validator.dart';
import '../../infrastructure/parsers/records_parser.dart';
import '../../infrastructure/parsers/schema_detector.dart';
import '../../infrastructure/parsers/timeline_parser.dart';
import '../../infrastructure/platform/app_platform.dart';
import '../analysis/analysis_coordinator.dart';
import '../models/persistence_models.dart';
import '../repositories/kurashilog_repository.dart';

/// インポート処理の進捗。
enum ImportStage {
  parsing,
  validating,
  clustering,
  summarizing,
  insights,
}

class ImportProgress {
  const ImportProgress(this.stage, {this.percent = 0});

  final ImportStage stage;
  final int percent;
}

/// プレビュー結果（画面表示用）。
class ImportPreview {
  const ImportPreview({
    required this.ok,
    required this.fileHash,
    required this.schemaType,
    this.minAt,
    this.maxAt,
    this.recordCount = 0,
    this.warnings = const [],
    this.errorCode,
    this.errorMessage,
    this.fileSizeBytes = 0,
  });

  final bool ok;
  final String fileHash;
  final String schemaType;
  final DateTime? minAt;
  final DateTime? maxAt;
  final int recordCount;
  final List<ImportWarning> warnings;
  final String? errorCode;
  final String? errorMessage;
  final int fileSizeBytes;

  bool get isUnsupported => errorCode == 'IMP-002';
}

/// インポート結果（画面表示用）。
class ImportResult {
  const ImportResult({
    required this.ok,
    this.addedVisits = 0,
    this.addedMovements = 0,
    this.sourceMinAt,
    this.sourceMaxAt,
    this.warnings = const [],
    this.errorCode,
    this.errorMessage,
  });

  final bool ok;
  final int addedVisits;
  final int addedMovements;
  final DateTime? sourceMinAt;
  final DateTime? sourceMaxAt;
  final List<ImportWarning> warnings;
  final String? errorCode;
  final String? errorMessage;
}

/// タイムラインインポートのユースケース（設計書 5.1 処理シーケンス）。
class ImportUseCase {
  const ImportUseCase({
    required this.repository,
    required this.platform,
    required this.analysis,
    this.schemaDetector = const SchemaDetector(),
    this.parser = const RecordsTimelineParser(),
    this.validator = const RecordValidator(),
  });

  final KurashilogRepository repository;
  final AppPlatform platform;
  final AnalysisCoordinator analysis;
  final SchemaDetector schemaDetector;
  final RecordsTimelineParser parser;
  final RecordValidator validator;

  /// プレビュー：形式・期間・概算件数を取得し、DB は変更しない。
  Future<ImportPreview> previewFile(
    String path, {
    CancellationToken? token,
  }) async {
    final t = token ?? CancellationToken();
    final file = File(path);
    final int size;
    try {
      size = await file.length();
    } on FileSystemException {
      return _error('IMP-001', 'ファイルを開けませんでした');
    }
    if (size == 0) {
      return _error('IMP-003', 'ファイルが空です');
    }

    // 1. スキーマ判定（先頭部分のみ）
    final detected = await schemaDetector.detect(file.openRead());
    if (detected == null) {
      return _error('IMP-002', '未対応のファイル形式です');
    }

    // 2. 期間・概算件数（ハッシュも同時に計算）
    final hash = DigestSha256();
    final previewStream = file.openRead().map((chunk) {
      hash.add(chunk);
      return chunk;
    });

    final PreviewResult preview;
    try {
      preview = await parser.preview(previewStream, t);
    } on ImportParseException catch (e) {
      return ImportPreview(
        ok: false,
        fileHash: hash.digest(),
        schemaType: detected,
        errorCode: e.code,
        errorMessage: e.message,
        fileSizeBytes: size,
      );
    }

    return ImportPreview(
      ok: preview.isOk,
      fileHash: hash.digest(),
      schemaType: detected,
      minAt: preview.minAt,
      maxAt: preview.maxAt,
      recordCount: preview.approxRecordCount,
      warnings: preview.warnings,
      errorCode: preview.errorCode,
      errorMessage: preview.errorMessage,
      fileSizeBytes: size,
    );
  }

  /// 本取込：解析 → 検証 → 差分登録 → 分析再構築。
  ///
  /// 処理の途中で失敗しても既存データは変更されない（設計書 9.1）。
  Future<ImportResult> importFile(
    String path, {
    CancellationToken? token,
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final t = token ?? CancellationToken();
    final file = File(path);

    onProgress?.call(const ImportProgress(ImportStage.parsing, percent: 5));

    final String fileHash;
    try {
      fileHash = await _hashFile(file);
    } on FileSystemException {
      return const ImportResult(
          ok: false, errorCode: 'IMP-001', errorMessage: 'ファイルを開けませんでした');
    }

    final started = DateTime.now();
    final int importId;
    try {
      importId = await repository.insertImport(ImportedFileRecord(
        id: 0,
        fileHash: fileHash,
        schemaType: 'timeline-records',
        startedAt: started,
        status: 'processing',
      ));
    } catch (_) {
      return const ImportResult(
        ok: false,
        errorCode: 'IMP-004',
        errorMessage: 'データベースの書き込みに失敗しました',
      );
    }

    onProgress?.call(const ImportProgress(ImportStage.parsing, percent: 10));

    try {
      // 解析（ストリーム）→ 検証（設計書 5.1 手順 4〜6）
      final recordStream = parser.parse(file.openRead(), t);
      final validated = await validator.validate(recordStream, t);

      onProgress?.call(const ImportProgress(ImportStage.validating, percent: 40));
      if (t.isCancelled) {
        await _completeImport(importId, fileHash, started, 0, 0, null, null,
            validated.warnings.length, 'cancelled');
        return const ImportResult(
            ok: false, errorCode: 'IMP-005', errorMessage: 'キャンセルされました');
      }

      // 差分・重複排除（単一トランザクション）
      onProgress?.call(const ImportProgress(ImportStage.parsing, percent: 60));
      final diff = await repository.insertNewRecords(
        visits: validated.visits,
        movements: validated.movements,
      );

      // 分析再構築（クラスタ → サマリー → インサイト）
      onProgress?.call(const ImportProgress(ImportStage.clustering, percent: 75));
      await analysis.rebuildAll();

      onProgress?.call(const ImportProgress(ImportStage.insights, percent: 95));

      final minAt = _minStart(validated.visits);
      final maxAt = _maxEnd(validated.visits);

      await _completeImport(importId, fileHash, started, diff.addedVisits,
          diff.addedMovements, minAt, maxAt, validated.warnings.length, 'completed');

      onProgress?.call(const ImportProgress(ImportStage.insights, percent: 100));

      return ImportResult(
        ok: true,
        addedVisits: diff.addedVisits,
        addedMovements: diff.addedMovements,
        sourceMinAt: minAt,
        sourceMaxAt: maxAt,
        warnings: validated.warnings,
      );
    } on ImportParseException catch (e) {
      await _completeImport(importId, fileHash, started, 0, 0, null, null, 0,
          'failed', errorCode: e.code);
      return ImportResult(ok: false, errorCode: e.code, errorMessage: e.message);
    } catch (e) {
      await _completeImport(importId, fileHash, started, 0, 0, null, null, 0,
          'failed', errorCode: 'IMP-004');
      return ImportResult(
          ok: false, errorCode: 'IMP-004', errorMessage: e.toString());
    }
  }

  Future<void> _completeImport(
    int id,
    String fileHash,
    DateTime started,
    int addedVisits,
    int addedMovements,
    DateTime? minAt,
    DateTime? maxAt,
    int warningCount,
    String status, {
    String? errorCode,
  }) async {
    try {
      await repository.updateImport(ImportedFileRecord(
        id: id,
        fileHash: fileHash,
        schemaType: 'timeline-records',
        startedAt: started,
        completedAt: DateTime.now(),
        sourceMinAt: minAt,
        sourceMaxAt: maxAt,
        status: status,
        warningCount: warningCount,
        addedVisits: addedVisits,
        addedMovements: addedMovements,
      ));
    } catch (_) {
      // 状態更新の失敗は致命的ではない
    }
  }

  DateTime? _minStart(List<StoredVisit> visits) {
    if (visits.isEmpty) return null;
    var m = visits.first.startAtUtc;
    for (final v in visits) {
      if (v.startAtUtc.isBefore(m)) m = v.startAtUtc;
    }
    return m;
  }

  DateTime? _maxEnd(List<StoredVisit> visits) {
    if (visits.isEmpty) return null;
    var m = visits.first.endAtUtc;
    for (final v in visits) {
      if (v.endAtUtc.isAfter(m)) m = v.endAtUtc;
    }
    return m;
  }

  ImportPreview _error(String code, String message) => ImportPreview(
        ok: false,
        fileHash: '',
        schemaType: 'unknown',
        errorCode: code,
        errorMessage: message,
      );

  Future<String> _hashFile(File file) async {
    final hash = DigestSha256();
    await for (final chunk in file.openRead()) {
      hash.add(chunk);
    }
    return hash.digest();
  }
}

/// SHA-256 の逐次計算ヘルパー（ストリームに挟んで全体ハッシュを取る）。
class DigestSha256 {
  final _sink = _DigestSink();
  late final _converter = sha256.startChunkedConversion(_sink);

  void add(List<int> bytes) => _converter.add(bytes);

  String digest() {
    _converter.close();
    return _sink.digest?.toString() ?? '';
  }
}

class _DigestSink implements Sink<Digest> {
  Digest? digest;

  @override
  void add(Digest data) => digest = data;

  @override
  void close() {}
}
