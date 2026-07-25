#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 160 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/f8.log 2>&1 &
sleep 8
for i in $(seq 1 12); do xdotool key --clearmodifiers Escape; sleep 2; done
xdotool mousemove 512 150; sleep 2; xdotool mousemove 288 158 click 1; sleep 2
xdotool mousemove 400 400 click 1; sleep 4
import -window root /out/shots/f8_cht.png
xdotool key --clearmodifiers F8; sleep 3
import -window root /out/shots/f8_en.png
xdotool key --clearmodifiers F8; sleep 3
import -window root /out/shots/f8_back.png
pkill -f scummvm 2>/dev/null || true
sleep 1
