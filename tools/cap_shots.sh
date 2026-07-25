#!/bin/bash
# README 用的成品截圖:標題 → 開場詢問 → 開場旁白 → 場景對白 → 暫停面板
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 260 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/shots.log 2>&1 &
sleep 5
n=0
shot(){ import -window root /out/shots/sh_$(printf %02d $n).png 2>/dev/null||true; n=$((n+1)); }
# 開場:Sierra logo → 標題 → 詢問是否跳過
for i in $(seq 1 10); do shot; sleep 2; done
for i in $(seq 1 10); do xdotool key --clearmodifiers Escape; sleep 2; shot; done
# 進遊戲:走位躲開續集警察,收旁白
xdotool mousemove 220 470 click 1; sleep 5; shot
for i in 1 2 3; do xdotool key --clearmodifiers Return; sleep 3; shot; done
# 觀看模式點場景
xdotool mousemove 512 190; sleep 2; xdotool mousemove 288 200 click 1; sleep 2
for xy in "400 380" "620 300"; do
  set -- $xy
  xdotool mousemove $1 $2 click 1; sleep 4; shot
  xdotool key --clearmodifiers Return; sleep 2
done
# 暫停面板
xdotool mousemove 512 190; sleep 2; xdotool mousemove 736 200 click 1; sleep 4; shot
pkill -f scummvm 2>/dev/null || true
sleep 1
