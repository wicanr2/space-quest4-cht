#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 120 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/status.log 2>&1 &
sleep 8
for i in $(seq 1 12); do xdotool key --clearmodifiers Escape; sleep 2; done
# 滑鼠移到畫面中央下方,讓圖示列收回
xdotool mousemove 512 550; sleep 3
for s in 0 1 2 3; do
  import -window root /out/shots/st_$s.png 2>/dev/null || true
  sleep 3
done
pkill -f scummvm 2>/dev/null || true
sleep 1
