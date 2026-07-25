#!/usr/bin/env bash
# 《宇宙傳奇 IV》macOS **完整版**打包(本機組,不上傳)。
#
# 為什麼是本機組而不是 CI 產:macOS 的 .app 只能在 macOS host build(codesign/hdiutil
# 只在 macOS 存在),但 CI 拿不到遊戲資源與 MT-32 ROM(兩者都不在公開 repo)。
# 所以流程是:CI 產「引擎 + 中文資料」的 .app → 本機把 game/ 與 ROM 注入進去。
#
# 用法:sq4_package_macos_full.sh <CI 下載的 patch tar.gz> [輸出目錄]
set -euo pipefail
SRC="${1:?用法: sq4_package_macos_full.sh <SQ4-CHT-patch-macos-universal.tar.gz> [輸出目錄]}"
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT="${2:-$ROOT/dist-all}"
source "$ROOT/tools/pkg_common.sh"

WORK="$(mktemp -d)"; trap 'rm -rf "$WORK"' EXIT
tar xzf "$SRC" -C "$WORK"
APP="$(find "$WORK" -maxdepth 2 -iname '*.app' -type d | head -1)"
[ -n "$APP" ] || { echo "!! 在 $SRC 裡找不到 .app" >&2; exit 1; }

# 1) 統一的 game/ 夾:遊戲資源 + 中文資料 + MT-32 ROM 全放同一層,
#    這樣 path 與 extrapath 指同一個地方就好。
GAME="$APP/Contents/Resources/game"
echo ">> 注入遊戲資料 → $GAME"
rm -rf "$GAME"; mkdir -p "$GAME"
cp -r "$ROOT/game/." "$GAME/"
rm -rf "$APP/Contents/Resources/cht-data"      # 已併進 game/,不需要重複一份

MT32LINE=""
if stage_mt32_rom "$GAME"; then
  MT32LINE="music_driver=mt32"
fi

# 2) 啟動包裝:CFBundleExecutable 仍叫 scummvm,把真正的執行檔改名成 scummvm.bin,
#    scummvm 換成 bash wrapper 產生 config 再啟動。
#    scummvm.bin 與 wrapper 同在 MacOS/,所以 @executable_path/../Frameworks 的
#    SDL2 rpath 仍然解析得到。
echo ">> 換成啟動 wrapper"
mv "$APP/Contents/MacOS/scummvm" "$APP/Contents/MacOS/scummvm.bin"
cat > "$APP/Contents/MacOS/scummvm" <<'WRAP'
#!/bin/bash
set -e
DIR="$(cd "$(dirname "$0")" && pwd)"
GAME="$DIR/../Resources/game"
CFGDIR="$HOME/Library/Application Support/sq4-cht-full"
CFG="$CFGDIR/scummvm.ini"
mkdir -p "$CFGDIR"
cat > "$CFG" <<CFGEOF
[scummvm]

[sq4-cht]
engineid=sci
gameid=sq4
description=Space Quest IV CHT (full)
path=$GAME
extrapath=$GAME
language=tw
subtitles=true
speech_mute=false
aspect_ratio=false
__MT32__
CFGEOF
exec "$DIR/scummvm.bin" --config="$CFG" sq4-cht "$@"
WRAP
if [ -n "$MT32LINE" ]; then
  sed -i.bak "s/^__MT32__$/$MT32LINE/" "$APP/Contents/MacOS/scummvm"
else
  sed -i.bak "/^__MT32__$/d" "$APP/Contents/MacOS/scummvm"
fi
rm -f "$APP/Contents/MacOS/scummvm.bak"
chmod +x "$APP/Contents/MacOS/scummvm"

# 3) 動過 .app 的內容,原本的 ad-hoc 簽章就失效了。
#    「未簽」比「壞簽」好——壞簽 macOS 會直接拒絕執行。附一個修復腳本讓使用者自己重簽。
echo ">> 移除失效簽章"
rm -rf "$APP/Contents/_CodeSignature"

mkdir -p "$OUT"
STAGE="$WORK/stage"; mkdir -p "$STAGE"
cp -R "$APP" "$STAGE/"
cat > "$STAGE/修復-macOS.command" <<'FIX'
#!/bin/bash
# 這個包是在 Linux 上組的,.app 的簽章已失效,而且會被 Gatekeeper 標記隔離。
# 在 Mac 上雙擊這個檔案跑一次即可(只需跑一次)。
cd "$(dirname "$0")"
xattr -cr ScummVM.app
codesign --force --deep --sign - ScummVM.app
echo "完成。現在可以打開 ScummVM.app 了。"
read -n 1 -s -r -p "按任意鍵關閉..."
FIX
chmod +x "$STAGE/修復-macOS.command"
cat > "$STAGE/讀我.txt" <<'TXT'
宇宙傳奇 IV — 時空穿越者　繁體中文化　macOS 完整版

遊戲、中文資料與 MT-32 ROM 都已內嵌，直接開 ScummVM.app 就能玩，不必自備遊戲。

第一次使用
----------
先雙擊「修復-macOS.command」跑一次。
這個包是在 Linux 上組的，.app 的簽章已失效、又會被 Gatekeeper 標記隔離，
那個腳本會清掉隔離屬性並重新做一次本機簽章。跑完再開 ScummVM.app。

這一版只給自己留存，不對外散布（內含遊戲本體與有版權的 MT-32 ROM）。
TXT

LABEL="SQ4-CHT-full-macos-universal"
tar czf "$OUT/${LABEL}.tar.gz" -C "$STAGE" .
echo ">> 完成: $OUT/${LABEL}.tar.gz ($(du -h "$OUT/${LABEL}.tar.gz" | cut -f1))"
echo ">> [注意] Linux 端無法 codesign 也無法實測 .app——請在 Mac 上跑一次"
echo "          「修復-macOS.command」再開 app 確認，別假設它一定會動。"
