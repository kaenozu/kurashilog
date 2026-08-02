# テストフィクスチャ: timeline_records_anonymized.json

Google マップ タイムラインの手動エクスポート `Records.json`（Takeout 形式）を
想定した**匿名化テストデータ**です。

## 注意

- このフィクスチャに含まれる値は**すべて架空**です。
- 実機エクスポートの実データに由来する値は含まれていません（実データは未取得のため）。
- 緯度経度・日時・placeId は、実在する地点・個人・日時を推測できない合成値です
  （例: `35.123456,139.654321`、`ANON-PLACE-001`、`2026-07-01T00:00:00Z`）。
- 構造は Takeout の公開・既知スキーマ仕様と、リポジトリの実装・既存テストが
  想定する構造に基づいて構築しています。

## 構造サマリ

トップレベルキー: `semanticSegments` / `locations` / `activitySegments` / `unknownTopLevelKey`

### semanticSegments（8 要素）

- visit 相当 6 件:
  - 1・2 件目: 同一 placeId（`ANON-PLACE-001`）の別日時訪問、`placeLocation` は
    文字列形式（`geo:35.123456,139.654321`）
  - 3 件目: placeId 欠落（`semanticType: WORK` のみ）
  - 4 件目: placeLocation 欠落（`topCandidate.location` の
    `latitudeE7`/`longitudeE7` オブジェクトで座標を代替）
  - 5 件目: `placeLocation` が `latE7`/`lngE7` オブジェクト形式、未知フィールド
    （`confidence` / `otherAttributes`）を含む
  - 6 件目: 座標情報なし（`placeId` のみ、`timelinePath: []`）のため、
    パーサーによりスキップされる
- activity 相当 2 件: `start`（`WALKING` / `IN_VEHICLE`）、`distanceMeters`、
  `timelinePath`（`point: "geo:..."` 3 点）付き。2 件目は未知フィールド
  （`calories` / `otherAttributes`）を含む
- 日時形式: RFC3339 UTC（例: `2026-07-01T00:00:00Z`）

### locations（2 点・旧形式）

`timestampMs`（文字列のミリ秒）/ `latitudeE7` / `longitudeE7` / `accuracy`。
2 点は近接しているため、パーサーの旧形式滞留検出により訪問 1 件が導出される。

### activitySegments（1 件・旧形式）

`startTime` / `endTime` / `activityType` / `distance`。

### その他

- `unknownTopLevelKey: null`: 未知トップレベルキー + null 値の許容確認用
