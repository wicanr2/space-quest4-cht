# 版權與合規說明

## 原作
《Space Quest IV: Roger Wilco and the Time Rippers》© 1991, 1992 Sierra On-Line, Inc.
本專案與 Sierra / Activision 無任何關聯,僅為非商業的繁體中文化與歷史保存。

## 本 repo 內容(patch-only)
- 引擎補丁(`patches/`)、譯文(`translation/`)、工具(`tools/`)、文件(`docs/`)為本專案原創產出。
- **不含**遊戲本體(`resource.000` / `resource.aud` / `resource.map` / `*.drv` / `sierra.exe`)
  或 MT-32 ROM——玩家須自備正版遊戲與 ROM。
- 1992 年《軟體世界》中文說明書掃描 **未收錄**;README 只摘錄對玩家有用的操作說明要點。

## 第三方
- **ScummVM**(GPLv3+):`patches/` 是對 ScummVM 原始碼的修改,依 GPL 釋出。
  釋出修改過的 binary 時會一併提供對應原始碼與修改說明。
  pinned upstream commit 記於 `patches/UPSTREAM_COMMIT.txt`。
- **倚天中文系統(ETEN 3.53)** 點陣字模:有版權,**不隨本 repo 散布**。
  `tools/build_eten_font.py` 與 `tools/etunpack.py` 是格式解析工具,需玩家自備原始字型檔。
  不想自備的話,`tools/build_cht.py` + `tools/bake_hires_font.py` 可從開源的
  AR PL UMing(Arphic Public License)烘出可用的替代字型。

## MT-32 ROM
Roland MT-32 ROM 有版權,**絕不**納入本 repo 或任何釋出包;玩家須自備。
