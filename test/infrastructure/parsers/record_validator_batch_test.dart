import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/lat_lng.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/parsers/record_validator.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  test('validation emits bounded deterministic batches', () async {
    final base = DateTime.utc(2026, 1, 1);
    final records = Stream<NormalizedRecord>.fromIterable(
      List.generate(1201, (index) {
        final start = base.add(Duration(minutes: index * 2));
        return NormalizedVisit(
          sourceKey: 'visit-$index',
          startAtUtc: start,
          endAtUtc: start.add(const Duration(minutes: 1)),
          latLng: LatLngE7(350000000 + index, 1390000000 + index),
        );
      }),
    );

    final batches = await const RecordValidator()
        .validateBatches(records, CancellationToken(), batchSize: 500)
        .toList();

    expect(batches.map((batch) => batch.totalRecords), [500, 500, 201]);
    expect(batches.map((batch) => batch.isFinal), [false, false, true]);
    expect(batches.last.processedRecords, 1201);
    expect(
      batches.expand((batch) => batch.visits).map((visit) => visit.sourceKey),
      [for (var index = 0; index < 1201; index++) 'visit-$index'],
    );
  });

  test('invalid batch size is rejected before consuming input', () async {
    expect(
      const RecordValidator()
          .validateBatches(
            const Stream<NormalizedRecord>.empty(),
            CancellationToken(),
            batchSize: 0,
          )
          .drain<void>(),
      throwsArgumentError,
    );
  });
}
