# くらしログ（仮称）

ユーザー自身が書き出した Google マップ タイムライン JSON を端末内で分析し、
生活の変化を見つける**オフライン** Flutter Android アプリ（MVP）。

> 位置履歴は外部へ送信されません。アプリは `INTERNET` 権限を持ちません。

## ドキュメント

- [MVP 要件定義・仕様書](docs/kurashilog_mvp_specification.txt)
- [MVP 基本設計・詳細設計書](docs/kurashilog_mvp_design.txt)
- 元ファイル: `docs/*.docx`

## 主な機能（MVP スコープ）

| 機能 | 内容 |
| --- | --- |
| インポート | SAF ファイル選択 / 共有受信、形式判定、差分・重複排除（sourceKey UNIQUE） |
| ホーム | 鮮度バッジ、今月カード 4 枚、インサイト最大 3 件 |
| カレンダー | 月表示の外出ヒートマップ、日タップで詳細へ |
| 月間ストーリー | 月選択、主要指標、最大移動日、新規地点、変化一覧 |
| 日別タイムライン | 時刻順の訪問・移動、滞在時間、推定距離、外部地図 |
| 頻出地点 | グリッドクラスタ（150m セル / 180m 統合）、ラベル編集、分析除外 |
| インサイト | 6 ルール（外出頻度・移動量・新規地点・訪問増加・帰宅時刻・活動半径） |
| 鮮度判定 | 欠落日数テーブル（高/中/低/かなり低い/履歴のみ）＋欠落率 20% で 1 段下げ |
| データ管理 | 全削除（オフライン・再起動後も復元されない） |

## 技術スタック

- Flutter / Material 3（暖色ニュートラル背景＋深緑アクセント、ダークモード対応）
- Riverpod（単方向データフロー）
- Drift + SQLite（トランザクション、型安全クエリ）
- 自作ストリーミング JSON トークナイザー（100MB 級ファイルでも全文 String 化しない）
- クラスタ計算は Isolate 実行

## 品質ゲート

```bash
dart format --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --release
```

リリースビルド後に最終 Manifest で `INTERNET` 権限が無いことを確認すること。

## ディレクトリ構成

```
lib/
  app/            # 起動、ルーティング、テーマ、DI
  features/       # onboarding / import_timeline / dashboard / calendar / day_detail / places / settings
  application/    # UseCase / Controller / State / Repository 抽象
  domain/         # モデル、集計・クラスタ・鮮度・インサイト規則（Flutter 非依存）
  infrastructure/ # Drift DB、パーサー、ファイルアクセス、プラットフォーム連携
  shared/         # ウィジェット
```

## 実装状況

- [x] P1 基盤（Theme・DB・DI・ルーティング）
- [x] P2 インポート（プレビュー・パーサー・検証・差分トランザクション）
- [x] P3 分析（クラスタ・日次/月次・鮮度・インサイト）
- [x] P4 UI（ホーム・カレンダー・日別・地点・設定）
- [~] P5 仕上げ（共有受信・外部地図・削除は実装済み。実機 E2E・性能確認は未実施）
- [ ] 実機エクスポート JSON サンプルでのスキーマ確定（設計書 P0、未取得）

> 注意: 対応 JSON 形式は Google マップ タイムラインの `Records.json`
> （`semanticSegments` 優先、旧 `locations`/`activitySegments` 対応）を想定して実装しています。
> 実機サンプル取得後にスキーマを確定し、パーサーテストを通す必要があります（設計書 11 リリース判定）。
