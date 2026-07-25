#!/usr/bin/env bash
# 《宇宙傳奇 IV》繁中化推廣片合成(全 docker、無剪輯軟體)。
#
# 素材鐵則(rulebook 93):畫面一律引擎實機截圖、配樂是原版遊戲音樂
# (MT-32 即時側錄,見 tools/rec_mt32.sh),兩者都不自產、不逼近。
#
# [雷] 不用 zoompan:`-loop 1 -t S` + 前置 fps 會讓 zoompan 算成 (FPS*S)^2 幀,
#      6 秒能燒到兩萬多幀。靜態 + fade 就夠看,而且秒出。
set -eu

# ===== theme:熔岩天空 × 電馭藍 ==============================================
# 色票不是憑喜好挑的,是從實機截圖的 dominant colors 取出來的:
#   #020312 / #0D105E → 標題畫面的深藍暈(sh_09)
#   #688FF1           → SPACE QUEST logo 的銀藍高光
#   #E74E03 / #E52400 → 氙星天空的熔岩橘紅(sh_13)
THEME_NAME="熔岩天空 × 電馭藍"
BG_DEEP='#020312'; BG_LITE='#0D105E'
ACCENT='#E74E03'      # 熔岩橘:標題與框線
ACCENT2='#688FF1'     # 銀藍:副標與 logo 呼應
TEXT='#DDE4FF'; DIM='#7A86B8'; INK='#0A0A14'
FT=/usr/share/fonts/opentype/noto/NotoSansCJK-Black.ttc     # 科幻 → 無襯線,不用明體
FB=/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc
FR=/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc
W=1280; H=720; FPS=25
SHOT=/shots; OUT=/out; TMP=/tmp/c; mkdir -p "$TMP" "$OUT"
GW=640; GH=400        # 遊戲畫面在 1024x768 截圖裡的位置
GX=192; GY=184

for f in "$FT" "$FB" "$FR"; do [ -f "$f" ] || { echo "!! 缺字型 $f"; exit 1; }; done

# 底:徑向漸層 + CRT 掃描線(母題——1992 VGA 的質感,不是奇幻羊皮紙)
bg(){ # $1 out
  convert -size ${W}x${H} "radial-gradient:${BG_LITE}-${BG_DEEP}" \
    \( -size ${W}x${H} xc:none -fill "#00000055" \
       -draw "$(for ((y=0;y<H;y+=3)); do printf 'rectangle 0,%d %d,%d ' $y $W $y; done)" \) \
    -compose over -composite "$1"
}

crop_shot(){ convert "$SHOT/$1" -crop ${GW}x${GH}+${GX}+${GY} +repage "$2"; }

# 片頭卡:大中文 + 熔岩橘浮雕 + 銀藍副標
card(){ # $1 out  $2 主標(中)  $3 英文小字  $4 副標
  bg "$TMP/_bg.png"
  convert "$TMP/_bg.png" -gravity center \
    -font "$FR" -fill "$DIM"     -pointsize 30 -annotate +0-190 "$3" \
    -font "$FT" -fill "#7a2a05"  -pointsize 96 -annotate +4+4    "$2" \
    -font "$FT" -fill "$ACCENT"  -pointsize 96 -annotate +0+0    "$2" \
    -font "$FB" -fill "$ACCENT2" -pointsize 40 -annotate +0+120  "$4" "$1"
}

# 大字卡:只有一句中文(節奏用)
bigcard(){ # $1 out  $2 中文  $3 小字
  bg "$TMP/_bg.png"
  convert "$TMP/_bg.png" -gravity center \
    -font "$FT" -fill "#7a2a05" -pointsize 78 -annotate +3+3 "$2" \
    -font "$FT" -fill "$ACCENT" -pointsize 78 -annotate +0+0 "$2" \
    -font "$FR" -fill "$DIM"    -pointsize 28 -annotate +0+110 "$3" "$1"
}

