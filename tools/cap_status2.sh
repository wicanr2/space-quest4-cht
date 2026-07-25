export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 160 ./scummvm --path=/game --auto-detect --language=tw >/out/status2.log 2>&1 &
SV=$!
sleep 24   # 等開場選單
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
shot(){ import -window root /out/shots/t_$1.png 2>/dev/null || true; }
shot 00_menu
# 進遊戲:按 Return(預設鈕=開始) + 點開始按鈕多次確保命中
xdotool key Return; sleep 1
xdotool mousemove 263 377; sleep 1; xdotool click 1; sleep 1; xdotool click 1; sleep 8
shot 01_game
sleep 5; shot 02_game
sleep 5; shot 03_game
kill $SV 2>/dev/null || true
