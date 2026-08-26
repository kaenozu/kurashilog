import 'package:flutter_test/flutter_test.dart';
import 'package:kurashilog/domain/privacy/place_privacy.dart';
import 'package:kurashilog/domain/privacy/share_safe_report.dart';

void main() {
  test('share-safe report serializes only aggregate presentation fields', () {
    const report = ShareSafeReport(
      title: '今月の暮らし',
      periodLabel: '2026年8月',
      facts: <String, String>{'外出日数': '12日'},
      places: <PlaceShareProjection>[
        PlaceShareProjection(
          displayName: '非公開の場所',
          category: null,
          locationLabel: '位置情報は非公開',
        ),
      ],
      evidence: <ShareSafeEvidence>[
        ShareSafeEvidence(category: '地点の集計', truthClass: 'fact'),
      ],
    );

    final encoded = report.toJson().toString();

    expect(report.toJson(), containsPair('period', '2026年8月'));
    expect(encoded, contains('地点の集計'));
    expect(encoded, isNot(contains('cluster:private-source')));
    expect(encoded, isNot(contains('anonymous-stable-key')));
    expect(encoded, isNot(contains('356812345')));
    expect(encoded, isNot(contains('1397671234')));
    expect(encoded, isNot(contains('2026-08-23T12:34:56')));
  });

  test('share-safe evidence has no reference or detailed date fields', () {
    const evidence = ShareSafeEvidence(
      category: '指標の集計',
      truthClass: 'weakInference',
    );

    expect(evidence.toJson(), <String, Object?>{
      'category': '指標の集計',
      'truthClass': 'weakInference',
    });
  });
}
