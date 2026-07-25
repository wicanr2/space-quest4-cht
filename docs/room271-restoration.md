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
| 逐一點擊畫面上的東西看說明 | ❌ 見下方〈還沒解決的〉 |
| 專屬 bad ending | ❌ 同上 |

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

## 還沒解決的

### 一、熱區點不到

原本要讓畫面上 9 樣東西各自可點（毛茸茸二人組、DROIDS R US 招牌、紙條……）。
做法是建 `Feature`（class 122）物件、設好 `nsTop/nsLeft/nsBottom/nsRight`（w15–w18，
順序是上左下右，不是左上右下）、覆寫 `doVerb`。

物件建出來了、方法表正確、`init` 也照原版方式呼叫（原版 `rm613` 對它的 `building` 就是
`pushi 110; push0; lofsa <obj>; send 4`，一模一樣），但點下去只會得到遊戲的通用回應
（「你不需要看那個。」），代表點擊沒打到我的熱區。

排除過的可能：把熱區放大到整個畫面（還是打不到，所以不是框的位置）、把 `doVerb` 改成
無條件換房（沒反應，所以不是 `say` 的問題）、檢查 `init` 順序（`super init:` 在前，
跟 `rm613` 一致）、確認從 `rm613` 複製的屬性沒有夾帶指向原 heap 的指標
（`heap.613` 的重定位表每個物件只有一筆，就是 name）。

還沒查的方向：`class 44:init` 會依 `self.sel116(5)` 的結果把物件加進 global 5 或 global 32
兩個清單之一——需要確認 `sel116` 是什麼判斷、以及點擊時掃的是哪一個清單。

### 二、專屬 bad ending

`message.271` 的 `1.4.0.1` 是這一房專屬的死亡台詞：

> 抱歉，羅傑。因為法律理由，**你**被踢出遊戲了。

tuple 是 noun 1（時空艙）、verb 4（動作），也就是原本設計成「對時空艙用動作」會死。
死亡畫面本身已經確認能叫得出來（`callb export10`，實機看到「恢復／重新開始／離開」），
但它掛在時空艙的熱區上，卡在問題一。

想改用「進房後依序播出所有對白、最後接死亡」的導覽序列繞過去，三種推進方式都不成立：

- 帶 client 讓訊息關掉時 cue 回來 → cue 不會回來，卡在同一則
- 設 `cycles=1` 靠 cycle 推進 → `say` 不是 modal 的，11 個狀態一口氣跑完直接到死亡畫面
- 設 `aTop 28`（以為是 seconds）→ 序列直接停住，那個屬性不是秒數

沒把 `Script` 類別的計時屬性認全之前不硬串——寧可少做，也不要讓玩家卡在房間裡出不來。
目前版本只做一件事：進房、說出房間描述、把控制權交還玩家。

---

## 重跑

```bash
python3 tools/build_room271.py <SCI_DUMP_RES 的輸出目錄> <輸出目錄>
# → 271.scr / 271.hep,放進遊戲目錄或 extrapath 皆可(兩種都實測過)
```

相關工具：[`sci11_asm.py`](../tools/sci11_asm.py)（組譯器）、
[`sci11_disasm.py`](../tools/sci11_disasm.py)（反組譯器，用來回頭驗證組出來的東西）。
