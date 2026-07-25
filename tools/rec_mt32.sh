#!/bin/bash
# 用 SDL disk-audio 即時側錄原版 MT-32 音樂(rulebook 93:配樂必須是原版真實音訊)。
# [雷] 不可設 SDL_DISKAUDIODELAY=0——那是全速輸出,SCI 的音樂排序器依遊戲時鐘推進,
#      全速下 callback 狂抽但排序器不動 → 灌出 GB 大檔卻全是靜音。
export HOME=/tmp XDG_RUNTIME_DIR=/tmp DISPLAY=:99
export SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=/out/video_src/cap.raw
Xvfb :99 -screen 0 1024x768x24 >/tmp/xvfb.log 2>&1 &
sleep 2
cd /src
rm -f /out/video_src/cap.raw
timeout 150 ./scummvm --config=/out/scummvm.ini \
  --music-driver=mt32 --extrapath=/mt32 --music-volume=255 --output-rate=44100 \
  sq4-cht >/out/video_src/music.log 2>&1 &
sleep 130
pkill -f scummvm 2>/dev/null || true
sleep 2
ls -la /out/video_src/cap.raw
grep -iE "MT32|mt-32|cannot be used" /out/video_src/music.log | head -3
