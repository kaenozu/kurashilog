import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/models/distance_method.dart';
import 'package:kurashilog/domain/models/normalized_record.dart';
import 'package:kurashilog/infrastructure/parsers/records_parser.dart';
import 'package:kurashilog/infrastructure/parsers/timeline_parser.dart';

void main() {
  const parser = RecordsTimelineParser();
  const fixturePath = 'test/fixtures/timeline_android_export_anonymized.json';

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

    test('activity records keep start/end coordinate and recorded distance',
        () async {
      final records = await parser
          .parse(
            Stream.value(await File(fixturePath).readAsBytes()),
            CancellationToken(),
          )
          .toList();

      final vehicle = records
          .whereType<NormalizedMovement>()
          .singleWhere((m) => m.activityType == 'IN_VEHICLE');

      expect(vehicle.distanceMethod, DistanceMethod.recorded);
      expect(vehicle.distanceM, 24507);
      expect(vehicle.startLatLng!.latE7, 356663790);
      expect(vehicle.startLatLng!.lngE7, 1397583398);
      expect(vehicle.startLatLng!.latE7, isNot(vehicle.endLatLng!.latE7));
    });

    test('activity without distanceMeters falls back to direct estimation',
        () async {
      final records = await parser
          .parse(
            Stream.value(await File(fixturePath).readAsBytes()),
            CancellationToken(),
          )
          .toList();

      final unknownActivity = records
          .whereType<NormalizedMovement>()
          .singleWhere(
            (m) => m.activityType == 'UNKNOWN_ACTIVITY_TYPE',
          );

      expect(unknownActivity.distanceMethod, DistanceMethod.estimatedDirect);
      expect(unknownActivity.distanceM, greaterThan(0));
      expect(unknownActivity.startLatLng, isNotNull);
      expect(unknownActivity.endLatLng, isNotNull);
    });

    test('visit placeLocation with degree latLng produces valid coordinates',
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
    });
  });
}