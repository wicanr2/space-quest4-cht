export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 160 ./scummvm --path=/game --auto-detect --language=tw >/out/intro2.log 2>&1 &
SV=$!
sleep 22   # 等開場選單「歡迎來到雪伍德森林」出現
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
shot(){ import -window root /out/shots/n_$1.png 2>/dev/null || true; }

shot 00_menu
# 點「序章」按鈕(最右, 視窗約 553,377)
xdotool mousemove 553 377; sleep 1; xdotool click 1; sleep 4; shot 01_intro
# 連續 Enter 推進開場敘事詩,每則截圖
for s in $(seq 2 11); do
  xdotool key Return; sleep 4
  shot $(printf %02d $s)_intro
done
kill $SV 2>/dev/null || true
