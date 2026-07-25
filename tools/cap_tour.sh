#!/bin/bash
# 走過開場後的幾個場景,盡量多收不同畫面的中文旁白
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
TGT="${1:-sq4-cht}"; PFX="${2:-tr}"
timeout 280 ./scummvm --config=/out/scummvm.ini "$TGT" >/out/tour_$PFX.log 2>&1 &
sleep 6
n=0
shot(){ import -window root /out/shots/${PFX}_$(printf %02d $n).png 2>/dev/null||true; n=$((n+1)); }
for i in $(seq 1 12); do xdotool key --clearmodifiers Escape; sleep 2; done
for i in 1 2 3 4; do xdotool key --clearmodifiers Return; sleep 2; done
shot
# 往左跑穿過幾個街道畫面
for i in 1 2 3 4 5; do
  xdotool mousemove 210 470 click 1; sleep 7; shot
done
# 換成「觀看」點場景各處
xdotool mousemove 512 190; sleep 2; xdotool mousemove 288 200 click 1; sleep 2
for xy in "400 380" "700 330" "260 300" "560 460"; do
  set -- $xy
  xdotool mousemove $1 $2 click 1; sleep 4; shot
  xdotool key --clearmodifiers Return; sleep 2
done
# 往右跑
for i in 1 2 3; do
  xdotool mousemove 800 470 click 1; sleep 7; shot
done
xdotool mousemove 512 190; sleep 2; xdotool mousemove 288 200 click 1; sleep 2
for xy in "450 350" "650 400"; do
  set -- $xy
  xdotool mousemove $1 $2 click 1; sleep 4; shot
  xdotool key --clearmodifiers Return; sleep 2
done
pkill -f scummvm 2>/dev/null || true
sleep 1
