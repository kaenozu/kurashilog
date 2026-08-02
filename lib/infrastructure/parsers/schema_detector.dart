import 'dart:async';
import 'dart:convert';

import 'json_event_parser.dart';
import 'timeline_parser.dart';

/// スキーマ検出（設計書 5.1 手順 2 / リスク「未知形式を安全拒否」）。
///
/// 先頭部分とトップレベルキーを読み、対応パーサーを選択する。
/// 未知形式は無理に解析せず、判定不能として安全に終了する。
class SchemaDetector {
  const SchemaDetector();

  /// Records.json（現行 Android 書き出し、タイムライン）のトップレベルキー。
  static const _recordsKeys = {
    'semanticSegments',
    'locations',
    'activitySegments',
  };

  /// 先頭チャンクから対応スキーマ種別を判定する。
  ///
  /// 戻り値: 'timeline-records' / 'timeline-legacy' / null（判定不能）。
  Future<String?> detect(Stream<List<int>> source) async {
    final parser = JsonEventParser();
    final topKeys = <String>{};
    var sawArrayValue = false;
    var rootDepth = 0;
    var inRootObject = false;

    try {
      await for (final chunk in source) {
        for (final event in parser.addChunk(chunk)) {
          switch (event.type) {
            case JsonEventType.objectStart:
              rootDepth++;
              if (rootDepth == 1) inRootObject = true;
            case JsonEventType.objectEnd:
              if (rootDepth > 0) rootDepth--;
              if (rootDepth == 0 && inRootObject) {
                // ルートオブジェクトのクローズが確認できたら完了
                return _resolve(topKeys, sawArrayValue);
              }
            case JsonEventType.arrayStart:
              if (rootDepth <= 1 && !sawArrayValue) {
                // トップレベルの配列は何らかのレコード列
                sawArrayValue = true;
              }
            case JsonEventType.arrayEnd:
              break;
            case JsonEventType.key:
              if (rootDepth == 1) topKeys.add(event.key ?? '');
            case JsonEventType.value:
              break;
          }
        }
      }
      parser.finish();
    } on JsonParseException {
      return null; // 構文エラーはパーサー側で再検出する
    } on FormatException {
      return null;
    }

    if (inRootObject && rootDepth <= 0) return _resolve(topKeys, sawArrayValue);
    // ルートが配列などの変則形式
    return null;
  }

  String? _resolve(Set<String> topKeys, bool sawArrayValue) {
    if (topKeys.contains('semanticSegments') ||
        topKeys.contains('locations') ||
        topKeys.contains('activitySegments')) {
      return 'timeline-records';
    }
    return null;
  }
}
