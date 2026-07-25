export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 120 ./scummvm --path=/game --auto-detect --language=tw >/out/probe.log 2>&1 &
SV=$!
sleep 8
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
shot(){ import -window root /out/shots/p_$1.png 2>/dev/null || true; }

# 遊戲已在洞窟。畫面 640x400 於 800x600 視窗置中(letterbox: x偏移~80, y偏移~100)。
# 1) 移到頂端叫出 icon bar
xdotool mousemove 400 105; sleep 1; shot 01_topbar
# 2) 按 Enter(可能觸發開場敘事/確認)
xdotool key Return; sleep 3; shot 02_enter
# 3) 右鍵切換游標(walk→look) 後點營火
xdotool click 3; sleep 1; xdotool mousemove 400 410 click 1; sleep 3; shot 03_look_fire
# 4) 再點床鋪
xdotool mousemove 250 290 click 1; sleep 3; shot 04_look_bed
# 5) 點 Robin 自己
xdotool mousemove 640 390 click 1; sleep 3; shot 05_look_robin
# 6) 移頂端點 icon bar 最左(通常是 look/eye 圖示區),再點物件
xdotool mousemove 400 103; sleep 1; shot 06_bar2
# 7) 連按 Enter 推進任何文字框
xdotool key Return; sleep 2; shot 07_enter2
xdotool key Return; sleep 2; shot 08_enter3
kill $SV 2>/dev/null || true
