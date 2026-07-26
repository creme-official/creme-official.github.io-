# Creme合同会社 サイト / 社内ツール

GitHub Pages で配信する**静的サイト**。ビルド工程・パッケージ管理・テストフレームワークは一切なし。
リポジトリ直下の `.html` をそのまま配信している。

## ファイル構成

すべて**単一ファイル完結**（CSS も JS もインライン、共有アセットなし）。ページ間で共有しているコードはない。

| ファイル | 役割 | 外部依存 |
|---|---|---|
| `index.html` | コーポレートサイト（Philosophy / Business / Company / Contact） | Google Fonts |
| `transcribe.html` | 動画・音声をブラウザ内で文字起こしするツール | jsDelivr の `@xenova/transformers@2.6.2` |
| `trend-research.html` | 美容コンテンツリサーチ用ダッシュボード（3タブ） | YouTube Data API v3 / Google News RSS + rss2json |

### index.html
- デザイントークンは `:root` の CSS 変数に集約: `--gold: #9f8a60`, `--gold-light`, `--gold-pale`, `--ink`, `--bg`。**色は直書きせず必ず変数を使う。**
- 書体は `--serif` (Cormorant Garamond) を欧文・装飾に、`--sans` (Zen Kaku Gothic New) を和文に。
- スクロール演出は `.fade-up` クラス + `IntersectionObserver`。新しいセクションを足したら `.fade-up` を付ける。
- `prefers-reduced-motion` 対応済み。アニメーションを追加する時はこのメディアクエリにも無効化を足すこと。
- ブレークポイントは **820px / 640px** の2つ。新規追加せずこれに合わせる。

### transcribe.html
- 完全クライアントサイド。サーバーもAPIキーも不要。
- 端末判定でモデルを切り替えている: モバイル `Xenova/whisper-tiny` / PC `Xenova/whisper-small`（`transcribe.html:316`）。モバイルでのメモリ不足を避けるための意図的な分岐なので、統一しないこと。
- `env.allowLocalModels = false`（モデルは CDN から取得）。
- ページ全体がドロップゾーン。ブラウザ既定の動画表示を抑止する処理が入っている。

### trend-research.html
- YouTube Data API のキーは**ユーザーが画面から入力し `localStorage` に保存**する方式。キーをコードに書かない・コミットしない。
- Google Trends は API を叩かず `trends.google.com/trends/explore` へのリンク遷移。
- 美容メディアは Google News RSS を `api.rss2json.com` 経由で取得（CORS 回避）。この経路は外部サービス依存なので、壊れた時はまず rss2json 側の応答を確認する。

## 変更時の約束ごと

- **単一 HTML ファイル完結を維持する。** ビルドツール、npm、フレームワーク、外部 CSS ファイルを導入しない。
- UI 文言は日本語。
- 会社情報（代表者名・所在地・メールアドレス）は実在情報。指示がない限り書き換えない。
- 新しい API キー・個人情報をハードコードしない。
- モバイル表示を必ず確認する。実利用の中心がスマホ。

## 動作確認

ビルドもテストもないので、**ヘッドレス Chromium で実際に描画して確認する**のが唯一の検証手段。

```bash
.claude/scripts/check.sh              # 全ページ
.claude/scripts/check.sh index.html   # 単体
```

ローカルサーバを立てて各ページを 1280x900 と 390x844（iPhone 相当）で描画し、

1. スクリーンショットを `.claude/tmp/` に保存
2. JS のコンソールエラーを検出
3. モバイル幅での横スクロール（要素のはみ出し）を実測で検出

**変更したら必ずスクリーンショットを Read して目視確認すること。**

> モバイル検証には `headless_shell` が必要。通常の Chrome の `--headless=new` は
> ウィンドウ幅を 500px 未満にできず、390px の検証結果が信用できない。
> スクリプトが自動で `headless_shell` を優先し、使えない場合ははみ出し検査をスキップして
> その旨を表示する。

手動で見たい場合:
```bash
python3 -m http.server 8000    # → http://127.0.0.1:8000/index.html
```

### 既知の制約
- リモート実行環境ではプロキシの都合で Google Fonts / jsDelivr への TLS 接続が失敗することがある。
  その場合スクショはフォールバックフォントで描画される（**レイアウト崩れではない**）。
  同じ理由で `transcribe.html` の実際の文字起こし動作はリモートでは検証できない。
- `trend-research.html` の YouTube タブは API キーが必要なため、リモートでは UI までしか検証できない。

## デプロイ

`main` への push で GitHub Pages が自動反映される（Actions ワークフローなし、ブランチ直配信）。

> ⚠️ リポジトリ名が `creme-official.github.io-` と**末尾にハイフンが付いている**。
> Organization ページ（`https://creme-official.github.io/`）として扱われるには
> リポジトリ名が正確に `creme-official.github.io` である必要があるため、現状は
> プロジェクトページ扱い（`https://creme-official.github.io/creme-official.github.io-/`）
> になっている可能性が高い。公開URLを扱う作業の前に実際の Pages 設定を確認すること。
