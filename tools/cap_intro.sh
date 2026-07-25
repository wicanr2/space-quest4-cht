export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_LOG_GFX=1
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 120 ./scummvm --path=/game --auto-detect --language=tw >/out/intro.log 2>&1 &
SV=$!
sleep 10
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
xdotool key Escape; sleep 5
import -window root /out/shots/i_title.png 2>/dev/null || true
# 點 Introduction(root 座標 556,372)
xdotool mousemove --sync 556 372; sleep 1; xdotool click 1
sleep 4; import -window root /out/shots/i_intro00.png 2>/dev/null || true
for s in $(seq 1 12); do
  xdotool key Return; sleep 5
  import -window root /out/shots/i_intro$(printf %02d $s).png 2>/dev/null || true
done
kill $SV 2>/dev/null || true
