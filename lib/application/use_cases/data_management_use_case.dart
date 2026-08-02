import 'dart:io';

import 'package:path_provider/path_provider.dart';

import '../repositories/kurashilog_repository.dart';

/// データ管理（設計書 FR-110 全削除 / PR-05 / 8.1 削除手順）。
class DataManagementUseCase {
  const DataManagementUseCase({required this.repository});

  final KurashilogRepository repository;

  /// 全データ削除（オフラインで完了し、再起動後も復元されない）。
  ///
  /// 設計書 8.1: DB close → ファイル削除 → キャッシュ削除 → 設定初期化。
  /// MVP ではアプリを止めずに全テーブルをクリアし、キャッシュも削除する。
  Future<void> deleteAllUserData() async {
    await repository.deleteAllUserData();
    await _clearCacheDir();
  }

  Future<void> _clearCacheDir() async {
    try {
      final dir = await getTemporaryDirectory();
      final d = Directory(dir.path);
      if (!await d.exists()) return;
      await for (final e in d.list()) {
        if (e is File && e.path.contains('kurashilog_share_')) {
          try {
            await e.delete();
          } on FileSystemException {
            // ベストエフォート
          }
        }
      }
    } catch (_) {
      // キャッシュ削除の失敗は致命的ではない
    }
  }
}
