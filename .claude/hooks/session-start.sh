#!/bin/bash
# セッション開始時に走る。ビルド対象がない静的サイトなので依存インストールはせず、
# 「このリポジトリで何をどう確認すればいいか」をセッションの文脈に流し込むのが目的。
set -euo pipefail

cd "${CLAUDE_PROJECT_DIR:-.}"

# ヘッドレス Chromium（＝唯一の検証手段）の場所を特定してセッションに引き継ぐ
CHROME=""
for c in /opt/pw-browsers/chromium-*/chrome-linux/chrome \
         /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome \
         "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
  [ -x "$c" ] && CHROME="$c" && break
done
if [ -n "$CHROME" ] && [ -n "${CLAUDE_ENV_FILE:-}" ]; then
  echo "export CHROME_BIN=\"$CHROME\"" >> "$CLAUDE_ENV_FILE"
fi

chmod +x .claude/scripts/*.sh 2>/dev/null || true

PAGES=$(ls *.html 2>/dev/null | tr '\n' ' ')

cat <<EOF
このリポジトリはビルド工程もテストもない静的サイトです（GitHub Pages 直配信）。
ページ: ${PAGES:-なし}

- 各 HTML は CSS/JS インラインの単一ファイル完結。この構成を崩さないこと。
- 動作確認は \`.claude/scripts/check.sh [page.html]\` を実行し、
  \`.claude/tmp/\` に出力されるスクリーンショットを Read して目視すること。
  デスクトップとモバイルの両方が出力される。
- 詳細な規約・既知の制約は CLAUDE.md を参照。
$([ -n "$CHROME" ] && echo "- Chromium: $CHROME (CHROME_BIN に設定済み)" || echo "- ‼️ Chromium が見つかりません。描画確認ができない状態です。")
EOF
