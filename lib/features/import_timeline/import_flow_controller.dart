import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/providers.dart';
import '../../application/use_cases/import_use_case.dart';
import '../../infrastructure/parsers/timeline_parser.dart';
import '../../infrastructure/platform/app_platform.dart';

/// インポートフローのフェーズ。
enum ImportPhase { idle, previewing, previewReady, importing, done, error }

class ImportFlowState {
  const ImportFlowState({
    required this.phase,
    this.cachePath,
    this.preview,
    this.progress,
    this.result,
    this.errorCode,
    this.errorMessage,
    this.existingLatestAt,
  });

  final ImportPhase phase;
  final String? cachePath;
  final ImportPreview? preview;
  final ImportProgress? progress;
  final ImportResult? result;
  final String? errorCode;
  final String? errorMessage;

  /// 取込前の既存データ最新記録日（未反映期間の算出に使用）。
  final DateTime? existingLatestAt;

  static const idle = ImportFlowState(phase: ImportPhase.idle);

  ImportFlowState copyWith({
    ImportPhase? phase,
    String? cachePath,
    ImportPreview? preview,
    ImportProgress? progress,
    ImportResult? result,
    String? errorCode,
    String? errorMessage,
    DateTime? existingLatestAt,
    bool clearPath = false,
    bool clearExistingLatestAt = false,
  }) => ImportFlowState(
    phase: phase ?? this.phase,
    cachePath: clearPath ? null : (cachePath ?? this.cachePath),
    preview: preview ?? this.preview,
    progress: progress ?? this.progress,
    result: result ?? this.result,
    errorCode: errorCode ?? this.errorCode,
    errorMessage: errorMessage ?? this.errorMessage,
    existingLatestAt: clearExistingLatestAt
        ? null
        : (existingLatestAt ?? this.existingLatestAt),
  );
}

/// インポートフローの状態管理（設計書 M01 TimelineImport）。
class ImportFlowNotifier extends Notifier<ImportFlowState> {
  @override
  ImportFlowState build() => ImportFlowState.idle;

  ImportUseCase get _useCase => ref.read(importUseCaseProvider);
  AppPlatform get _platform => ref.read(platformProvider);
  CancellationToken? _token;

  /// 共有インテントで受け取ったファイルがあればプレビューを開始する。
  Future<bool> startFromShare() async {
    final path = await _platform.takeSharedFile();
    if (path == null) return false;
    await preview(path);
    return true;
  }

  /// ファイル選択（SAF）から開始。
  Future<void> startFromPicker() async {
    state = const ImportFlowState(phase: ImportPhase.previewing);
    final path = await _platform.pickJsonFile();
    if (path == null) {
      state = ImportFlowState.idle;
      return;
    }
    await preview(path);
  }

  /// プレビュー（DB は変更しない）。
  Future<void> preview(String cachePath) async {
    final token = CancellationToken();
    _token?.cancel();
    _token = token;
    state = ImportFlowState(
      phase: ImportPhase.previewing,
      cachePath: cachePath,
    );

    final result = await _useCase.previewFile(cachePath, token: token);
    if (!identical(_token, token)) return;
    if (!result.ok) {
      state = ImportFlowState(
        phase: ImportPhase.error,
        cachePath: cachePath,
        errorCode: result.errorCode,
        errorMessage: result.errorMessage,
      );
      return;
    }
    // AC6: 未反映期間の表示に使う、取込前の既存データ最新記録日を取得する。
    final existingLatestAt = await ref
        .read(repositoryProvider)
        .latestActivityAt();
    if (!identical(_token, token)) return;
    state = ImportFlowState(
      phase: ImportPhase.previewReady,
      cachePath: cachePath,
      preview: result,
      existingLatestAt: existingLatestAt,
    );
  }

  /// プレビュー承認後の本取込。
  Future<void> startImport() async {
    final path = state.cachePath;
    if (path == null) return;

    final preview = state.preview;
    final token = CancellationToken();
    _token?.cancel();
    _token = token;
    state = ImportFlowState(
      phase: ImportPhase.importing,
      cachePath: path,
      preview: preview,
      progress: const ImportProgress(ImportStage.parsing, percent: 0),
    );

    final result = await _useCase.importFile(
      path,
      token: token,
      previewWarnings: preview?.warnings ?? const [],
      onProgress: (progress) {
        if (!identical(_token, token)) return;
        state = state.copyWith(
          progress: progress,
          phase: ImportPhase.importing,
        );
      },
    );
    if (!identical(_token, token)) return;

    if (result.ok) {
      ref.read(dashboardRefreshProvider.notifier).state++;
      await _cleanupCache();
      state = ImportFlowState(
        phase: ImportPhase.done,
        preview: state.preview,
        result: result,
      );
    } else {
      state = ImportFlowState(
        phase: ImportPhase.error,
        cachePath: path,
        preview: state.preview,
        errorCode: result.errorCode,
        errorMessage: result.errorMessage,
      );
    }
  }

  /// 処理を中断し、途中の一時ファイルを残さず待機状態へ戻す。
  ///
  /// CancellationToken の通知だけでは、非同期処理が完了するまで画面が
  /// importing のままになり、戻る操作や再取込を始められない。先に世代を
  /// 無効化してからキャッシュを削除することで、遅れて届く進捗も無視する。
  Future<void> cancel() async {
    _token?.cancel();
    _token = null;
    await _cleanupCache();
    state = ImportFlowState.idle;
  }

  /// フローを閉じる（キャッシュも削除）。
  Future<void> dismiss() async {
    _token?.cancel();
    _token = null;
    await _cleanupCache();
    state = ImportFlowState.idle;
  }

  Future<void> _cleanupCache() async {
    final path = state.cachePath;
    if (path != null) await deleteCacheFile(path);
    state = state.copyWith(clearPath: true);
  }
}

final importFlowProvider =
    NotifierProvider<ImportFlowNotifier, ImportFlowState>(
      ImportFlowNotifier.new,
    );
