#!/bin/bash
# 重現「跑完片頭 / 跳過片頭後程式就跳出」。
# 重點:不主動 pkill,讓 scummvm 自己活或自己死,才看得到 exit code 與最後的訊息。
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99 SDL_AUDIODRIVER=dummy SCI_CHT_DEBUG=1
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src

TARGET="${1:-sq4-cht}"          # sq4-cht(中文/走 extrapath) 或 sq4-en(英文原版對照)
LOG=/out/repro_${TARGET}.log
mkdir -p /out/shots

./scummvm --config=/out/scummvm.ini "$TARGET" >"$LOG" 2>&1 &
PID=$!
shot(){ import -window root /out/shots/rp_${TARGET}_$(printf %02d $1).png 2>/dev/null || true; }

alive(){ kill -0 $PID 2>/dev/null; }

n=0
# 片頭:每 2 秒截一張並按一次 Escape(模擬玩家跳過),共 ~60 秒
for i in $(seq 1 30); do
  alive || { echo "!! 在第 $i 次 Escape 前就已結束(t≈$((i*2))s)" >>"$LOG"; break; }
  shot $n; n=$((n+1))
  xdotool key --clearmodifiers Escape
  sleep 2
done

# 跳過之後再觀察 40 秒,期間不做任何輸入——若這段自己死掉,就跟輸入無關
for i in $(seq 1 20); do
  alive || { echo "!! 靜置觀察期第 $i 次(t≈$((i*2))s)發現行程已結束" >>"$LOG"; break; }
  shot $n; n=$((n+1))
  sleep 2
done

if alive; then
  echo "== 觀察結束時仍存活,主動結束 ==" >>"$LOG"
  kill $PID 2>/dev/null; wait $PID 2>/dev/null; RC="(still-alive)"
else
  wait $PID 2>/dev/null; RC=$?
fi
echo "== exit code: $RC ==" >>"$LOG"
echo "===== $TARGET 結束,exit=$RC ====="
tail -30 "$LOG"
