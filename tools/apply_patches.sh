#!/usr/bin/env bash
# 把《宇宙傳奇 IV》繁中化引擎改動套進一份乾淨(或既有)的 ScummVM source 樹。
#
# 用法:apply_patches.sh <scummvm-src-dir>
#   - 若 <scummvm-src-dir> 不存在:自動 clone 官方 scummvm/scummvm,
#     checkout patches/UPSTREAM_COMMIT.txt 記錄的 pinned commit。上游若已大幅 drift,
#     下方 patch 套用步驟會直接失敗並停止,不會默默套錯。
#   - 若 <scummvm-src-dir> 已存在(本機既有 checkout):直接對它套用,不會動 git 狀態。
set -euo pipefail
SRC="${1:?用法: apply_patches.sh <scummvm-src-dir>}"
HERE="$(cd "$(dirname "$0")/.." && pwd)"

if [ ! -d "$SRC" ]; then
  UPSTREAM="$(cat "$HERE/patches/UPSTREAM_COMMIT.txt")"
  echo ">> $SRC 不存在,clone 官方 ScummVM @ $UPSTREAM"
  # core.autocrlf=false:Windows(MSYS2)預設 autocrlf=true 會把 patch 轉 CRLF 導致套不上
  git clone --config core.autocrlf=false --config core.eol=lf https://github.com/scummvm/scummvm.git "$SRC"
  git -C "$SRC" fetch --depth 1 origin "$UPSTREAM" 2>/dev/null || git -C "$SRC" fetch origin
  git -C "$SRC" checkout -f "$UPSTREAM"
fi

# 新檔:GfxFontChinese —— Big5 繪字 + 24×24 hi-res + 狀態列 16×15 compact
cp "$HERE/patches/fontchinese.h"   "$SRC/engines/sci/graphics/fontchinese.h"
cp "$HERE/patches/fontchinese.cpp" "$SRC/engines/sci/graphics/fontchinese.cpp"

# 既有檔 diff:ZH_TWN 啟用、Big5 繪字、640×400 hi-res、kFormat 模板 + %s 參數、
# GetLongest Big5 斷行、空白正規化 key、Size() 量測譯文、SQ4 狀態列片段替換、
# pic 1 中文標題疊圖、SCI_DUMP_RES / SCI_DUMP_PIC / SCI_LOG_GFX / SCI_CHT_DEBUG
patch -p1 -d "$SRC" < "$HERE/patches/0001-sci-cht-zh_twn.patch"

cat <<'EOS'
>> 已套用。configure(docker 內;MT-32 必須啟用,不可帶 --disable-mt32emu):
   export CXXFLAGS="-fstack-protector-strong"
   ./configure --disable-all-engines --enable-engine=sci --disable-detection-full
   make -j$(nproc)
>> CXXFLAGS 的 -fstack-protector-strong 不要拿掉:issue #1(macOS 跑完片頭就 SIGABRT)
   是繪字路徑的堆疊溢位,clang 在 arm64 預設開才擋下來;Linux 沒開就靜靜跑過去。
>> Windows(mingw)交叉編譯要多一步:__stack_chk_fail 在 libssp,而 ScummVM 的連結行是
   $(LDFLAGS) ... $(OBJS) $(LIBS),放 LDFLAGS 會排在物件之前解析不到。configure 後補:
     echo "LIBS += $(x86_64-w64-mingw32-gcc -print-file-name=libssp.a)" >> config.mk
   要給**靜態封存檔的絕對路徑**,不能寫 -lssp —— 後者會連到 import lib,產生
   libssp-0.dll 執行期相依,而打包腳本不收那個 DLL,玩家一開就是 c0000135。
>> 驗證:grep USE_MT32EMU config.h 應為 #define
>> 啟用中文:target config 寫 language=tw(SCI1.1 走 config,不要用命令列 --language)
EOS
