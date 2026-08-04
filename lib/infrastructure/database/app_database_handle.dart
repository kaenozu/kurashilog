import 'dart:async';
import 'dart:io';

import 'app_database.dart';

typedef DatabaseOpener = Future<AppDatabase> Function(String path);
typedef DatabaseFileDeleter = Future<void> Function(File file);

class DatabaseResetException implements Exception {
  const DatabaseResetException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() => 'DatabaseResetException($message)';
}

/// Serializes database access and owns crash-recoverable physical resets.
class AppDatabaseHandle {
  AppDatabaseHandle._({
    required String databasePath,
    required DatabaseOpener opener,
    required DatabaseFileDeleter deleteFile,
    required AppDatabase database,
  }) : _databasePath = databasePath,
       _opener = opener,
       _deleteFile = deleteFile,
       _database = database;

  static const String resetMarkerSuffix = '.reset-pending';
  static const String stagedSuffix = '.resetting';

  final String _databasePath;
  final DatabaseOpener _opener;
  final DatabaseFileDeleter _deleteFile;

  AppDatabase _database;
  Future<void> _tail = Future<void>.value();
  bool _closed = false;

  String get databasePath => _databasePath;

  static Future<AppDatabaseHandle> open({
    String? databasePath,
    DatabaseOpener? opener,
    DatabaseFileDeleter? deleteFile,
  }) async {
    final resolvedPath = databasePath ?? await AppDatabase.defaultPath();
    final resolvedOpener = opener ?? AppDatabase.openAtPath;
    final resolvedDeleteFile = deleteFile ?? _deleteIfPresent;

    await _completePendingReset(
      resolvedPath,
      deleteFile: resolvedDeleteFile,
    );
    final database = await resolvedOpener(resolvedPath);
    return AppDatabaseHandle._(
      databasePath: resolvedPath,
      opener: resolvedOpener,
      deleteFile: resolvedDeleteFile,
      database: database,
    );
  }

  Future<T> run<T>(Future<T> Function(AppDatabase database) action) {
    return _enqueue(() async {
      if (_closed) throw StateError('Database handle is closed');
      return action(_database);
    });
  }

  /// Blocks new work, drains queued work, and replaces the database physically.
  Future<void> reset() {
    return _enqueue(() async {
      if (_closed) throw StateError('Database handle is closed');

      final marker = File('$_databasePath$resetMarkerSuffix');
      await marker.parent.create(recursive: true);
      await marker.writeAsString('pending\n', flush: true);

      Object? originalError;
      StackTrace? originalStackTrace;
      try {
        await _database.customStatement('PRAGMA wal_checkpoint(TRUNCATE);');
        await _database.close();
        await _completePendingReset(
          _databasePath,
          deleteFile: _deleteFile,
        );
      } catch (error, stackTrace) {
        originalError = error;
        originalStackTrace = stackTrace;
        try {
          await _completePendingReset(
            _databasePath,
            deleteFile: _deleteFile,
          );
        } catch (recoveryError) {
          throw DatabaseResetException(
            'データベースの物理削除と復旧に失敗しました',
            recoveryError,
          );
        }
      }

      _database = await _opener(_databasePath);
      if (originalError != null) {
        Error.throwWithStackTrace(
          DatabaseResetException('データベースの物理削除に失敗しました', originalError),
          originalStackTrace!,
        );
      }
    });
  }

  Future<void> close() {
    return _enqueue(() async {
      if (_closed) return;
      _closed = true;
      await _database.close();
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() action) {
    final result = _tail.then((_) => action());
    _tail = result.then<void>(
      (_) {},
      onError: (Object _, StackTrace _) {},
    );
    return result;
  }

  static Future<void> _completePendingReset(
    String databasePath, {
    required DatabaseFileDeleter deleteFile,
  }) async {
    final marker = File('$databasePath$resetMarkerSuffix');
    if (!await marker.exists()) return;

    final originals = <File>[
      File(databasePath),
      File('$databasePath-wal'),
      File('$databasePath-shm'),
    ];

    for (final original in originals) {
      final staged = File('${original.path}$stagedSuffix');
      if (await staged.exists()) await deleteFile(staged);
      if (await original.exists()) await original.rename(staged.path);
    }

    for (final original in originals) {
      await deleteFile(File('${original.path}$stagedSuffix'));
    }

    final remaining = <String>[];
    for (final original in originals) {
      if (await original.exists()) remaining.add(original.path);
      final staged = File('${original.path}$stagedSuffix');
      if (await staged.exists()) remaining.add(staged.path);
    }
    if (remaining.isNotEmpty) {
      throw FileSystemException(
        'Database reset left files behind: ${remaining.join(', ')}',
      );
    }

    await deleteFile(marker);
  }

  static Future<void> _deleteIfPresent(File file) async {
    if (await file.exists()) await file.delete();
  }
}
