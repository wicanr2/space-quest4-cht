#!/usr/bin/env python3
"""把《宇宙傳奇 IV》CD 版被移除的 271 號房「因法律理由被拿掉的東西的倉庫」寫回遊戲。

CD 版只留下背景圖 pic.570、對白 message.271 與 view.271,房間程式(script/heap)
被整包拿掉,所以那組 18 個符號的時空艙座標按下去會找不到房間。本工具產生
271.scr / 271.hep 兩個散裝 patch 檔補回去——ScummVM 偵測到 script 271 存在後,
會自動停用它那條「停用該座標」的相容性 patch(script_patches.cpp,bug #11006),
座標因此自動復活,不必動引擎。

所有結構常數都是從遊戲既有資源反推來的(見 docs/timepod-coordinates.md):
  selector   0=y 1=x 2=view 3=loop 4=cel 110=init 146=setScript 153=posn
             278=doVerb 291=say 376=newRoom
  class      6=Script 122=Feature 124=Prop 136=Rm
  global     0=ego 2=目前房間 91=Messager
  屬性 index 房間 16=背景圖;Prop 27=view 28=loop
             Feature(查 class 122 的屬性選擇子表得到,不是猜的):
               w9=x(sel 1) w10=y(sel 0) w13=noun(sel 214) w14=module(sel 215)
               w15..w18 = nsTop/nsLeft/nsBottom/nsRight(sel 6/7/8/9)
               —— 注意是 (上,左,下,右),不是 (左,上,右,下)
  死亡       callb export10(類別, 索引) —— 通用死亡表,帶不了本房專屬台詞,
             所以先 say 專屬那句再叫死亡畫面。

用法: build_room271.py <dump 目錄> <輸出目錄>
"""
import os
import struct
import sys

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from sci11_asm import Asm                                    # noqa: E402

SEL_Y, SEL_X, SEL_VIEW, SEL_LOOP = 0, 1, 2, 3
SEL_INIT, SEL_DOVERB, SEL_NEWROOM, SEL_SETSCRIPT = 110, 278, 376, 146
# gMessager(global 89 = class 130)的完整說話介面。say(291) 只吃 cond,noun/verb/module
# 來自它自己的屬性;536 才是把 module/noun/verb/cond/seq 一次帶進去的那個。
# 逐條追過:class 127 的 536 → super class 114 的 536,參數順序就是下面這個。
SEL_SAYFULL = 536
# noun 不是 sayFull 的參數,是 Messager 的屬性(word 58)。class 114 是「類別」,
# 有屬性選擇子表,查出來 word 58 → selector 601。同一張表也印證了先前統計推出的
# selector 215 = module。
SEL_NOUN = 601
CLASS_FEATURE, CLASS_PROP, CLASS_RM = 122, 124, 136
G_EGO, G_ROOM, G_MESSAGER = 0, 2, 89   # 89 才是遊戲的 Messager;91 是 9xx 開發工具用的
MODULE = 271
PIC = 570
POD_VIEW, POD_LOOP = 410, 1

# 熱區:(名稱, noun, 左, 上, 右, 下)。座標對著 pic.570(320x200)量的。
# noun → 物件的對應是重建的:message.271 只留下文字,原始的 noun 指派無從得知,
# 這裡照描述內容配到畫面上對得起來的東西。
HOTSPOTS = [
    ('guys',    3, 104, 101, 164, 158),   # 兩個彈吉他的毛茸茸傢伙(Two Guys from Andromeda)
    ('critter', 4, 127,  52, 174,  94),   # 中央牆上的綠色生物
    ('flyer',   5,  13,  47,  48,  98),   # 左牆上的飛行生物
    ('graffiti',6,   0, 113,  64, 140),   # 左下角的塗鴉人物
    ('droids',  7, 216,  33, 319, 101),   # DROIDS R US 招牌
    ('shock',   8, 196, 112, 294, 181),   # RADIO SHOCK 招牌
    ('note',    9, 180,  99, 192, 114),   # 牆上的小紙條
    ('crates', 10,   0, 159,  64, 185),   # 左下角的箱子(兼房間本身的描述)
]
POD_NOUN = 1
# 動詞編號(從 613 的 ship/building doVerb 反推):1=看 4=動作 6=聞 7=嚐。
# message.271 的 1.4.0.1 正好是 verb 4,所以「對時空艙用動作」= 專屬 bad ending,
# 這是原始資料本來就有的設計,不是我編的。
V_LOOK, V_DO = 1, 4
# 出口是本專案加的:原始資料沒留下離開這裡的方法(verb 4 是死亡),
# 不補一個的話玩家會被關在裡面。畫面最下緣一條,點了就回時空艙內。
EXIT_RECT = (0, 186, 319, 199)
EGO_X, EGO_Y = 205, 180
POD_X, POD_Y = 265, 188


