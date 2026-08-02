import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/distance_method.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  const parser = RecordsTimelineParser();
  const fixturePath = 'test/fixtures/timeline_android_export_anonymized.json';

  Future<List<NormalizedRecord>> parseJson(String json) => parser
      .parse(Stream.value(utf8.encode(json)), CancellationToken())
      .toList();

  Future<PreviewResult> previewJson(String json) =>
      parser.preview(Stream.value(utf8.encode(json)), CancellationToken());

  group('timeline_android_export_anonymized.json', () {
    test('parses visits, activities and timeline-only segments', () async {
      final records = await parser
          .parse(
            Stream.value(await File(fixturePath).readAsBytes()),
            CancellationToken(),
          )
          .toList();

      final visits = records.whereType<NormalizedVisit>().toList();
      final movements = records.whereType<NormalizedMovement>().toList();

      expect(visits, hasLength(2));
      expect(movements, hasLength(3));
      expect(records, hasLength(5));

      for (final visit in visits) {
        expect(visit.latLng.isValid, isTrue);
      }
      for (final movement in movements) {
        expect(movement.startLatLng, isNotNull);
        expect(movement.endLatLng, isNotNull);
      }
    });

    test('parses timeline-only segments as estimated movements', () async {
      final records = await parser
          .parse(
            Stream.value(await File(fixturePath).readAsBytes()),
            CancellationToken(),
          )
          .toList();

      final timelineMovement = records.whereType<NormalizedMovement>().first;
      expect(timelineMovement.distanceMethod, DistanceMethod.estimatedPath);
      expect(timelineMovement.distanceM, greaterThan(0));
      expect(timelineMovement.activityType, isNull);
      expect(timelineMovement.startLatLng!.latE7, 356663790);
      expect(timelineMovement.startLatLng!.lngE7, 1397583398);
    });

    test(
      'activity records keep start/end coordinate and recorded distance',
      () async {
        final records = await parser
            .parse(
              Stream.value(await File(fixturePath).readAsBytes()),
              CancellationToken(),
            )
            .toList();

        final vehicle = records.whereType<NormalizedMovement>().singleWhere(
          (m) => m.activityType == 'IN_VEHICLE',
        );

        expect(vehicle.distanceMethod, DistanceMethod.recorded);
        expect(vehicle.distanceM, 24507);
        expect(vehicle.startLatLng!.latE7, 356663790);
        expect(vehicle.startLatLng!.lngE7, 1397583398);
        expect(vehicle.startLatLng!.latE7, isNot(vehicle.endLatLng!.latE7));
      },
    );

    test(
      'activity without distanceMeters falls back to direct estimation',
      () async {
        final records = await parser
            .parse(
              Stream.value(await File(fixturePath).readAsBytes()),
              CancellationToken(),
            )
            .toList();

        final unknownActivity = records
            .whereType<NormalizedMovement>()
            .singleWhere((m) => m.activityType == 'UNKNOWN_ACTIVITY_TYPE');

        expect(unknownActivity.distanceMethod, DistanceMethod.estimatedDirect);
        expect(unknownActivity.distanceM, greaterThan(0));
        expect(unknownActivity.startLatLng, isNotNull);
        expect(unknownActivity.endLatLng, isNotNull);
      },
    );

    test(
      'visit placeLocation with degree latLng produces valid coordinates',
      () async {
        final records = await parser
            .parse(
              Stream.value(await File(fixturePath).readAsBytes()),
              CancellationToken(),
            )
            .toList();

        final parkVisit = records.whereType<NormalizedVisit>().singleWhere(
          (v) => v.latLng.latE7 == 356663790 && v.latLng.lngE7 == 1397583398,
        );

        expect(parkVisit.latLng.isValid, isTrue);
        expect(parkVisit.latLng.latE7, 356663790);
        expect(parkVisit.latLng.lngE7, 1397583398);
      },
    );

    test(
      'activity start/end coordinates win over a single-point timelinePath',
      () async {
        final records = await parseJson('''
        {
          "semanticSegments": [
            {
              "startTime": "2026-07-20T07:00:00+09:00",
              "endTime": "2026-07-20T08:00:00+09:00",
              "activity": {
                "start": {"latLng": "35.666379\\u00b0, 139.7583398\\u00b0"},
                "end": {"latLng": "35.697308\\u00b0, 139.786073\\u00b0"},
                "topCandidate": {"type": "WALKING", "probability": 0.7}
              },
              "timelinePath": [
                {
                  "point": "35.6700000\\u00b0, 139.7600000\\u00b0",
                  "time": "2026-07-20T07:30:00+09:00"
                }
              ]
            }
          ]
        }
        ''');

        final movement = records.single as NormalizedMovement;
        expect(movement.distanceMethod, DistanceMethod.estimatedDirect);
        expect(movement.distanceM, greaterThan(0));
        expect(movement.startLatLng!.latE7, 356663790);
        expect(movement.startLatLng!.lngE7, 1397583398);
        expect(movement.endLatLng!.latE7, 356973080);
        expect(movement.endLatLng!.lngE7, 1397860730);
        expect(movement.startLatLng, isNot(movement.endLatLng));
        expect(movement.path, hasLength(1));
      },
    );

    test(
      'out-of-range degree coordinates do not create visits or count',
      () async {
        const invalidLatLngs = <String>[
          '91.0, 139.7583398',
          '-91.0, 139.7583398',
          '35.666379, 181.0',
          '35.666379, -181.0',
          'NaN, 139.7583398',
          'Infinity, 139.7583398',
          '356663790, 1397583398',
        ];

        for (final latLng in invalidLatLngs) {
          final json =
              '''
          {
            "semanticSegments": [
              {
                "startTime": "2026-07-20T07:00:00+09:00",
                "endTime": "2026-07-20T08:00:00+09:00",
                "visit": {
                  "topCandidate": {
                    "placeLocation": {"latLng": "$latLng"}
                  }
                }
              }
            ]
          }
          ''';

          final records = await parseJson(json);
          final result = await previewJson(json);

          expect(records, isEmpty, reason: 'latLng: $latLng');
          expect(result.approxRecordCount, 0, reason: 'latLng: $latLng');
        }
      },
    );

    test(
      'single-point timelinePath never becomes a counted movement',
      () async {
        const json = '''
        {
          "semanticSegments": [
            {
              "startTime": "2026-07-20T07:00:00+09:00",
              "endTime": "2026-07-20T08:00:00+09:00",
              "timelinePath": [
                {
                  "point": "35.6899999\\u00b0, -117.6900000\\u00b0",
                  "time": "2026-07-20T07:30:00+09:00"
                }
              ]
            }
          ]
        }
        ''';

        final records = await parseJson(json);
        final preview = await previewJson(json);

        expect(records, isEmpty);
        expect(preview.approxRecordCount, 0);
        expect(preview.isOk, isTrue);
      },
    );

    test(
      'activity with out-of-range coordinates keeps no coordinate fields',
      () async {
        final records = await parseJson('''
        {
          "semanticSegments": [
            {
              "startTime": "2026-07-20T07:00:00+09:00",
              "endTime": "2026-07-20T08:00:00+09:00",
              "activity": {
                "start": {"latLng": "91.0\\u00b0, -170.0\\u00b0"},
                "end": {"latLng": "-93.0\\u00b0, 170.0\\u00b0"},
                "topCandidate": {"type": "WALKING", "probability": 0.7}
              }
            }
          ]
        }
        ''');

        final movement = records.single as NormalizedMovement;
        expect(movement.startLatLng, isNull);
        expect(movement.endLatLng, isNull);
        expect(movement.path, isEmpty);
        expect(movement.distanceMethod, DistanceMethod.unknown);
      },
    );

    test(
      'preview count and timelineMemory exclusion on the current fixture',
      () async {
        final bytes = await File(fixturePath).readAsBytes();
        final preview = await parser.preview(
          Stream.value(bytes),
          CancellationToken(),
        );
        final records = await parser
            .parse(Stream.value(bytes), CancellationToken())
            .toList();

        expect(preview.isOk, isTrue);
        expect(preview.approxRecordCount, 5);
        expect(records, hasLength(5));

        final sparsePath = records.where(
          (r) => r.startAtUtc == DateTime.utc(2026, 7, 19, 20),
        );
        final memorySegments = records.where(
          (r) => r.startAtUtc == DateTime.utc(2026, 7, 19, 21),
        );
        expect(sparsePath, isEmpty);
        expect(memorySegments, isEmpty);
      },
    );
  });
}
