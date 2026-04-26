---
globs: app/javascript/**/*.js, app/assets/stylesheets/**/*.css
---

## フロントエンド規約

### Stimulus コントローラ

- コントローラ名はケバブケース（例: `gift-records`, `delete-modal`）
- ファイル名は `<name>_controller.js` 形式
- `targets` / `values` は `static` で宣言する
- DOM 直接操作より `targets` を優先する

### API リクエスト

- fetch の際は `utils.js` の `getAPIHeaders()` を必ず使う（CSRF トークン含む）
- トースト通知は `utils.js` の `showToast(message, type)` を使う（type: `success` / `error` / `warning` / `info`）
- fetch は `async/await` + `try/catch/finally` パターンで書く

### Turbo

- ページ初期化処理は `utils.js` の `turboInit()` を使う（`DOMContentLoaded` と `turbo:load` の二重実行を防ぐ）
- Turbo Drive が有効なので `document.getElementById` を `connect()` 内で行う

### ユーティリティ

- 共通関数は `app/javascript/utils.js` に集約する
- デバウンスは `utils.js` の `debounce(fn, delay)` を使う
- HTML エスケープは `utils.js` の `escapeHtml()` を使う

### スタイル

- スタイルは Tailwind CSS クラスを優先する
- カスタム CSS が必要な場合は `app/assets/stylesheets/` に機能単位でファイルを分ける
- インラインスタイルは避ける（Tailwind で表現できない場合のみ許可）
