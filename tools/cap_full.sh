#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_CHT_DEBUG=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 280 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/full.log 2>&1 &
sleep 8
n=0
shot(){ import -window root /out/shots/fu_$(printf %02d $n).png 2>/dev/null||true; n=$((n+1)); }
for i in $(seq 1 14); do shot; xdotool key --clearmodifiers Escape; sleep 2; done
for icon in 288 352 416 480 544 608 672 736 800; do
  xdotool mousemove 512 150; sleep 2
  xdotool mousemove $icon 158 click 1; sleep 3; shot
  xdotool key --clearmodifiers Escape; sleep 2
done
xdotool mousemove 512 150; sleep 2; xdotool mousemove 288 158 click 1; sleep 2
for xy in "400 400" "620 330"; do
  set -- $xy
  xdotool mousemove $1 $2 click 1; sleep 3; shot
  xdotool key --clearmodifiers F8; sleep 2; shot
  xdotool key --clearmodifiers F8; sleep 2
  xdotool key --clearmodifiers Return; sleep 2
done
pkill -f scummvm 2>/dev/null || true
sleep 1
