export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 90 ./scummvm --path=/game --auto-detect --language=tw >/out/menu.log 2>&1 &
SV=$!
sleep 6
WID=$(xdotool search --class scummvm | head -1)
xdotool windowfocus --sync $WID 2>/dev/null || true
# 被動連拍:不點擊,讓開場 logo→標題→選單自然跑,每 3 秒一張
for s in $(seq 0 20); do
  import -window root /out/shots/m_$(printf %02d $s).png 2>/dev/null || true
  sleep 3
done
kill $SV 2>/dev/null || true