# ── 讀模板 ──────────────────────────────────────────────────────────────────
def load_objects(path):
    b = open(path, 'rb').read()
    n = struct.unpack_from('<H', b, 4)[0]
    pos = 6 + n * 2
    objs = []
    while pos < len(b) - 1 and struct.unpack_from('<H', b, pos)[0] == 0x1234:
        sz = struct.unpack_from('<H', b, pos + 2)[0]
        objs.append([struct.unpack_from('<H', b, pos + k * 2)[0] for k in range(sz)])
        pos += sz * 2
    strs = {}
    j = pos
    while j < len(b):
        e = b.find(b'\0', j)
        if e < 0:
            break
        s = b[j:e].decode('latin1')
        if s:
            strs[j] = s
        j += 1 + len(s)
    return objs, strs


def template(dump, res, name):
    objs, strs = load_objects(os.path.join(dump, res))
    for w in objs:
        if strs.get(w[8] + 2) == name:
            return list(w)
    raise SystemExit(f"!! 在 {res} 找不到物件 {name}")


# ── 產生 ────────────────────────────────────────────────────────────────────
def build(dump, out):
    rm_t = template(dump, 'heap.613', 'rm613')          # 一般可走動的房間
    ft_t = template(dump, 'heap.613', 'building')       # 純熱區 Feature
    pod_t = template(dump, 'heap.650', 'pod')           # 時空艙 Prop

    # --- 物件表(先排版面,才知道 heap 偏移) ---
    sc_t = template(dump, 'heap.650', 'meltRoger')      # Script 子類別範本
    names = ['rm271', 'roomScript']
    sizes = [len(rm_t), len(sc_t)]
    heap_off = {}
    o = 4                                                # heap +0 重定位偏移, +2 locals 數
    for nm, sz in zip(names, sizes):
        heap_off[nm] = o
        o += sz * 2
    obj_end = o

    strtab, strpos = bytearray(), {}
    for nm in names:
        strpos[nm] = obj_end + len(strtab)
        strtab += nm.encode('ascii') + b'\0'

    # --- script:方法表 + 程式碼 ---
    meth = {'rm271': [(SEL_INIT, 'rm_init')],
            'roomScript': [(144, 'room_script')]}      # 144 = changeState

    sp = 10                                              # +6 export 數, +8 export[0]
    meth_off = {}
    for nm in names:
        meth_off[nm] = sp
        sp += 2 + len(meth[nm]) * 4
    code_base = sp

    a = Asm()

    def say(noun, verb, client=False):
        """先設 noun 屬性,再 sayFull(module, _, verb, cond, seq[, client])。

        帶 client 時訊息關掉會 cue 回那個物件,用來推進 changeState。"""
        a.emit('pushi', SEL_NOUN); a.emit('pushi', 1); a.emit('pushi', noun)
        a.emit('pushi', SEL_SAYFULL); a.emit('pushi', 6 if client else 5)
        for v in (MODULE, 0, verb, 0, 1):
            a.emit('pushi', v)
        if client:
            a.emit('pushSelf')
        a.emit('lag', G_MESSAGER); a.emit('send', 22 if client else 20)

    # rm271:init
    a.label('rm_init')
    a.emit('pushi', 2); a.emit('pushi', 128); a.emit('pushi', POD_VIEW)
    a.emit('callk', 0, 4)                                # kLoad(128, view 410)
    a.emit('pushi', SEL_INIT); a.emit('pushi', 0)
    a.emit('super', rm_t[6], 4)                          # super init:
    a.emit('pushi', SEL_X); a.emit('pushi', 1); a.emit('pushi', EGO_X)
    a.emit('pushi', SEL_Y); a.emit('pushi', 1); a.emit('pushi', EGO_Y)
    a.emit('pushi', SEL_INIT); a.emit('pushi', 0)
    a.emit('lag', G_EGO); a.emit('send', 16)              # 定位 + 把羅傑加進場景
    a.emit('pushi', 0); a.emit('callb', 3, 0)            # HandsOn:把控制權交還玩家
    a.emit('pushi', SEL_SETSCRIPT); a.emit('pushi', 1)
    a.emit('lofsa', 'roomScript'); a.emit('push'); a.emit('self', 6)
    # 注意:不要在 init 裡 say。實測會讓訊息框卡在 modal 狀態(游標一直是 Wait),
    # 因為房間還沒初始化完就跳訊息。房間描述改掛在箱子那個熱區上。

    # callb 前面那個 push 是「參數個數」,不能省(省掉會 stack underflow);
    # callb 的第二個運算元則是參數佔的 byte 數。
    # (script 0 的 export 3 會把 global80 的兩個輸入旗標設 1;export 2 才是 HandsOff)
    a.emit('ret')

    # 出口(本專案加的):回到時空艙內
    a.label('exit_doverb')
    a.emit('lsp', 1); a.emit('toss')
    a.emit('pushi', SEL_NEWROOM); a.emit('pushi', 1); a.emit('pushi', 531)
    a.emit('lag', G_ROOM); a.emit('send', 6)
    a.emit('ret')

    # roomScript:changeState —— 只做一件事:進房穩定後說出房間描述。
    #
    # 原本想串成「逐則播出所有對白 → 專屬 bad ending」的導覽,但兩條推進方式實測都不成立:
    #   * 帶 client 讓訊息關掉時 cue 回來 → cue 不會回來,卡在同一則
    #   * 設 cycles=1 靠 cycle 推進     → say 不是 modal 的,11 個狀態一口氣跑完直接到死亡
    #   * 設 aTop 28(以為是 seconds)   → 序列直接停住,那個屬性不是秒數
    # 沒把 Script 的計時屬性認全之前不硬串,寧可少做也不要卡住玩家。
    a.label('room_script')
    a.emit('lap', 1); a.emit('aTop', 20)                 # state = 參數
    a.emit('push')
    a.emit('dup'); a.emit('ldi', 0); a.emit('eq?'); a.emit('bnt', 'st1')
    a.emit('ldi', 2); a.emit('aTop', 26)                 # 等兩個 cycle,讓房間畫完
    a.emit('jmp', 'st_end')
    a.label('st1')
    a.emit('dup'); a.emit('ldi', 1); a.emit('eq?'); a.emit('bnt', 'st_end')
    say(10, 1)
    a.label('st_end')
    a.emit('toss'); a.emit('ret')

    code, code_reloc = a.assemble(code_base, lambda n: heap_off[n])

    # --- 組 script ---
    scr = bytearray(code_base + len(code))
    struct.pack_into('<H', scr, 6, 1)                    # 1 個 export
    struct.pack_into('<H', scr, 8, heap_off['rm271'])
    for nm in names:
        p = meth_off[nm]
        struct.pack_into('<H', scr, p, len(meth[nm]))
        for k, (sel, lbl) in enumerate(meth[nm]):
            struct.pack_into('<H', scr, p + 2 + k * 4, sel)
            struct.pack_into('<H', scr, p + 4 + k * 4, a.labels[lbl])
    scr[code_base:] = code
    reloc = [8] + sorted(code_reloc)
    struct.pack_into('<H', scr, 0, len(scr))
    scr += struct.pack('<H', len(reloc)) + b''.join(struct.pack('<H', r) for r in reloc)

    # --- 組 heap ---
    def mkobj(tmpl, nm, over):
        w = list(tmpl)
        w[2] = meth_off[nm]                              # instance 沒有屬性表,指方法表即可
        w[3] = meth_off[nm]
        w[8] = strpos[nm]                                # name 指標(heap 偏移)
        for i, v in over.items():
            w[i] = v & 0xFFFF
        return w

    objs = [mkobj(rm_t, 'rm271', {16: PIC, 21: 531, 22: 531, 23: 531}),
            mkobj(sc_t, 'roomScript', {})]

    hp = bytearray(4)
    struct.pack_into('<H', hp, 2, 0)                     # 沒有 local
    for w in objs:
        for v in w:
            hp += struct.pack('<H', v)
    hp += strtab
    hreloc = [heap_off[nm] + 16 for nm in names]         # 每個物件的 name 指標
    struct.pack_into('<H', hp, 0, len(hp))
    hp += struct.pack('<H', len(hreloc)) + b''.join(struct.pack('<H', r) for r in hreloc)

    os.makedirs(out, exist_ok=True)
    open(os.path.join(out, '271.scr'), 'wb').write(bytes([0x82, 0]) + bytes(scr))
    open(os.path.join(out, '271.hep'), 'wb').write(bytes([0x91, 0]) + bytes(hp))
    print(f">> 271.scr {len(scr)+2} bytes  /  271.hep {len(hp)+2} bytes")
    print(f"   物件 {len(objs)} 個,程式碼 {len(code)} bytes,重定位 script {len(reloc)} 筆 / heap {len(hreloc)} 筆")


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit(__doc__)
    build(sys.argv[1], sys.argv[2])
