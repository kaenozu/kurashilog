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
  });

  final ImportPhase phase;
  final String? cachePath;
  final ImportPreview? preview;
  final ImportProgress? progress;
  final ImportResult? result;
  final String? errorCode;
  final String? errorMessage;

  static const idle = ImportFlowState(phase: ImportPhase.idle);

  ImportFlowState copyWith({
    ImportPhase? phase,
    String? cachePath,
    ImportPreview? preview,
    ImportProgress? progress,
    ImportResult? result,
    String? errorCode,
    String? errorMessage,
    bool clearPath = false,
  }) => ImportFlowState(
    phase: phase ?? this.phase,
    cachePath: clearPath ? null : (cachePath ?? this.cachePath),
    preview: preview ?? this.preview,
    progress: progress ?? this.progress,
    result: result ?? this.result,
    errorCode: errorCode ?? this.errorCode,
    errorMessage: errorMessage ?? this.errorMessage,
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
    _token = CancellationToken();
    state = ImportFlowState(
      phase: ImportPhase.previewing,
      cachePath: cachePath,
    );
    final preview = await _useCase.previewFile(cachePath, token: _token);
    if (!mounted) return;
    if (!preview.ok) {
      state = ImportFlowState(
        phase: ImportPhase.error,
        cachePath: cachePath,
        errorCode: preview.errorCode,
        errorMessage: preview.errorMessage,
      );
      return;
    }
    state = ImportFlowState(
      phase: ImportPhase.previewReady,
      cachePath: cachePath,
      preview: preview,
    );
  }

  /// プレビュー承認後の本取込。
  Future<void> startImport() async {
    final path = state.cachePath;
    if (path == null) return;
    _token = CancellationToken();
    state = ImportFlowState(
      phase: ImportPhase.importing,
      cachePath: path,
      preview: state.preview,
      progress: const ImportProgress(ImportStage.parsing, percent: 0),
    );
    final result = await _useCase.importFile(
      path,
      token: _token,
      onProgress: (p) {
        if (!mounted) return;
        state = state.copyWith(progress: p, phase: ImportPhase.importing);
      },
    );
    if (!mounted) return;
    if (result.ok) {
      // ホーム等の再読込を促す
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

  void cancel() {
    _token?.cancel();
  }

  /// フローを閉じる（キャッシュも削除）。
  Future<void> dismiss() async {
    await _cleanupCache();
    state = ImportFlowState.idle;
  }

  Future<void> _cleanupCache() async {
    final path = state.cachePath;
    if (path != null) {
      await deleteCacheFile(path);
    }
    state = state.copyWith(clearPath: true);
  }
}

final importFlowProvider =
    NotifierProvider<ImportFlowNotifier, ImportFlowState>(
      ImportFlowNotifier.new,
    );