# 大圖遊戲畫面 + 下方字幕條
# [雷] 遊戲是 640×400(1.6),影片是 16:9;直接 resize 到滿版會把畫面橫向拉扁
#      (SPACE QUEST 的 logo 一眼就看得出變形)。等比縮到內容區高度、置中即可。
slide_full(){ # $1 out  $2 截圖  $3 字幕
  crop_shot "$2" "$TMP/_s.png"
  convert "$TMP/_s.png" -filter point -resize x$((H-150)) \
    -bordercolor "$ACCENT" -border 2 -background none -gravity center -extent ${W}x$((H-140)) "$TMP/_sf.png"
  bg "$TMP/_bg.png"
  convert "$TMP/_bg.png" \( "$TMP/_sf.png" \) -gravity north -geometry +0+0 -composite \
    -fill "${INK}dd" -draw "rectangle 0,$((H-140)) ${W},${H}" \
    -fill "$ACCENT" -draw "rectangle 0,$((H-142)) ${W},$((H-139))" \
    -font "$FB" -fill "$TEXT" -gravity south -pointsize 34 -annotate +0+50 "$3" "$1"
}

# 前後對照:左英文原版 / 右繁體中文
split_ba(){ # $1 out  $2 英文截圖  $3 中文截圖  $4 說明
  crop_shot "$2" "$TMP/_a.png"; crop_shot "$3" "$TMP/_b.png"
  convert "$TMP/_a.png" -filter point -resize 600x375! -bordercolor "$DIM"    -border 2 "$TMP/_a2.png"
  convert "$TMP/_b.png" -filter point -resize 600x375! -bordercolor "$ACCENT" -border 2 "$TMP/_b2.png"
  bg "$TMP/_bg.png"
  convert "$TMP/_bg.png" \
    \( "$TMP/_a2.png" \) -gravity northwest -geometry +18+150 -composite \
    \( "$TMP/_b2.png" \) -gravity northeast -geometry +18+150 -composite \
    -font "$FB" -fill "$DIM"    -gravity northwest -pointsize 30 -annotate +18+108 "英文原版" \
    -font "$FB" -fill "$ACCENT" -gravity northeast -pointsize 30 -annotate +18+108 "繁體中文" \
    -font "$FT" -fill "$ACCENT" -gravity north     -pointsize 40 -annotate +0+36  "$4" \
    -font "$FB" -fill "$TEXT"   -gravity south     -pointsize 30 -annotate +0+60  "▶" "$1"
}

# 對白卡:巨型引號 + 中文大字 + 英文原文小灰字
dcard(){ # $1 out  $2 中文  $3 英文原文  $4 場景標
  bg "$TMP/_bg.png"
  convert "$TMP/_bg.png" \
    -font /usr/share/fonts/truetype/dejavu/DejaVuSerif-Bold.ttf \
    -fill "#ffffff1f" -gravity northwest -pointsize 320 -annotate +24-40 '“' \
    -font "$FB" -fill "$ACCENT2"  -gravity northwest -pointsize 26  -annotate +70+120 "$4" \
    -font "$FB" -fill "$TEXT"     -gravity west      -pointsize 44  -annotate +70+0   "$2" \
    -font "$FR" -fill "$DIM"      -gravity southwest -pointsize 24  -annotate +72+90  "$3" "$1"
}

kb(){ # $1 png  $2 mp4  $3 秒 —— 靜態 + 淡入淡出
  local FO; FO=$(awk "BEGIN{print $3-0.5}")
  ffmpeg -y -loglevel error -loop 1 -i "$1" -t "$3" -r $FPS \
    -vf "fade=t=in:st=0:d=0.5,fade=t=out:st=$FO:d=0.5,format=yuv420p" \
    -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$2"
}

# ===== 分鏡 =================================================================
echo ">> 產生素材卡（theme: $THEME_NAME）"

# --- 片頭(使用者要求加長,全中文)---
card    "$TMP/00.png" "1992"          "SIERRA ON-LINE"                     "當年沒等到的中文版"
card    "$TMP/01.png" "宇宙傳奇 IV"    "SPACE QUEST IV"                     "時空穿越者"
bigcard "$TMP/02.png" "羅傑·威爾科　回來了" "太空清潔工，宇宙最不情願的英雄"
bigcard "$TMP/03.png" "而這一次，他說中文" "繁體中文化 v1.0"
card    "$TMP/04.png" "1,677 則"      "TRANSLATED"                          "對白・旁白・選單　全繁中"

