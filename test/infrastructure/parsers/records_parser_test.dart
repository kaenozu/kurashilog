import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  test(
    'same placeId at different times produces distinct visit keys',
    () async {
      const json = '''
{
  "semanticSegments": [
    {
      "startTime": "2026-07-01T00:00:00Z",
      "endTime": "2026-07-01T01:00:00Z",
      "visit": {
        "topCandidate": {
          "placeId": "same-place",
          "semanticType": "HOME",
          "placeLocation": "geo:35.681236,139.767125"
        }
      }
    },
    {
      "startTime": "2026-07-02T00:00:00Z",
      "endTime": "2026-07-02T01:00:00Z",
      "visit": {
        "topCandidate": {
          "placeId": "same-place",
          "semanticType": "HOME",
          "placeLocation": "geo:35.681236,139.767125"
        }
      }
    }
  ]
}
''';

      final records = await const RecordsTimelineParser()
          .parse(Stream.value(utf8.encode(json)), CancellationToken())
          .toList();
      final visits = records.whereType<NormalizedVisit>().toList();

      expect(visits, hasLength(2));
      expect(visits[0].sourceKey, isNot(visits[1].sourceKey));
    },
  );

  test('preview reports malformed JSON as an error', () async {
    final preview = await const RecordsTimelineParser().preview(
      Stream.value(utf8.encode('{"semanticSegments":[')),
      CancellationToken(),
    );

    expect(preview.isOk, isFalse);
    expect(preview.errorCode, 'IMP-003');
  });

  test('legacy locations beyond the buffer limit abort with IMP-006', () async {
    final points = List.generate(
      5,
      (index) =>
          '{"timestampMs":"${1720000000000 + index * 60000}",'
          '"latitudeE7":356812360,"longitudeE7":1397671250}',
    );
    final json = '{"locations":[${points.join(',')}]}';
    const parser = RecordsTimelineParser(legacyMaxPoints: 4);

    final preview = await parser.preview(
      Stream.value(utf8.encode(json)),
      CancellationToken(),
    );
    expect(preview.isOk, isFalse);
    expect(preview.errorCode, 'IMP-006');
    expect(preview.errorMessage, contains('上限'));

    await expectLater(
      parser
          .parse(Stream.value(utf8.encode(json)), CancellationToken())
          .toList(),
      throwsA(
        isA<ImportParseException>().having((e) => e.code, 'code', 'IMP-006'),
      ),
    );
  });
}
