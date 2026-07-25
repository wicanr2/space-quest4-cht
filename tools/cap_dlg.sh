#!/bin/bash
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_LOG_FONT=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 200 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/dlg.log 2>&1 &
sleep 8
for i in $(seq 1 12); do xdotool key --clearmodifiers Escape; sleep 2; done
n=0
shot(){ import -window root /out/shots/dg_$(printf %02d $n).png 2>/dev/null||true; n=$((n+1)); }
# 圖示列在最上方:移到頂端讓它降下,點「眼睛」(第 2 個圖示)切成 look 模式
for icon in 288 352; do
  xdotool mousemove 512 150; sleep 2
  xdotool mousemove $icon 158 click 1; sleep 2
  shot
  # 用該動作點場景各處
  for xy in "400 400" "620 330" "300 330" "740 420" "500 480"; do
    set -- $xy
    xdotool mousemove $1 $2 click 1; sleep 3
    shot
    xdotool key --clearmodifiers Return; sleep 1
  done
done
pkill -f scummvm 2>/dev/null || true
sleep 1