# --- 主體:前後對照 + 對白卡交錯 ---
split_ba  "$TMP/10.png" en_08.png sh_09.png "標題畫面"
slide_full "$TMP/11.png" sh_09.png "不蓋原版 logo，中文副標疊在下方留白處"
split_ba  "$TMP/12.png" en_10.png sh_10.png "開場詢問"
dcard     "$TMP/13.png" "巨石漢堡的精華已經永遠附著在你的舌頭上了！" \
                        "Essence of Monolith Burger now coats your tongue - forever!" "巨石漢堡"
split_ba  "$TMP/14.png" en_21.png sh_18.png "遊戲內旁白"
slide_full "$TMP/15.png" sh_18.png "640×400 高解析中文，倚天 24 點明體直繪"
dcard     "$TMP/16.png" "別把兔子丟向續集警察！他的火氣可能一「觸」即發。" \
                        "Don't throw the bunny at the Sequel Policeman!" "氙星街頭"
split_ba  "$TMP/17.png" en_26.png sh_26.png "暫停面板"
slide_full "$TMP/18.png" sh_26.png "連烘進美術圖的按鈕字都重繪成中文"
dcard     "$TMP/19.png" "羅傑·威爾科，你還敢回來，膽子不小嘛。" \
                        "You've got a lot of nerve coming back here, Roger Wilco." "續集警察"

# --- 片尾 ---
bigcard "$TMP/90.png" "英文原音　繁體中文字幕" "CD 語音版全程保留原配音"
card    "$TMP/98.png" "三平台"        "LINUX / WINDOWS / MACOS"            "ScummVM patch・自備正版遊戲"
card    "$TMP/99.png" "宇宙傳奇 IV"    "github.com/wicanr2/space-quest4-cht" "致敬 Sierra On-Line 與兩位仙女座傑作者"

echo ">> 轉成片段"
LIST="$TMP/list.txt"; : > "$LIST"
add(){ kb "$TMP/$1.png" "$TMP/s_$1.mp4" "$2"; echo "file '$TMP/s_$1.mp4'" >> "$LIST"; }
add 00 4 ; add 01 5 ; add 02 4 ; add 03 4.5 ; add 04 4
add 10 5 ; add 11 4.5 ; add 12 4.5 ; add 13 5 ; add 14 5
add 15 4.5 ; add 16 5 ; add 17 5 ; add 18 4.5 ; add 19 5
add 90 4 ; add 98 4.5 ; add 99 6

echo ">> concat"
ffmpeg -y -loglevel error -f concat -safe 0 -i "$LIST" \
  -threads 2 -c:v libx264 -preset veryfast -pix_fmt yuv420p "$TMP/silent.mp4"

DUR=$(ffprobe -v error -show_entries format=duration -of csv=p=0 "$TMP/silent.mp4")
FO=$(awk "BEGIN{print $DUR-3}")
echo ">> 影片長度 ${DUR}s，鋪原版 MT-32 配樂"
# [雷] 配樂比影片短時不能用 -shortest(會把結尾卡砍掉)。
#      先 aloop 無限循環再 atrim 剪到影片長度,視訊音訊自然等長。
ffmpeg -y -loglevel error -i "$TMP/silent.mp4" -ss 10 -t 76 -i /music/music_full.wav \
  -filter_complex "[1:a]aloop=loop=-1:size=2000000000,atrim=0:$DUR,asetpts=N/SR/TB,afade=t=in:st=0:d=2,afade=t=out:st=$FO:d=3[a]" \
  -map 0:v -map "[a]" -threads 2 -c:v libx264 -preset veryfast -c:a aac -b:a 192k \
  -movflags +faststart "$OUT/video/sq4-cht-promo.mp4"

echo ">> 完成"
ffprobe -v error -select_streams v -show_entries stream=duration -of csv=p=0 "$OUT/video/sq4-cht-promo.mp4"
ffprobe -v error -select_streams a -show_entries stream=duration -of csv=p=0 "$OUT/video/sq4-cht-promo.mp4"
ls -la "$OUT/video/"
