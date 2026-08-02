import 'json_event_parser.dart';

/// スキーマ検出（設計書 5.1 手順 2 / リスク「未知形式を安全拒否」）。
class SchemaDetector {
  const SchemaDetector();

  /// トップレベルキーを読み、対応するRecords形式か判定する。
  Future<String?> detect(Stream<List<int>> source) async {
    final parser = JsonEventParser();
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
              if (rootDepth == 0 && inRootObject) return null;
            case JsonEventType.key:
              if (rootDepth == 1 && _isSupportedKey(event.key)) {
                return 'timeline-records';
              }
            case JsonEventType.arrayStart:
            case JsonEventType.arrayEnd:
            case JsonEventType.value:
              break;
          }
        }
      }
      parser.finish();
    } on JsonParseException {
      return null;
    } on FormatException {
      return null;
    }
    return null;
  }

  bool _isSupportedKey(String? key) =>
      key == 'semanticSegments' ||
      key == 'locations' ||
      key == 'activitySegments';
}
