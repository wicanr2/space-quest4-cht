# 《宇宙傳奇 IV》繁中化實作筆記（SCI1.1 VGA talkie）

素材：SQ4 CD 1.0（1992-12），`resource.000` 5 MB + `resource.aud` 169 MB 語音。
引擎軌：SCI1.1，`GfxText16` / `GfxPaint16`（非 SCI32），底稿沿用 Longbow（SCI1 VGA）patch。

## 一、SCI1.1 與前代（SCI0 EGA）的抽字差異

- **字串常數住 `heap.NNN`，不住 `script.NNN`**。SCI1.1 把 SCI0 的單一 script 資源拆成
  bytecode（`script`）與資料段（`heap`）。沿用 SCI0 的 `extract_ega_scripts.py` 掃 `script.*`
  只會掃出 bytecode 雜訊，玩家可見字整批漏掉。→ `extract_sci11_strings.py` 只掃 `heap.*`。
- **9xx 是 Sierra 內建開發工具**（DialogEditor、Polygon Editor、Feature Writer），跟著遊戲一起
  出貨但玩家看不到。抽字要用資源編號 ≤ 899 過濾，否則會白翻上百則開發工具字串。
  例外：`heap.900`（Restart/Quit）、`heap.995`（You are carrying:）是真的會顯示，手動補回。
- **message 資源是 V4**（`headerSize=10, recordSize=11`，`stringOffset` 在 rec+5、talker 在 rec+4）。
  沿用 V3 的解析器會整批解錯。版本在資源前 4 bytes：`4000`/`4010`。

## 二、狀態列：runtime 組字 + 高度不足

SQ4 狀態列顯示的是「假續集標題」，實際傳進 `DrawStatus` 的字串長這樣：

```
\x06 × 62  +  "Space Quest \x1d - Vohaul's Revenge \x1f"
```

- `\x06` 是置中用的 padding，數量隨標題長度變；`\x1d`/`\x1f` 是狀態列專用字型裡的羅馬數字。
- 因此**整串查表永遠 MISS**，只能做片段替換（片段的中文放 `translation.tsv`，不寫死在引擎裡）。
- 資源裡存的是 `\x01` + `'d'` 兩個 byte，runtime 才合成 `\x1d`——抽字抽到的 key 與 runtime
  字串不同，這 6 則要另外手工處理。

**高度問題**：狀態列只有 10 script rows（20 display rows），24px 的 hi-res 中文字模會被裁掉
下緣並溢出到畫面。修法是 `GfxScreen::_statusTextActive` 旗標 + `GfxFontChinese::drawCompact()`：
狀態列改用 16×15 倚天字模**以 1:1 畫進 display buffer**（＝7.5 script rows），塞得下又銳利。

## 三、`kTextSize` 要量測譯文

`GfxText16::Box()` 在繪製當下才把英文換成中文，但視窗大小是更早的 `kTextSize` → `Size()`
決定的。只 hook `Box()` 會用英文的行數去開視窗：中文較精簡時視窗過高（下半空白），
中文較長時**視窗過矮、文字溢出**。→ `Size()` 開頭也要查表換成譯文再量。

## 四、暫停面板的 baked-art：確認為「不做」

面板（SAVE/RESTORE/RESTART/QUIT/TEXT/SPEECH/BOTH/AUDIO/PLAY、DETAIL/VOLUME/SPEED、
GAME PAUSED）全是 `view.947` 的 cel 美術字，可以用 `sci_view.py` 解碼重繪。實測後決定不做：

- 按鈕 cel 是 **50×15**，扣掉立體邊框只剩約 11px 文字帶；倚天 24×24 縮到 11px 後
  筆劃多的字（儲、讀、離、緻）糊成一團，13px 才勉強可讀。
- 更關鍵的是 `DETAIL`/`VOLUME`/`SPEED`/`GAME PAUSED` 那批 cel 只有 **9px 高**，
  任何中文在這個高度都不可能可讀。
- 放大 cel 會打壞腳本寫死的面板版面（背景板與按鈕座標都是固定的）。

rulebook 81 的原則是「CJK 塞不下就拉畫布，不要縮字」；這裡畫布拉不動，所以維持英文，
而不是硬塞一排糊掉的中文。面板內同一個黑色小資訊框（顯示模式／分數）同理保持英文——
那個框行距是 9 script rows 寫死的，中文兩行必定重疊。

標題畫面則相反：pic 1 下方有整片空白，`.ovl` 疊圖放得下 16×15 中文副標，所以有做。

## 五、字型檔位（定案）

| 用途 | 字模 | 來源 |
|---|---|---|
| 對白／旁白（hi-res 直繪 display buffer） | 24×24 | 倚天 `STD.24M` 明體（`etunpack.py` 解壓）+ `SPCFONT.24` |
| 狀態列（1:1 畫進 display） | 16×15 | 倚天 `STDFONT.15` + `SPCFONT.15` |
| 標題副標疊圖 | 16×15 | 同上 |

