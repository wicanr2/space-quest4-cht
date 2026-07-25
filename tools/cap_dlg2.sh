export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 140 ./scummvm --path=/game --auto-detect --language=tw >/out/dlg2.log 2>&1 &
SV=$!
sleep 20   # 等遊戲跑完開場進到可互動洞窟
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
shot(){ import -window root /out/shots/e_$1.png 2>/dev/null || true; }

shot 00_scene
# F5 存檔對話框(中文按鈕標籤 + 遊戲字型)
xdotool key F5; sleep 3; shot 01_f5
xdotool key Escape; sleep 2; shot 02_afteresc
# 右鍵切游標(look) → 點營火拿描述
xdotool click 3; sleep 1; shot 03_rclick
xdotool mousemove 400 410; sleep 1; xdotool click 1; sleep 3; shot 04_lookfire
# 再右鍵切 → 點床
xdotool click 3; sleep 1; xdotool mousemove 250 290; xdotool click 1; sleep 3; shot 05_lookbed
# 頂端 icon bar
xdotool mousemove 400 100; sleep 1; xdotool mousemove 400 96; sleep 1; shot 06_bar
kill $SV 2>/dev/null || true
