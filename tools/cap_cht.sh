export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 70 ./scummvm --path=/game --auto-detect --language=tw >/out/cht.log 2>&1 &
SV=$!
sleep 12
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
xdotool key Escape
sleep 6
import -window root /out/shots/cht_title.png 2>/dev/null || true
# 點 Introduction 按鈕(約 x=555,y=372 視窗內)
xdotool mousemove 555 372 click 1
sleep 5; import -window root /out/shots/cht_intro1.png 2>/dev/null || true
sleep 8; import -window root /out/shots/cht_intro2.png 2>/dev/null || true
xdotool key Return; sleep 6; import -window root /out/shots/cht_intro3.png 2>/dev/null || true
xdotool key Return; sleep 6; import -window root /out/shots/cht_intro4.png 2>/dev/null || true
kill $SV 2>/dev/null || true
