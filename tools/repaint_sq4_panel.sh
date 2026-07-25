#!/bin/bash
# 重繪 SQ4 暫停面板(view.947)與道具欄的英文美術字為中文。
# 按鈕 50x15 → 加高到 19(吃掉按鈕間距的 5px),讓 16x15 倚天字模原尺寸放得下。
# 標籤無邊框 → 加高到 15、需要時往右加寬。
set -e
cd "$(dirname "$0")/.."
python3 tools/repaint_buttons.py extract/dump/view.947 dist-cht/view.947 \
  --decoded extract/view947 --view-id 947 --workdir extract/repaint \
  --spec "0,2,速度,15,label"   --spec "0,3,音量,15,label"  --spec "0,4,細節,15,label" \
  --spec "0,5,遊戲暫停,15,label" --spec "0,6,音效開,15,label" --spec "0,7,文字開,15,label" \
  --spec "2,0,儲存,19"  --spec "2,1,儲存,19" \
  --spec "3,0,讀取,19"  --spec "3,1,讀取,19" \
  --spec "4,0,重來,19"  --spec "4,1,重來,19" \
  --spec "5,0,離開,19"  --spec "5,1,離開,19" \
  --spec "8,0,繼續,19"  --spec "8,1,繼續,19" \
  --spec "9,0,文字,19"  --spec "9,1,文字,19" \
  --spec "10,0,語音,19" --spec "10,1,語音,19" \
  --spec "11,0,兩者,19" --spec "11,1,兩者,19" \
  --spec "12,0,音效,19" --spec "12,1,音效,19" \
  --spec "13,1,速度,15,label"
