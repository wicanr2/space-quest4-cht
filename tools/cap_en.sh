export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
Xvfb :99 -screen 0 800x600x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
timeout 45 ./scummvm --path=/game --auto-detect 2>/tmp/sv.log &
SV=$!
sleep 12; import -window root /out/shots/en_05.png 2>/dev/null || true
sleep 10; import -window root /out/shots/en_15.png 2>/dev/null || true
xdotool mousemove 400 300 click 1; sleep 5; import -window root /out/shots/en_20.png 2>/dev/null || true
xdotool key Escape; sleep 5; import -window root /out/shots/en_25.png 2>/dev/null || true
kill $SV 2>/dev/null || true
