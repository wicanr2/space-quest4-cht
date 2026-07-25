#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_LOG_FONT=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 150 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/invlog.log 2>&1 &
sleep 8
for i in $(seq 1 12); do xdotool key --clearmodifiers Escape; sleep 2; done
echo "=== MARK-BEFORE-INVENTORY ===" >> /out/invlog.log
xdotool mousemove 512 150; sleep 2
xdotool mousemove 736 158 click 1; sleep 4
import -window root /out/shots/iv.png 2>/dev/null||true
pkill -f scummvm 2>/dev/null || true
sleep 1