`kBig5Width = 12`（script 座標的前進寬度）→ 顯示字距 24px，剛好等於 hi-res 字框寬，
字邊到邊密排。2141 個用到的字全部在倚天涵蓋範圍內，**零 TTF fallback**。

## 六、打包踩到的雷

**Windows 的 `.bat` 用括號區塊寫 ini 會只寫進第一行。**
`> file ( echo A & echo B )` 這種寫法在部分 cmd 實作（含 wine）只有第一個 `echo` 進檔案，
其餘噴到畫面 → 產出的 `scummvm.ini` 只剩 `[scummvm]` 一行，遊戲啟動時說「Unrecognized game」。
改成逐行 `>> "%INI%" echo ...` 就穩。**這個 bug 只有實跑才看得出來**——腳本本身沒有語法錯誤，
zip 打包也一切正常。

**`.bat` 裡不要用 `%*` 轉發參數。** patch 版的第一個參數是遊戲路徑，已經被 `%~1` 取用，
再用 `%*` 轉發會把它當成第二個 target 再送一次 → `Stray argument`。

**ini 內容全部用 ASCII。** cmd 在不同 codepage 下用 `echo` 寫中文會變亂碼（`description=` 那行
會整行壞掉）。中文只留在給玩家看的提示訊息與檔名。

**啟動器不能靠 `--language=tw --auto-detect`。** SQ4 CD 同時符合 DOS 與 Windows 兩個偵測條目，
`--auto-detect` 遇到兩個候選只會列出來、不會啟動；而且 SCI1.1 的偵測器在偵測階段就會用語言
過濾條目。啟動器自己寫一份帶 `language=tw` 的 target 進 config 再指定它，兩個問題一起解決。

**不要在產出的 config 裡設 `gui_language=zh_TW`。** 包裡沒附 CJK 的 GUI 字型，設了只會讓
ScummVM 的主題引擎報 `Error loading localized Font` 並載入失敗。遊戲內的中文與 GUI 語言無關。

## 七、推廣片

配樂是**原版遊戲音樂**（rulebook 93 [HARD]：不可自產、不可用合成器逼近）。做法是 SDL disk-audio
即時側錄 Munt 的 MT-32 輸出：

```
SDL_AUDIODRIVER=disk SDL_DISKAUDIOFILE=cap.raw \
  scummvm --music-driver=mt32 --extrapath=<放 ROM 的夾> --music-volume=255 --output-rate=44100
```

**不要設 `SDL_DISKAUDIODELAY=0`**。那是全速輸出，但 SCI 的音樂排序器是依遊戲時鐘推進的——
全速下 audio callback 狂抽而排序器不動，會灌出 GB 級的檔案卻整段 −91 dB 靜音。即時錄 130 秒
wall-clock 得到 93.9 秒音訊（16.5 MB），`volumedetect` 量到 mean −23.5 dB、max −3.3 dB
（非靜音、無破音），log 出現 `Falling back to MT32` 代表 ROM 真的載入了。

合成端的雷（都寫在 kb `game-promo-video-ffmpeg`，這次確認仍然成立）：

- **不用 zoompan**。靜態圖 + fade 就夠，zoompan 的 `d` 是「每個輸入幀輸出 d 幀」，
  配上前置 `fps` 會變成 `(FPS×S)²` 幀。
- **配樂比影片短時不能用 `-shortest`**，會把結尾卡一起砍掉。先 `aloop` 無限循環再
  `atrim` 剪到影片長度，視訊音訊自然等長（本片兩者都是 84.12s）。
- **4:3 的遊戲畫面不要直接 resize 成 16:9**。SPACE QUEST 的 logo 一眼就看得出被拉扁；
  等比縮到內容區高度、置中，兩側露出主題底色即可。
- **抽幀檢查要抽片段中點**，抽在邊界上會落在 0.5 秒的 fade 裡，看起來像整張卡都太暗。

本片的 theme 是從實機截圖的 dominant colors 取的（標題畫面的深藍 `#020312`/`#0D105E`、
logo 銀藍 `#688FF1`、氙星天空的熔岩橘 `#E74E03`），科幻題材用無襯線字、母題是 CRT 掃描線——
刻意不沿用其他專案的配色模板。

**最後一版修的錯配**：有一幕字幕寫「640×400 高解析中文」，配的截圖卻是圖示欄降下來的畫面，
一個中文都沒有。同一類錯配先前在 README 抓過，卻沒回頭改影片腳本。修法不是換張圖了事，
而是加 `assert_has_dialog()`：量畫面中段淺灰（SCI 對白框底色）的佔比，低於 8% 直接讓 build 失敗。
實測有對白框的 37–57%、沒有的 0.09–0.25%，門檻分得很開。**字幕宣稱的事，要由畫面自己證明。**

