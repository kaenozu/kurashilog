import 'dart:convert';

import 'package:crypto/crypto.dart';

/// レコード単位の安定キー生成（設計書 5.3 sourceKey 生成）。
///
/// ソース側に安定 ID がある場合はその ID とスキーマ種別をハッシュ化し、
/// 無い場合はレコード種別・開始/終了時刻・丸めた座標・主要属性から
/// SHA-256 相当の指紋を生成する。ファイル全体のハッシュだけでは
/// 差分ファイルを扱えないため、レコード単位のキーを必須とする。
class SourceKeyGenerator {
  const SourceKeyGenerator({required this.schemaType});

  final String schemaType;

  /// ソース側の安定 ID がある場合。
  String fromStableId({required String recordType, required String id}) {
    final input = <String>[schemaType, recordType, 'id', id].join('|');
    return _hash(input);
  }

  /// 安定 ID がない場合の指紋生成。
  String fingerprint({
    required String recordType,
    required DateTime startAtUtc,
    required DateTime endAtUtc,
    int? latE7,
    int? lngE7,
    String? normalizedActivity,
  }) {
    final input = <String>[
      schemaType,
      recordType,
      startAtUtc.millisecondsSinceEpoch.toString(),
      endAtUtc.millisecondsSinceEpoch.toString(),
      latE7 != null ? (latE7 ~/ 100).toString() : '',
      lngE7 != null ? (lngE7 ~/ 100).toString() : '',
      normalizedActivity ?? '',
    ].join('|');
    return _hash(input);
  }

  String _hash(String input) => sha256.convert(utf8.encode(input)).toString();
}
