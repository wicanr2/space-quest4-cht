#!/bin/bash
# 用 SCI_CHT_DEBUG 記錄所有查表 MISS 的 runtime 字串 → 找出動態組字/漏抽的文字
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_CHT_DEBUG=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 90 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/miss.log 2>&1 &
sleep 8
for s in $(seq 0 20); do
  import -window root /out/shots/ms_$(printf %02d $s).png 2>/dev/null || true
  xdotool key --clearmodifiers Escape 2>/dev/null || true
  xdotool key --clearmodifiers Return 2>/dev/null || true
  sleep 3
done
pkill -f scummvm 2>/dev/null || true
sleep 1
