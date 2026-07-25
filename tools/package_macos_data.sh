#!/usr/bin/env bash
# 把 macOS CI(.github/workflows/build-macos.yml)產出的「空引擎」ScummVM.app,
# 注入《宇宙傳奇 IV》繁中資料(dist-cht/ 全部檔案)+ README,重新打包成可交付檔。
# 在 CI runner 內跑(bash 內建即可,不需 docker/python)。
#
# 用法:tools/package_macos_data.sh <engine.tar.gz 或 .app 路徑> <輸出目錄>
#
# 交付原則(硬):.app 本身只含 patched 引擎;中文資料放進
# .app/Contents/Resources/cht-data/,原遊戲資源與 MT-32 ROM 絕不塞入。
#
# [雷] 注入清單要含 dist-cht/ 的「全部」檔案——只複製 translation.tsv + *.fnt 會漏掉
#      sq4_title.ovl(中文標題疊圖)與 view.947(中文化的暫停面板),macOS 版就會少那兩塊中文。
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
SRC="${1:?用法: package_macos_data.sh <engine.tar.gz|.app> <輸出目錄>}"
OUT="${2:?需指定輸出目錄}"

WORK="$(mktemp -d)"
trap 'rm -rf "$WORK"' EXIT

if [ -d "$SRC" ] && [[ "$SRC" == *.app ]]; then
  cp -R "$SRC" "$WORK/ScummVM.app"
else
  tar xzf "$SRC" -C "$WORK"
fi
APP="$(find "$WORK" -maxdepth 2 -iname '*.app' -type d | head -1)"
[ -n "$APP" ] || { echo "!! 在 $SRC 裡找不到 .app" >&2; exit 1; }

CHT_DIR="$APP/Contents/Resources/cht-data"
echo ">> 注入中文資料 → $CHT_DIR"
rm -rf "$CHT_DIR"; mkdir -p "$CHT_DIR"
[ -f "$ROOT/dist-cht/translation.tsv" ] || { echo "!! 找不到 $ROOT/dist-cht/translation.tsv" >&2; exit 1; }
cp "$ROOT"/dist-cht/* "$CHT_DIR/"
echo ">>    staged $(ls "$CHT_DIR" | wc -l) 個中文資料檔:$(ls "$CHT_DIR" | tr '\n' ' ')"
for f in translation.tsv sq4_big5.fnt sq4_big5_hi.fnt sq4_title.ovl view.947; do
  [ -f "$CHT_DIR/$f" ] || { echo "!! 少了 $f" >&2; exit 2; }
done

cat > "$APP/Contents/Resources/README-cht.txt" <<'EOF'
宇宙傳奇 IV — 時空穿越者（Space Quest IV: Roger Wilco and the Time Rippers）繁體中文化 — macOS 版

本包內容
--------
- patched ScummVM 執行檔（Big5 繪字、ZH_TWN、640x400 高解析中文對白、中文標題疊圖、
  中文化的暫停面板）
- cht-data/：中文資料
    translation.tsv   對白/旁白/UI 譯文（Big5）
    sq4_big5.fnt      16x15 倚天字型（狀態列與固定高度小框用）
    sq4_big5_hi.fnt   24x24 倚天字型（對白用，直接畫進高解析緩衝區）
    sq4_title.ovl     標題畫面的中文副標疊圖
    view.947          中文化的暫停面板美術字
- 本說明檔

本包【不含】原遊戲資源，也不含 Roland MT-32 ROM（版權因素不隨包分發）。
請自備合法取得的 Space Quest IV CD 版（resource.000 / resource.aud / resource.map）。

安裝步驟
--------
1. 準備好你自己的遊戲資料夾。
2. 把 cht-data/ 內的所有檔案，複製進上述遊戲資料夾（與 resource.000 同一層）。
3. 把 ScummVM.app 拖進「應用程式」，第一次執行前先解除 Gatekeeper 隔離（未簽署 app）：
     xattr -dr com.apple.quarantine /Applications/ScummVM.app
4. 開啟 ScummVM.app，按「Add Game...」選那個遊戲資料夾。
5. 在該遊戲的 Game Options 把 Language 設成 Chinese (Taiwan)。

   ※ 一定要用 Game Options 設定，不要用命令列的 --language=tw。
     SCI1.1 的偵測器在偵測階段就會用語言過濾條目，命令列帶語言反而會讓遊戲認不出來。

語音與字幕
--------
CD 版有全套英文語音。中文化保留原配音，字幕顯示繁中；請在 Game Options 的 Audio 分頁
確認同時開啟語音與字幕（Speech + Subtitles）。

MT-32 音效
--------
本 build 已編入 MT-32 模擬（Munt），但 ROM 有版權不隨包分發，預設仍是 AdLib。
自備 MT32_CONTROL.ROM + MT32_PCM.ROM 放進遊戲資料夾後，於音效選項選 Roland MT-32 即可。

交付原則
--------
中文化僅以 ScummVM patch 形式交付（引擎改動 + 中文資料），原遊戲資源與 ROM 不入包、不散布。
repo：https://github.com/wicanr2/space-quest4-cht
EOF

# 重簽:Resources 內容變動後,build 期的 ad-hoc 簽章要重蓋(--deep 涵蓋巢狀 dylib)
if command -v codesign >/dev/null 2>&1; then
  codesign --force --deep --sign - "$APP" 2>/dev/null || echo "!! codesign 失敗(非 macOS host 屬預期)"
fi

mkdir -p "$OUT"
LABEL="SQ4-CHT-patch-macos-universal"
tar czf "$OUT/${LABEL}.tar.gz" -C "$(dirname "$APP")" "$(basename "$APP")"
echo ">> -> $OUT/${LABEL}.tar.gz"

if command -v hdiutil >/dev/null 2>&1; then
  hdiutil create -volname "$LABEL" -srcfolder "$APP" -ov -format UDZO "$OUT/${LABEL}.dmg"
  echo ">> -> $OUT/${LABEL}.dmg"
else
  echo ">> (非 macOS host,略過 .dmg——hdiutil 只在 macOS 存在)"
fi

ls -la "$OUT"