---

## 八、判斷「這一版有沒有防拷」：缺席也是證據

SQ4 CD 語音版拿掉了防拷關卡，但玩家會問「你怎麼確定後段不會突然跳出來」。開機實測只能證明
開機那一段，得補資源層的證據。順序是這樣：

1. **先看程式在不在。** SCI 的房間 = `script.NNN` + `heap.NNN`。防拷是 815 號房，
   而 800–820 之間只有 815（和 805）這兩對不見了。程式不存在 → 跑不起來。
2. **別被遺留素材騙。** `message.815`、`view.815`、`sound.815` 都還在，光看「有防拷文字」
   會得到相反結論。把 `view.815` 解碼出來確實是那台鍵盤，但那只證明**曾經**有。
3. **確認沒人叫得到它。** 掃全部 203 個 script 找常數 815，只有 `script.070` 兩處是
   `pushi 40; push1; pushi 815`——型態和 `newRoom: 815` 一模一樣。
4. **selector 編號要驗，不能猜。** 沒有 `vocab.997` 就用統計反推：把每個 selector 的所有
   賦值收集起來，看值對應到哪一類資源。selector 40 的值有 99/102 對得上 `sound.NNN`
   （而 `heap.070` 裡正好有個物件叫 `aSound`）→ 是 `number`，那兩處在播音效。
   真正的換房 selector 是 376（57 個值裡 56 個有 `script`、55 個有 `pic`），它的值裡沒有 815。

第 4 步是關鍵。停在第 3 步會得出「有兩處疑似呼叫防拷」的錯誤結論，而「型態像 `newRoom`」
純粹是巧合——一參數 send 的位元組序列本來就長一樣。**位元組型態不能當語意證據，
selector 的身分要另外用資料反推。**（同 rulebook 62 靜態反追溯源）

完整結論與對照表在 [`copy-protection.md`](copy-protection.md)。

---

## 九、緩衝區要照 pitch 配置，不是照繪製寬度（issue #1）

macOS 版跑完片頭就跳出。回報者附的 crash report 直接點名：

```
Application Specific Information: stack buffer overflow
4  scummvm.bin  Sci::GfxFontChinese::drawCompact(...)   ← __stack_chk_fail
6  scummvm.bin  Sci::GfxText16::DrawStatus(...)
```

狀態列是片頭結束後第一個被畫的東西，時機完全吻合。原因是這兩個數字被當成同一個：

| | 值 | 是什麼 |
|---|---|---|
| `kBig5Width` | 12 | **排版**用的 advance width，字要間隔多寬 |
| `kChineseTraditionalWidth` | 16 | **點陣圖**的一列有多寬，也就是 `drawBig5Char` 的 destination pitch |

`drawCompact` 用 16 當 pitch 去填一個 `byte glyph[kBig5Width * 16]`（192 bytes）的緩衝區，
而 `drawBig5Char` 實際會寫到 `16 × 15 = 240` bytes——超出 48 bytes，正好蓋過 stack canary。

同一支程式碼的另一條路徑 `draw()` 沒事，是因為它 pitch 傳 `kBig5Width`（12×15 = 180 < 192）。
**同一個緩衝區宣告，一條安全一條溢位**，差別只在呼叫端傳了哪個常數。

### 為什麼三個平台只有 macOS 炸

clang 在 arm64 預設開 `-fstack-protector-strong`，寫穿 canary 就 `SIGABRT`。當時 Linux 與
Windows build 都沒開，同一份溢位靜靜跑過去，實機測試全綠。

驗證方式就是把這個變因補回去：只把 `fontchinese.cpp` 加上 `-fstack-protector-strong` 重編、
relink，Linux 立刻在同一個位置死掉（開場問「要跳過還是看完」之後），修好再跑就活過整段。
**能重現的失敗訊號比讀十遍程式碼有用。**

現在三個平台的 build 都帶 `-fstack-protector-strong`（`tools/apply_patches.sh` 的 configure
指引與 `.github/workflows/build-macos.yml` 兩個弧都標成 `[HARD]`）。

### 留下來的規則

- 交給別人填的緩衝區，尺寸要照**你傳給它的 pitch × 高度**算，不要照繪製時用的寬度。
  兩者剛好都叫「寬度」，但一個是排版度量、一個是記憶體步長。
- 上游把 `kChineseTraditionalMaxHeight` 設成 private，就自己寫一份具名上限常數，
  不要拿手邊剛好順眼的數字（原本那個 `16` 是硬寫的字面值，跟 pitch 無關）。
- 平台差異造成的「只有某一台會壞」，多半不是那台的問題，是**只有那台開了檢查**。
