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

enum ImportStage { parsing, validating, clustering, summarizing, insights }

class ImportProgress {
  const ImportProgress(this.stage, {this.percent = 0});

  final ImportStage stage;
  final int percent;
}

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

  Future<ImportPreview> previewFile(
    String path, {
    CancellationToken? token,
  }) async {
    final cancellation = token ?? CancellationToken();
    final file = File(path);
    final int size;
    try {
      size = await file.length();
    } on FileSystemException {
      return _previewError('IMP-001', 'ファイルを開けませんでした');
    }
    if (size == 0) {
      return _previewError('IMP-003', 'ファイルが空です');
    }

    final detected = await schemaDetector.detect(file.openRead());
    if (detected == null) {
      return _previewError('IMP-002', '未対応のファイル形式です');
    }

    final hash = DigestSha256();
    final previewStream = file.openRead().map((chunk) {
      hash.add(chunk);
      return chunk;
    });

    try {
      final preview = await parser.preview(previewStream, cancellation);
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
    } on ImportParseException catch (error) {
      return ImportPreview(
        ok: false,
        fileHash: hash.digest(),
        schemaType: detected,
        errorCode: error.code,
        errorMessage: error.message,
        fileSizeBytes: size,
      );
    } on FileSystemException {
      return _previewError('IMP-001', 'ファイルを読み取れませんでした');
    }
  }

  Future<ImportResult> importFile(
    String path, {
    CancellationToken? token,
    void Function(ImportProgress progress)? onProgress,
  }) async {
    final cancellation = token ?? CancellationToken();
    final file = File(path);
    onProgress?.call(const ImportProgress(ImportStage.parsing, percent: 5));

    final String fileHash;
    try {
      fileHash = await _hashFile(file);
    } on FileSystemException {
      return const ImportResult(
        ok: false,
        errorCode: 'IMP-001',
        errorMessage: 'ファイルを開けませんでした',
      );
    }

    final startedAt = DateTime.now();
    final int importId;
    try {
      importId = await repository.insertImport(ImportedFileRecord(
        id: 0,
        fileHash: fileHash,
        schemaType: parser.schemaType,
        startedAt: startedAt,
        status: 'processing',
      ));
    } catch (_) {
      return const ImportResult(
        ok: false,
        errorCode: 'IMP-004',
        errorMessage: 'データベースの書き込みに失敗しました',
      );
    }

    try {
      onProgress?.call(const ImportProgress(ImportStage.parsing, percent: 10));
      final records = parser.parse(file.openRead(), cancellation);
      final validated = await validator.validate(records, cancellation);
      onProgress?.call(const ImportProgress(ImportStage.validating, percent: 40));

      if (cancellation.isCancelled) {
        await _recordTerminalState(
          importId: importId,
          fileHash: fileHash,
          startedAt: startedAt,
          status: 'cancelled',
          warningCount: validated.warnings.length,
        );
        return const ImportResult(
          ok: false,
          errorCode: 'IMP-005',
          errorMessage: 'キャンセルされました',
        );
      }

      final sourceMinAt = _minStart(validated.visits, validated.movements);
      final sourceMaxAt = _maxEnd(validated.visits, validated.movements);
      late ImportDiffResult diff;

      await repository.runInTransaction(() async {
        onProgress?.call(
          const ImportProgress(ImportStage.parsing, percent: 60),
        );
        diff = await repository.insertNewRecords(
          visits: validated.visits,
          movements: validated.movements,
        );

        if (cancellation.isCancelled) {
          throw const ImportParseException('IMP-005', 'キャンセルされました');
        }

        onProgress?.call(
          const ImportProgress(ImportStage.clustering, percent: 75),
        );
        await analysis.rebuildAll();

        onProgress?.call(
          const ImportProgress(ImportStage.insights, percent: 95),
        );
        await repository.updateImport(ImportedFileRecord(
          id: importId,
          fileHash: fileHash,
          schemaType: parser.schemaType,
          startedAt: startedAt,
          completedAt: DateTime.now(),
          sourceMinAt: sourceMinAt,
          sourceMaxAt: sourceMaxAt,
          status: 'completed',
          warningCount: validated.warnings.length,
          addedVisits: diff.addedVisits,
          addedMovements: diff.addedMovements,
        ));
      });

      onProgress?.call(
        const ImportProgress(ImportStage.insights, percent: 100),
      );
      return ImportResult(
        ok: true,
        addedVisits: diff.addedVisits,
        addedMovements: diff.addedMovements,
        sourceMinAt: sourceMinAt,
        sourceMaxAt: sourceMaxAt,
        warnings: validated.warnings,
      );
    } on ImportParseException catch (error) {
      await _recordTerminalState(
        importId: importId,
        fileHash: fileHash,
        startedAt: startedAt,
        status: error.code == 'IMP-005' ? 'cancelled' : 'failed',
      );
      return ImportResult(
        ok: false,
        errorCode: error.code,
        errorMessage: error.message,
      );
    } on FileSystemException {
      await _recordTerminalState(
        importId: importId,
        fileHash: fileHash,
        startedAt: startedAt,
        status: 'failed',
      );
      return const ImportResult(
        ok: false,
        errorCode: 'IMP-001',
        errorMessage: 'ファイルを読み取れませんでした',
      );
    } catch (_) {
      await _recordTerminalState(
        importId: importId,
        fileHash: fileHash,
        startedAt: startedAt,
        status: 'failed',
      );
      return const ImportResult(
        ok: false,
        errorCode: 'IMP-004',
        errorMessage: 'データベースの更新に失敗しました',
      );
    }
  }

  Future<void> _recordTerminalState({
    required int importId,
    required String fileHash,
    required DateTime startedAt,
    required String status,
    int warningCount = 0,
  }) async {
    try {
      await repository.updateImport(ImportedFileRecord(
        id: importId,
        fileHash: fileHash,
        schemaType: parser.schemaType,
        startedAt: startedAt,
        completedAt: DateTime.now(),
        status: status,
        warningCount: warningCount,
      ));
    } catch (_) {
      // 元の失敗理由を優先する。processing 行は次回起動時の復旧対象にできる。
    }
  }

  DateTime? _minStart(
    List<StoredVisit> visits,
    List<StoredMovement> movements,
  ) {
    DateTime? minimum;
    for (final value in <DateTime>[
      ...visits.map((visit) => visit.startAtUtc),
      ...movements.map((movement) => movement.startAtUtc),
    ]) {
      if (minimum == null || value.isBefore(minimum)) minimum = value;
    }
    return minimum;
  }

  DateTime? _maxEnd(
    List<StoredVisit> visits,
    List<StoredMovement> movements,
  ) {
    DateTime? maximum;
    for (final value in <DateTime>[
      ...visits.map((visit) => visit.endAtUtc),
      ...movements.map((movement) => movement.endAtUtc),
    ]) {
      if (maximum == null || value.isAfter(maximum)) maximum = value;
    }
    return maximum;
  }

  ImportPreview _previewError(String code, String message) => ImportPreview(
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

class DigestSha256 {
  final _sink = _DigestSink();
  late final _converter = sha256.startChunkedConversion(_sink);
  bool _closed = false;

  void add(List<int> bytes) {
    if (_closed) throw StateError('Digest already finalized');
    _converter.add(bytes);
  }

  String digest() {
    if (!_closed) {
      _converter.close();
      _closed = true;
    }
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
