import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import '../repositories/kurashilog_repository.dart';

/// データ管理（設計書 FR-110 全削除 / PR-05 / 8.1 削除手順）。
class DataManagementUseCase {
  const DataManagementUseCase({required this.repository});

  final KurashilogRepository repository;

  /// 全データ削除（オフラインで完了し、再起動後も復元されない）。
  ///
  /// DB本体・WAL・SHMを物理resetした後、共有一時キャッシュも削除する。
  /// いずれかが残存した場合は例外を返し、UIで成功扱いにしない。
  Future<void> deleteAllUserData() async {
    await repository.deleteAllUserData();
    await _clearShareCache();
  }

  Future<void> _clearShareCache() async {
    final directory = await getTemporaryDirectory();
    if (!await directory.exists()) return;

    final targets = <FileSystemEntity>[];
    await for (final entity in directory.list()) {
      if (p.basename(entity.path).startsWith('kurashilog_share_')) {
        targets.add(entity);
      }
    }

    Object? firstError;
    for (final target in targets) {
      try {
        await target.delete(recursive: true);
      } catch (error) {
        firstError ??= error;
      }
    }

    final remaining = <String>[];
    for (final target in targets) {
      if (await target.exists()) remaining.add(target.path);
    }
    if (remaining.isNotEmpty) {
      throw FileSystemException(
        '共有一時キャッシュを完全に削除できませんでした: '
        '${remaining.join(', ')}',
      );
    }
    if (firstError != null) throw firstError;
  }
}
