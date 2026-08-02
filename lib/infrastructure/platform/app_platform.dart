import 'dart:io';

import 'package:flutter/services.dart';

/// ネイティブ（Android）との橋渡し（設計書 M10 PlatformBridge）。
///
/// - SAF による JSON 選択（FR-010）
/// - ACTION_SEND 共有受信（FR-011）
/// - content:// URI の一時キャッシュへのコピー
///
/// コピー先は一時キャッシュで、Flutter 側は解析後に削除する
/// （元データを永続化しない、設計書 5.1 手順 1・8.1）。
class AppPlatform {
  AppPlatform({MethodChannel? channel})
      : _channel = channel ??
            const MethodChannel('kurashilog/platform');

  final MethodChannel _channel;

  /// SAF で JSON を選択し、一時キャッシュへのパスを返す。キャンセルは null。
  Future<String?> pickJsonFile() async {
    final path = await _channel.invokeMethod<String>('pickJsonFile');
    return path;
  }

  /// 共有インテントで受け取ったファイルを一時キャッシュへコピーし、
  /// パスを返す。未受信なら null。
  Future<String?> takeSharedFile() async {
    final path = await _channel.invokeMethod<String>('takeSharedFile');
    return path;
  }

  /// 受信済み共有 URI をクリアする。
  Future<void> clearShared() async {
    await _channel.invokeMethod<void>('clearShared');
  }

  /// content:// URI を一時キャッシュへコピーし、パスを返す。
  Future<String> copyUriToCache(String uri) async {
    final path = await _channel.invokeMethod<String>('copyUriToCache', {
      'uri': uri,
    });
    if (path == null) {
      throw PlatformException(code: 'IO_ERROR', message: 'コピーに失敗しました');
    }
    return path;
  }
}

/// 一時キャッシュファイルの後片付け（解析後に呼ぶ）。
Future<void> deleteCacheFile(String? path) async {
  if (path == null) return;
  try {
    final f = File(path);
    if (await f.exists()) await f.delete();
  } on FileSystemException {
    // ベストエフォート。キャッシュは OS が掃除できる。
  }
}
