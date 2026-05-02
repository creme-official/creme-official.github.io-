# CLAUDE.md — Creme合同会社 公式サイト

## リポジトリ概要

Creme合同会社（神奈川県大和市）の公式Webサイト兼会社案内ページ。  
GitHub Pages でホスティングされる静的サイトで、ファイルは `index.html` 一枚構成。

- **目的**: 会社案内（A4印刷対応）
- **言語**: 日本語
- **技術スタック**: 素のHTML5 + CSS（ビルドツール・フレームワーク・依存パッケージなし）

---

## ファイル構成

```
/
└── index.html   # サイト全体（HTML + CSS を一ファイルに内包）
```

外部ライブラリ・画像・フォント等は一切使用していない。  
将来ファイルを追加する場合はルート直下に置く。

---

## ページ構成

`index.html` は以下のセクションを上から順に持つ。

| セクション | クラス/要素 | 内容 |
|---|---|---|
| 社名見出し | `h1` | Creme合同会社 |
| PHILOSOPHY | `.philosophy-block` | 会社理念・ミッション文 |
| BUSINESS | `.section-block > .business-layout` | 3事業の説明（縦並び） |
| PERFORMANCE | `.section-block > .row` | 売上実績・目標（横並び2カラム） |
| COMPANY PROFILE | `.profile.section-block` | 会社概要（名称・住所・メール） |

---

## CSSアーキテクチャ

スタイルはすべて `<head>` 内の `<style>` タグに記述されている。

### 画面表示
- `body`: グレー背景 `#cccccc`、コンテンツを中央寄せ
- `.a4-container`: 幅 `210mm` 固定、内側余白 `20mm`、白背景 + ドロップシャドウ

### 印刷（`@media print`）
- `@page` ルール: 上下 `30mm`、左右 `20mm` のマージン（ブラウザ標準のヘッダー/フッター領域を確保）
- `.a4-container`: 内側余白を `0` にし、`@page` の外側余白だけで制御
- 背景色の印刷には `-webkit-print-color-adjust: exact; print-color-adjust: exact;` を使用

### 改ページ制御
改ページが起きてはいけないブロックには以下を付与している。

```css
page-break-inside: avoid;
break-inside: avoid;
```

見出し直後での改ページ禁止には `page-break-after: avoid;` を使用。

---

## 開発ワークフロー

### ローカルプレビュー
```bash
# Python が入っている場合
python3 -m http.server 8000
# → http://localhost:8000 で確認
```

ビルド手順・npm スクリプト等は存在しない。

### 印刷確認
ブラウザの印刷プレビュー（Ctrl+P / Cmd+P）でA4縦向きを選択し、  
ヘッダー/フッターの有無・各セクションの改ページ位置を必ず確認する。

### デプロイ
`main` ブランチへ push すると GitHub Pages が自動でデプロイする。  
追加の CI/CD 設定はない。

---

## コーディング規約

- **文字コード**: UTF-8（`<meta charset="UTF-8">`）
- **言語属性**: `<html lang="ja">`
- **フォント**: システムフォントスタック（Helvetica Neue → Hiragino → Meiryo）
- **単位**: 印刷要素は `mm` / `pt`、余白等は `mm`、フォントは `pt`
- **色**: テキスト `#333`、アクセント（見出し下線・section色）`#9f8a60`
- コメントは日本語で記述する
- `!important` は使用しない
- 外部リソース（CDN・外部フォント等）は導入しない

---

## 会社情報（コンテンツ更新時の参照用）

| 項目 | 値 |
|---|---|
| 会社名 | Creme合同会社 |
| 代表者 | 前田 みゆき |
| 所在地 | 〒242-0023 神奈川県大和市渋谷5-13-9 |
| メール | creme0106@gmail.com |
| 設立期 | 第1期〜（2025年度が第6期） |

数値（売上・目標・フォロワー数）を更新する際は `.performance-num` 要素内を直接編集する。

---

## Git ブランチ運用

| ブランチ | 役割 |
|---|---|
| `main` | 本番（GitHub Pages 配信元） |
| `claude/*` | AI による自動変更作業用 |

作業ブランチから `main` へのマージ前に、印刷プレビューで表示崩れがないことを確認すること。
