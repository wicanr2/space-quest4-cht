#!/usr/bin/env bash
# 產生 README 用的「英文原版 ↔ 繁體中文」對照圖(上下堆疊,寬度一致好排版)
set -eu
FB=/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc
SHOT=/shots; OUT=/out/compare; mkdir -p "$OUT"
GX=192; GY=184; GW=640; GH=400
LBL=34; PAD=8
BG='#12161f'; ACC='#E74E03'; DIMC='#8a93a8'; TXT='#e8ecf5'

cmp2(){ # $1 out  $2 英文截圖  $3 中文截圖
  convert "$SHOT/$2" -crop ${GW}x${GH}+${GX}+${GY} +repage "/tmp/a.png"
  convert "$SHOT/$3" -crop ${GW}x${GH}+${GX}+${GY} +repage "/tmp/b.png"
  convert "/tmp/a.png" -bordercolor "$DIMC" -border 1 \
    -background "$BG" -gravity north -splice 0x${LBL} \
    -font "$FB" -fill "$DIMC" -pointsize 24 -annotate +0+6 "英文原版" /tmp/a2.png
  convert "/tmp/b.png" -bordercolor "$ACC" -border 1 \
    -background "$BG" -gravity north -splice 0x${LBL} \
    -font "$FB" -fill "$ACC" -pointsize 24 -annotate +0+6 "繁體中文" /tmp/b2.png
  convert /tmp/a2.png /tmp/b2.png -background "$BG" -gravity center -append \
    -bordercolor "$BG" -border ${PAD} "$OUT/$1"
}

cmp2 cmp-title.png     en_08.png sh_09.png
cmp2 cmp-intro.png     en_10.png sh_10.png
cmp2 cmp-narration.png en_21.png sh_18.png
cmp2 cmp-panel.png     en_26.png sh_26.png
ls -la "$OUT"
