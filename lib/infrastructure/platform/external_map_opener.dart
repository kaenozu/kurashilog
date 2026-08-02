import 'package:url_launcher/url_launcher.dart';

import '../../domain/models/lat_lng.dart';

/// 外部地図アプリへの遷移（設計書 FR-100 / PR-06）。
///
/// geo: インテントで端末の地図アプリへ座標を渡す。有料 API や
/// アプリ内地図タイルは使わない。地図アプリが無い場合は失敗を返し、
/// UI 側で座標のみ表示する（MAP-001）。
class ExternalMapOpener {
  const ExternalMapOpener();

  Future<bool> open(LatLngE7 coord, {String? label}) async {
    final lat = coord.lat.toStringAsFixed(6);
    final lng = coord.lng.toStringAsFixed(6);
    final query = label == null ? '$lat,$lng' : '$lat,$lng($label)';
    final uri = Uri.parse('geo:$lat,$lng?q=${Uri.encodeComponent(query)}');
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}
