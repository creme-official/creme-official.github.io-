#!/bin/bash
# 静的ページをヘッドレス Chromium で実際に描画して確認する。
#   - デスクトップ(1280x900) / モバイル(390x844) のスクリーンショット
#   - JS コンソールエラーの検出
#   - モバイル幅での横スクロール（はみ出し）検出
# 使い方: .claude/scripts/check.sh [page.html ...]   (省略時は全 .html)
set -uo pipefail

cd "${CLAUDE_PROJECT_DIR:-$(git rev-parse --show-toplevel)}"

OUT=".claude/tmp"
rm -rf "$OUT" && mkdir -p "$OUT"

# --- Chromium を探す ---------------------------------------------------------
# headless_shell を優先する。通常の chrome の --headless=new はウィンドウ幅を
# 500px 未満に縮められず、390px のモバイル検証が正しく行えないため。
CHROME="" ; HEADLESS_FLAG="--headless=new"
for c in "${CHROME_BIN:-}" \
         /opt/pw-browsers/chromium_headless_shell-*/chrome-linux/headless_shell \
         /opt/pw-browsers/chromium-*/chrome-linux/chrome \
         /usr/bin/chromium /usr/bin/chromium-browser /usr/bin/google-chrome \
         "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"; do
  [ -n "$c" ] && [ -x "$c" ] && CHROME="$c" && break
done
if [ -z "$CHROME" ]; then
  echo "‼️  Chromium が見つかりません。CHROME_BIN に実行ファイルのパスを指定してください。" >&2
  exit 1
fi
case "$CHROME" in *headless_shell) HEADLESS_FLAG="--headless" ;; esac

# --- ローカルサーバ（空きポートを自動選択） ----------------------------------
PORT=$(python3 -c 'import socket;s=socket.socket();s.bind(("127.0.0.1",0));print(s.getsockname()[1]);s.close()')
python3 -m http.server "$PORT" --bind 127.0.0.1 >/dev/null 2>&1 &
SERVER_PID=$!
trap 'kill "$SERVER_PID" 2>/dev/null' EXIT
for _ in $(seq 1 30); do
  curl -s -o /dev/null "http://127.0.0.1:$PORT/" && break
  sleep 0.2
done

PAGES=("$@")
if [ ${#PAGES[@]} -eq 0 ]; then mapfile -t PAGES < <(ls *.html 2>/dev/null); fi
if [ ${#PAGES[@]} -eq 0 ]; then echo "‼️  対象の .html がありません" >&2; exit 1; fi

FAILED=0
run() { "$CHROME" $HEADLESS_FLAG --no-sandbox --disable-gpu --hide-scrollbars "$@"; }

shoot() { # $1=page $2=label $3=W,H
  local page="$1" label="$2" size="$3"
  local base="$OUT/${page%.html}-${label}"

  run --window-size="$size" --virtual-time-budget=6000 --enable-logging=stderr --v=0 \
      --screenshot="$base.png" "http://127.0.0.1:$PORT/$page" >"$base.log" 2>&1

  if [ ! -s "$base.png" ]; then
    echo "‼️  $page ($label): 描画に失敗"; sed -n '1,20p' "$base.log"; FAILED=1; return
  fi

  # ページ自身の JS エラーのみ拾う（プロキシ由来の TLS ノイズは除外）
  local errs
  errs=$(grep -E 'CONSOLE\(|CONSOLE:|Uncaught|SyntaxError|ReferenceError|TypeError' "$base.log" \
         | grep -v 'ssl_client_socket' | head -10)
  if [ -n "$errs" ]; then
    echo "⚠️  $page ($label): コンソールエラーあり"
    echo "$errs" | sed 's/^/     /'
    FAILED=1
  else
    echo "✅ $page ($label) → $base.png"
  fi
}

overflow() { # $1=page — モバイル幅で横にはみ出す要素がないか実測する
  local page="$1" probe="$OUT/_probe-$page"
  cat "$page" > "$probe"
  cat >> "$probe" <<'PROBE'
<script>
setTimeout(() => {
  const w = innerWidth;
  const bad = [...document.querySelectorAll('body *')]
    .filter(e => e.getBoundingClientRect().right > w + 1)
    .slice(0, 5)
    .map(e => e.tagName.toLowerCase() + (e.className ? '.' + String(e.className).split(' ')[0] : ''));
  document.title = `VP=${w} SCROLL=${document.documentElement.scrollWidth} ${bad.join(',')}`;
}, 3000);
</script>
PROBE
  local t
  t=$(run --window-size=390,844 --virtual-time-budget=6000 \
          --dump-dom "http://127.0.0.1:$PORT/$probe" 2>/dev/null \
      | grep -o '<title>[^<]*</title>' | sed 's/<[^>]*>//g')
  rm -f "$probe"

  local vp scroll
  vp=$(sed -n 's/.*VP=\([0-9]*\).*/\1/p' <<<"$t")
  scroll=$(sed -n 's/.*SCROLL=\([0-9]*\).*/\1/p' <<<"$t")
  if [ -z "$vp" ]; then echo "   （はみ出し検査スキップ: 計測不能）"; return; fi
  if [ "$vp" -gt 400 ]; then
    echo "   （はみ出し検査スキップ: ビューポートが ${vp}px に丸められた。headless_shell が必要）"
  elif [ "${scroll:-0}" -gt "$vp" ]; then
    echo "‼️  $page: モバイル幅で横にはみ出している (viewport=${vp} scrollWidth=${scroll}) → ${t#* }"
    FAILED=1
  else
    echo "✅ $page: モバイル幅の横はみ出しなし (viewport=${vp} scrollWidth=${scroll})"
  fi
}

for page in "${PAGES[@]}"; do
  if [ ! -f "$page" ]; then echo "‼️  $page が見つかりません"; FAILED=1; continue; fi
  shoot "$page" desktop 1280,900
  shoot "$page" mobile  390,844
  overflow "$page"
done

echo
echo "スクリーンショット: $OUT/  ← Read して目視確認すること"
exit $FAILED
