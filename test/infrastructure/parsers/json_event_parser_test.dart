import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/infrastructure/parsers/json_event_parser.dart';

void main() {
  test('parses nested JSON one byte at a time', () {
    const source =
        '{"empty":[],"object":{},"null":null,"text":"日本語\\n😀",'
        '"number":-12.5e2,"bool":true}';
    final parser = JsonEventParser();
    final events = <JsonEvent>[];
    for (final byte in utf8.encode(source)) {
      events.addAll(parser.addChunk([byte]));
    }
    parser.finish();

    expect(
      events.map((event) => event.type),
      containsAllInOrder([
        JsonEventType.objectStart,
        JsonEventType.key,
        JsonEventType.arrayStart,
        JsonEventType.arrayEnd,
        JsonEventType.key,
        JsonEventType.objectStart,
        JsonEventType.objectEnd,
        JsonEventType.key,
        JsonEventType.value,
        JsonEventType.key,
        JsonEventType.value,
        JsonEventType.key,
        JsonEventType.value,
        JsonEventType.key,
        JsonEventType.value,
        JsonEventType.objectEnd,
      ]),
    );

    final values = events
        .where((event) => event.type == JsonEventType.value)
        .map((event) => event.value)
        .toList();
    expect(values, [null, '日本語\n😀', -1250.0, true]);
  });

  test('rejects trailing data and malformed containers', () {
    expect(
      () {
        final parser = JsonEventParser();
        parser.addChunk(utf8.encode('{} {}'));
        parser.finish();
      },
      throwsA(isA<JsonParseException>()),
    );

    expect(
      () {
        final parser = JsonEventParser();
        parser.addChunk(utf8.encode('{"a":]'));
        parser.finish();
      },
      throwsA(isA<JsonParseException>()),
    );
  });
}
