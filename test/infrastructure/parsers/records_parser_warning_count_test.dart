import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  const parser = RecordsTimelineParser();

  Future<PreviewResult> preview(List<Map<String, Object?>> segments) {
    final bytes = utf8.encode(jsonEncode({'semanticSegments': segments}));
    return parser.preview(Stream.value(bytes), CancellationToken());
  }

  Map<String, Object?> unsupported(int hour) => {
    'startTime': '2026-07-20T${hour.toString().padLeft(2, '0')}:00:00Z',
    'endTime': '2026-07-20T${hour.toString().padLeft(2, '0')}:30:00Z',
    'timelineMemory': {'unsupported': true},
  };

  Map<String, Object?> sparsePath(int hour) => {
    'startTime': '2026-07-20T${hour.toString().padLeft(2, '0')}:00:00Z',
    'endTime': '2026-07-20T${hour.toString().padLeft(2, '0')}:30:00Z',
    'timelinePath': [
      {'point': '35.0, 139.0'},
    ],
  };

  test('a warning code seen once has count 1', () async {
    final result = await preview([unsupported(0)]);

    expect(result.isOk, isTrue);
    expect(result.approxRecordCount, 0);
    expect(result.warnings, hasLength(1));
    expect(result.warnings.single.code, 'PAR-001');
    expect(result.warnings.single.count, 1);
  });

  test('warning counts match events independently for each code', () async {
    final result = await preview([
      unsupported(0),
      sparsePath(1),
      unsupported(2),
      sparsePath(3),
      sparsePath(4),
    ]);
    final counts = {
      for (final warning in result.warnings) warning.code: warning.count,
    };

    expect(result.isOk, isTrue);
    expect(result.approxRecordCount, 0);
    expect(counts, {'PAR-001': 2, 'PAR-004': 3});
  });
}
