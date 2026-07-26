# 把「因法律理由被拿掉的東西」的倉庫寫回遊戲

《宇宙傳奇 IV》藏了一個房間，裡面堆滿了 Sierra 因為法律問題從自家遊戲裡撤掉的東西。
房間裡的告示牌寫著：

> 這裡似乎是專門存放所有因為法律問題被 Sierra 遊戲刪掉的東西的儲藏室。

**而那個房間本身也被拿掉了。** CD 語音版把它的程式（`script.271`、`heap.271`）整包移除，
只留下背景圖 `pic.570` 和對白 `message.271`。原版跑到這裡會找不到房間直接當掉，
所以 ScummVM 乾脆把那組 18 個符號的時空艙座標停用（`script_patches.cpp`，bug #11006）。

這份文件記錄怎麼把它寫回去。

![還原後的 271 號房](../screenshots/room271-restored.png)

---

## 現況

| 項目 | 狀態 |
|---|---|
| 房間進得去、不當機 | ✅ 實機驗證 |
| `pic.570` 背景正常繪製 | ✅ |
| 羅傑在房間裡、可走動 | ✅ |
| 房間描述以中文顯示 | ✅ |
| 從 `extrapath` 載入（打包用得上） | ✅ |
| 逐一點擊畫面上的東西看說明（9 個熱區） | ✅ 實機驗證 |
| 專屬 bad ending | ✅ 實機驗證 |

`271.scr` / `271.hep` 兩個檔已收進 [`dist-cht/`](../dist-cht/)，三平台的 patch 包都會帶上。
玩家不用做任何事——**ScummVM 偵測到 `script.271` 存在，就會自動停用它那條「停用該座標」的
相容性 patch**，那 18 個符號因此自動復活，不必改引擎。

