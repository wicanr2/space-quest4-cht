#!/bin/bash
# 走開場 → 進遊戲 → 觸發旁白對白,沿路截圖
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_CHT_DEBUG=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 170 ./scummvm --config=/out/scummvm.ini sq4-cht >/out/play.log 2>&1 &
sleep 8
shot(){ import -window root /out/shots/pl_$(printf %02d $1).png 2>/dev/null || true; }
n=0
# 前段:跳過開場動畫
for i in $(seq 1 12); do shot $n; n=$((n+1)); xdotool key --clearmodifiers Escape; sleep 2; done
# 進遊戲後:點擊場景各處觸發「看」的旁白
for xy in "500 400" "300 350" "700 380" "420 300" "600 300" "350 450" "550 450" "250 300"; do
  set -- $xy
  xdotool mousemove $1 $2 click 1; sleep 2; shot $n; n=$((n+1))
  xdotool key --clearmodifiers Escape; sleep 1
done
# 右鍵切換動作 → 再點
for i in 1 2 3; do
  xdotool mousemove 500 400 click 3; sleep 1
  xdotool mousemove 480 380 click 1; sleep 2; shot $n; n=$((n+1))
  xdotool key --clearmodifiers Escape; sleep 1
done
pkill -f scummvm 2>/dev/null || true
sleep 1
