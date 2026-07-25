#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 70 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/smoke.log 2>&1 &
sleep 6
for s in $(seq 0 14); do
  import -window root /out/shots/sm_$(printf %02d $s).png 2>/dev/null || true
  xdotool key --clearmodifiers Escape 2>/dev/null || true
  sleep 3
done
pkill -f scummvm 2>/dev/null || true
sleep 1
