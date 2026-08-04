import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/distance_method.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  const parser = RecordsTimelineParser();
  const fixturePath = 'test/fixtures/timeline_records_anonymized.json';

  Future<List<NormalizedRecord>> parseBytes(List<int> bytes) =>
      parser.parse(Stream.value(bytes), CancellationToken()).toList();

  Future<List<NormalizedRecord>> parseFixture() async =>
      parseBytes(await File(fixturePath).readAsBytes());

  Future<PreviewResult> preview(String json) =>
      parser.preview(Stream.value(utf8.encode(json)), CancellationToken());

  group('timeline_records_anonymized.json', () {
    test(
      'parses without throwing and yields the expected record counts',
      () async {
        final records = await parseFixture();
        final visits = records.whereType<NormalizedVisit>().toList();
        final movements = records.whereType<NormalizedMovement>().toList();

        expect(records, hasLength(9));
        expect(visits, hasLength(6));
        expect(movements, hasLength(3));
      },
    );

    test('separates NormalizedVisit and NormalizedMovement', () async {
      final records = await parseFixture();
      final visits = records.whereType<NormalizedVisit>().toList();
      final movements = records.whereType<NormalizedMovement>().toList();

      for (final visit in visits) {
        expect(visit.latLng.isValid, isTrue);
      }
      for (final movement in movements) {
        expect(movement.distanceMethod, DistanceMethod.recorded);
        expect(movement.distanceM, isNotNull);
        expect(movement.distanceM, greaterThan(0));
        expect(movement.activityType, isNotNull);
      }
      for (final movement in movements.where(
        (m) =>
            m.startAtUtc == DateTime.utc(2026, 7, 7, 2) ||
            m.startAtUtc == DateTime.utc(2026, 7, 8, 2),
      )) {
        expect(movement.startLatLng, isNotNull);
        expect(movement.endLatLng, isNotNull);
      }
    });

    test('keeps startTime as UTC DateTime', () async {
      final records = await parseFixture();
      final homeVisits = records
          .whereType<NormalizedVisit>()
          .where((v) => v.latLng.latE7 == 351234560)
          .toList();

      expect(homeVisits, hasLength(2));
      expect(homeVisits[0].startAtUtc, DateTime.utc(2026, 7, 1));
      expect(homeVisits[0].startAtUtc.isUtc, isTrue);
      expect(homeVisits[0].endAtUtc, DateTime.utc(2026, 7, 1, 1));
      expect(homeVisits[0].endAtUtc.isUtc, isTrue);
    });

    test('preview count equals the number of parseable records', () async {
      final preview = await parser.preview(
        Stream.value(await File(fixturePath).readAsBytes()),
        CancellationToken(),
      );
      final records = await parseFixture();

      expect(preview.isOk, isTrue);
      expect(preview.approxRecordCount, records.length);
    });

    test('produces a stable and deterministic sourceKey set', () async {
      final bytes = await File(fixturePath).readAsBytes();
      final first = await parseBytes(bytes);
      final second = await parseBytes(bytes);

      final firstKeys = first.map((record) => record.sourceKey).toList();
      final secondKeys = second.map((record) => record.sourceKey).toList();

      expect(secondKeys.toSet(), firstKeys.toSet());
      expect(secondKeys, firstKeys);
    });

    test(
      'visits to the same placeId at different times have distinct keys',
      () async {
        final records = await parseFixture();
        final homeVisits = records
            .whereType<NormalizedVisit>()
            .where((v) => v.latLng.latE7 == 351234560)
            .toList();

        expect(homeVisits, hasLength(2));
        expect(homeVisits[0].sourceKey, isNot(homeVisits[1].sourceKey));
      },
    );

    test('ignores unknown fields and still parses the records', () async {
      final records = await parseFixture();

      final visitWithUnknownFields = records
          .whereType<NormalizedVisit>()
          .singleWhere((v) => v.startAtUtc == DateTime.utc(2026, 7, 5, 2));
      expect(visitWithUnknownFields.sourceLabel, 'GROCERY');
      expect(visitWithUnknownFields.latLng.isValid, isTrue);

      final movementWithUnknownFields = records
          .whereType<NormalizedMovement>()
          .singleWhere((m) => m.startAtUtc == DateTime.utc(2026, 7, 8, 2));
      expect(movementWithUnknownFields.distanceM, greaterThan(0));
    });

    test('missing optional fields are not treated as failures', () async {
      final records = await parseFixture();

      final visitWithoutPlaceId = records
          .whereType<NormalizedVisit>()
          .singleWhere((v) => v.startAtUtc == DateTime.utc(2026, 7, 3, 2));
      expect(visitWithoutPlaceId.sourceLabel, 'WORK');
      expect(visitWithoutPlaceId.latLng.isValid, isTrue);

      final visitWithoutPlaceLocation = records
          .whereType<NormalizedVisit>()
          .singleWhere((v) => v.startAtUtc == DateTime.utc(2026, 7, 4, 2));
      expect(visitWithoutPlaceLocation.latLng.latE7, 352345670);
      expect(visitWithoutPlaceLocation.latLng.lngE7, 1397654320);
    });

    test('empty arrays and null values are accepted', () async {
      final records = await parseFixture();
      final visits = records.whereType<NormalizedVisit>().toList();
      final movements = records.whereType<NormalizedMovement>().toList();

      expect(records, hasLength(9));
      expect(visits, hasLength(6));
      expect(movements, hasLength(3));
      expect(
        visits.any((v) => v.startAtUtc == DateTime.utc(2026, 7, 6, 2)),
        isFalse,
      );
    });

    test(
      'uses activity.start and distanceMeters from current Takeout',
      () async {
        final records = await parseFixture();
        final movements = records.whereType<NormalizedMovement>().toList();

        final walking = movements.singleWhere(
          (m) => m.startAtUtc == DateTime.utc(2026, 7, 7, 2),
        );
        expect(walking.activityType, 'WALKING');
        expect(walking.distanceM, 1520);
        expect(walking.distanceMethod, DistanceMethod.recorded);

        final vehicle = movements.singleWhere(
          (m) => m.startAtUtc == DateTime.utc(2026, 7, 8, 2),
        );
        expect(vehicle.activityType, 'IN_VEHICLE');
        expect(vehicle.distanceM, 9000);
        expect(vehicle.distanceMethod, DistanceMethod.recorded);
      },
    );

    test('derives movement from legacy activitySegments entries', () async {
      final records = await parseFixture();
      final legacyMovement = records
          .whereType<NormalizedMovement>()
          .singleWhere((m) => m.startAtUtc == DateTime.utc(2026, 7, 1, 5));

      expect(legacyMovement.activityType, 'WALKING');
      expect(legacyMovement.distanceM, 800);
      expect(legacyMovement.distanceMethod, DistanceMethod.recorded);
      expect(legacyMovement.endAtUtc, DateTime.utc(2026, 7, 1, 5, 30));
    });

    test('does not treat a timestamp-like activity.start as a type', () async {
      final bytes = utf8.encode('''
      {
        "semanticSegments": [
          {
            "startTime": "2026-07-09T02:00:00Z",
            "endTime": "2026-07-09T03:00:00Z",
            "activity": {
              "start": "2026-07-09T02:00:00Z",
              "topCandidate": {"type": "CYCLING"},
              "distanceMeters": 2000.0
            }
          }
        ],
        "locations": [],
        "activitySegments": []
      }
      ''');
      final records = await parseBytes(bytes);

      final movement = records.single as NormalizedMovement;
      expect(movement.activityType, 'CYCLING');
      expect(movement.distanceM, 2000);
      expect(movement.distanceMethod, DistanceMethod.recorded);
    });

    test(
      'derives a visit from legacy locations and tolerates legacy activitySegments',
      () async {
        final records = await parseFixture();
        final legacyVisit = records.whereType<NormalizedVisit>().singleWhere(
          (v) => v.startAtUtc == DateTime.utc(2026, 7, 1, 4),
        );

        expect(legacyVisit.endAtUtc, DateTime.utc(2026, 7, 1, 4, 30));
        expect(legacyVisit.latLng.latE7, 351235080);
        expect(legacyVisit.latLng.lngE7, 1396543605);
      },
    );
  });

  group('malformed JSON', () {
    const malformedCases = <String, String>{
      'truncated document':
          '{"semanticSegments":[{"startTime":"2026-07-01T00:00:00Z"',
      'missing closing bracket': '{"semanticSegments":[',
      'trailing JSON after root value': '{} {"semanticSegments":[]}',
      'empty file': '',
    };

    for (final entry in malformedCases.entries) {
      test('preview rejects ${entry.key}', () async {
        final previewResult = await preview(entry.value);
        expect(previewResult.isOk, isFalse);
        expect(previewResult.errorCode, 'IMP-003');
      });
    }

    test('parse surfaces malformed input as ImportParseException', () async {
      await expectLater(
        parseBytes(utf8.encode('{"semanticSegments":[')),
        throwsA(isA<ImportParseException>()),
      );
    });
  });
}