座標見 [時空艙座標全解](timepod-coordinates.md#被剪掉的那一站)。

---

## 怎麼做的

### 檔案格式

散裝 patch 檔（`NNN.scr` / `NNN.hep`）是引擎原生支援的——遊戲目錄裡本來就有 Sierra 自己放的
`335.scr`、`390.hep`。格式全部從既有資源反推，寫進了
[`tools/sci11_asm.py`](../tools/sci11_asm.py) 的說明裡：

```
patch 檔頭  2 bytes: [0x80|resType, headerSize]   script=0x82  heap=0x91
heap        +0 重定位表偏移  +2 local 數  +4 locals  物件  字串  重定位表
物件        w0=0x1234  w1=大小(words)  w2=屬性表偏移  w3=方法表偏移
            w6=superclass  w8=name 指標
script      +0 重定位表偏移  +6 export 數  +8 export 表  方法表們  bytecode  重定位表
方法表      count, (selector, codeOffset) * count
重定位表    heap:每個物件 name 指標的位置(物件偏移+16)
            script:export 項 + 每個 lofsa 運算元的位置
```

順帶解掉一個先前一直沒想通的怪事：ScummVM 原始碼寫「物件區起點 = `4 + heap[2]*2`」，
但那是對它內部的 `_heap` 而言，比 `SCI_DUMP_RES` 倒出來的檔案少 2 bytes——那 2 bytes
就是 patch 檔頭。

### 需要知道的常數（全部查表得到，不是猜的）

| 項目 | 值 | 怎麼確定的 |
|---|---|---|
| selector | 0=y 1=x 2=view 3=loop 4=cel | 從 `rm613:init` 設定 ego 的那段反推 |
| | 110=init 146=setScript 278=doVerb 376=newRoom | 方法表 + 呼叫端交叉比對 |
| | 536=完整版 say 601=Messager 的 noun | class 114 的屬性選擇子表 |
| class | 6=Script 122=Feature 124=Prop 136=Rm | 物件的 `w6` |
| global | 0=ego 2=目前房間 **89=Messager** | 89 是 `class 130`，91 是 9xx 開發工具用的 |
| 動詞 | 1=看 4=動作 6=聞 7=嚐 | `ship:doVerb` / `building:doVerb` 對照 message tuple |
| 房間屬性 | index 16 = 背景圖 | 100 個房間裡 96 個的值 == 房號，不吻合的正是背景圖≠房號那幾間 |
| 死亡 | `callb export10(類別, 索引)` | `meltRoger` 最後一個 state |
| HandsOn | `callb export3` | script 0 的 export 3 會把 global80 的兩個輸入旗標設 1 |

### 說訊息

`message.271` 用的慣例跟遊戲其他房間**不一樣**：271 是「每個物件不同 noun ＋ verb 1」，
613/531 是「固定 noun 99 ＋ 每個物件不同 cond」。這反過來佐證 271 是早期版本的殘留。

`Messager:say(cond)` 只吃 cond，noun 來自它自己的屬性。所以要先設 noun 再說：

```
g89.sel601(noun)                          ; noun 屬性(word 58)
g89.sel536(module, _, verb, cond, seq)    ; 完整版
```

訊息本身走 `message.271` 的英文原文，中文是本專案的引擎在繪製時查 `translation.tsv` 換上去的
——不需要改動 Sierra 的資源。

---

## 找了最久的那個 bug:一個從範本複製過來的欄位

熱區一開始完全點不到。物件建出來了、方法表正確、`init` 也照原版方式呼叫，
把熱區放大到整個畫面照樣沒反應。

繞了很久之後改用第一性原理:**與其猜「誰在掃清單」,直接讀「一次點擊怎麼變成一次
`doVerb` 呼叫」**。順著 `Feature:handleEvent`(class 44 的 selector 133)往下,
它在做任何事之前只擋兩關,其中一關是 `self.sel219(event)`——那就是 `onMe`。
把 `onMe` 讀完，條件是這樣:

```
矩形測試:  w16 ≤ x ≤ w18   且   w15 ≤ y ≤ w17
然後:
  if w21 != 26505:  再 AND 一次 callk 78(控制層檢查)
```

矩形我設對了。問題出在 **w21**:class 122 的預設值是 `26505`(0x6789,「未設定」哨兵),
但我拿來當範本的 `building` 把它設成 **2**——因為 613 那個房間需要控制層檢查。
我整包複製 `building`,把這道檢查一起帶走了,而它在 `pic.570` 上永遠不會通過。

把 w19 / w21 還原成哨兵值,九個熱區立刻全部正常。

**教訓**:複製一個現成物件當範本很省事,但範本身上那些「為了它自己的場景才設的欄位」
會跟著過來。逐欄確認過語意再決定要不要保留,不能整包照抄。

### 其他踩到的東西

- **`say` 是非阻塞的。** 對時空艙用「動作」時,說完專屬台詞就直接叫死亡畫面,
  那句會被瞬間蓋掉。改成掛一個 Script 隔 60 個 cycle 再叫死亡,玩家才讀得到。
- **不要在 `init` 裡 say。** 房間還沒初始化完就跳訊息,訊息框會卡在 modal 狀態
  (游標一直是 Wait)。房間描述改由 `setScript` 的第一個 state 說。
- **`callb` 前面那個 push 是參數個數**,省掉會 stack underflow;`callb` 的第二個
  運算元則是參數佔的 byte 數,兩者不同。
- **`sel116` 是 `RespondsTo`**(`callk 7`),參數 selector 5 是 `underBits`。
  `Feature` 沒有 selector 5,所以進 `features`(global 32);有的(Prop/Actor)進
  `cast`(global 5)。這條查完確認登記路徑沒問題,排除了一個方向。
- **用除錯器 `newRoom` 進場的房間,輸入是關著的**——正常進場才會跑抵達腳本、
  腳本裡才 HandsOn。拿原版房間當對照組時要記得這件事,否則會以為「原版也點不到」。

---

## 重跑

```bash
python3 tools/build_room271.py <SCI_DUMP_RES 的輸出目錄> <輸出目錄>
# → 271.scr / 271.hep,放進遊戲目錄或 extrapath 皆可(兩種都實測過)
```

相關工具：[`sci11_asm.py`](../tools/sci11_asm.py)（組譯器）、
[`sci11_disasm.py`](../tools/sci11_disasm.py)（反組譯器，用來回頭驗證組出來的東西）。
