#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_LOG_GFX=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 90 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/title.log 2>&1 &
sleep 5
n=0
for i in $(seq 1 20); do
  import -window root /out/shots/ti_$(printf %02d $n).png 2>/dev/null||true; n=$((n+1))
  sleep 2
done
pkill -f scummvm 2>/dev/null || true
sleep 1
