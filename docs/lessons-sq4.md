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
