# CLAUDE.md

## 応答ルール
- 日本語で返信する
- コード変更は変更部分のみを説明・提示する

## プロジェクト概要
「思い出ギフト」の管理・共有 Web アプリ。Ruby on Rails 7.2 + PostgreSQL（pgvector）+ Redis + Sidekiq 構成。

## 開発コマンド
コマンドは必ず Docker コンテナ内で実行する（`docker compose exec web <command>`）。

```bash
# 開発環境起動
docker compose up --build

# テスト
docker compose exec web bundle exec rspec

# Lint
docker compose exec web bin/rubocop

# セキュリティスキャン
docker compose exec web bin/brakeman

# 全チェック一括（RuboCop + Brakeman + RSpec）
docker compose exec web bin/check

# JS ビルド
docker compose exec web yarn build

# CSS ビルド
docker compose exec web bin/rails tailwindcss:build
```

## 主要ファイル構成
| 場所 | 役割 |
|------|------|
| `app/models/` | ActiveRecord モデル |
| `app/controllers/` | コントローラ（admin/ サブディレクトリあり） |
| `app/services/` | ビジネスロジック（EmbeddingService, LineNotificationService 等） |
| `app/jobs/` | Sidekiq バックグラウンドジョブ |
| `app/javascript/controllers/` | Stimulus コントローラ |
| `spec/` | RSpec テスト（models/, requests/, system/, factories/） |

## テスト方針
- FactoryBot + Faker でテストデータを生成する
- 外部 API 呼び出しはモックを使う
- PR 前に `bundle exec rspec` がグリーンであること

## コミット形式
`feat:`, `fix:`, `style:`, `add:`, `update:` などのプレフィックスを付ける。

## ブランチ命名規則
`feat/`, `fix:` などのプレフィックスを付ける。

例: `feat/add-rag-feature`, `fix/ogp-url-error`
