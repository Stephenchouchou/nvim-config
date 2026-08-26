# NOTES

## 2026-08-05｜C/C++ `gd` 跳轉失敗（No results found for lsp_definitions）

**現象**：在 `util_crc.c` 按 `gd`，Snacks picker 開得起來但顯示 `No results found for
lsp_definitions`；buffer 上有 2 error / 1 warning。

**根因（兩層）**

1. **clangd 是被 mason-lspconfig 順手啟動的，config 從沒設定過它。**
   `lazyvim.json` 的 `extras` 是空的 → LazyVim 的 `lang.clangd` extra 沒啟用。
   但 mason 裡裝了 clangd，而 mason-lspconfig 2.x 的 `automatic_enable` 預設 `true`
   （見 `LazyVim/lua/lazyvim/plugins/lsp/init.lua:259`），會自動 `vim.lsp.enable("clangd")`。
   → clangd 有跑，但裸跑、零調校。
   *判別法*：`gd` 的 picker 開得起來＝有 LSP attach（沒 attach 的話 LazyVim 連 keymap 都不綁）。

2. **沒有 `compile_commands.json`。** clangd 只能用猜的 fallback flags 編單檔，
   找不到 SDK 的 include path → header 解析失敗 → AST 半殘 → 跨檔 definition 查不到。
   那 2 個 error 多半就是 `'xxx.h' file not found`。

**已做（nvim config 側）**

- `lua/config/lazy.lua`：加入 `{ import = "lazyvim.plugins.extras.lang.clangd" }`。
- `lua/plugins/clangd.lua`（新檔）：疊加 `--query-driver=<arm-gnu-toolchain-*>/bin/arm-none-eabi-*`。
  ARM 交叉編譯必須要有這個，否則 clangd 找不到 toolchain 內建的 freestanding header
  （`stdint.h` 等）。版本目錄使用 glob，實際版本由各專案的 compilation database 決定。
- 驗證：headless 開 `.c` 檔，`vim.lsp.get_clients()` 回報 clangd attach，cmd 含 query-driver
  且 `~` 已展開為絕對路徑。

**各 C 專案的專案側設定**

每個 C 專案各自要在根目錄放一份「flag 來源」，三選一（優先序由高到低）：

| 方式 | 適用 | 精確度 |
|---|---|---|
| `compile_commands.json` | 有 build system（任何會實際呼叫 compiler 的都算） | 逐檔精確 |
| `.clangd`（`CompileFlags:`） | 沒有 build system、或 build 在 Windows（Keil/IAR） | 全樹共用一組 flag |
| `compile_flags.txt` | 同上，但語法更陽春 | 同上，且**無法指定 cross compiler** |

**wise_sdk_zephyr 已完成（2026-08-24）**：正確資料庫位於
`build/p18_coap_led_csma/compile_commands.json`；clangd 原先自動吃到
`build/compile_commands.json`（2026-06-14 舊檔），造成 driver 30 個解析錯誤。
`lua/config/clangd_build.lua` 現會掃描 `build/*/compile_commands.json`、記住 active
build，並透過 `--compile-commands-dir` 傳給 clangd；repo 內追蹤的
`clangd/config.yaml` 由 `~/.config/clangd/config.yaml` symlink 使用，只保留三個 clang
不支援的 GCC 參數移除規則（不影響 firmware build）。驗證：
app/driver source diagnostics 歸零；Nvim LSP 能由 `ieee802154_wise.c:445` 的
`hal_esmt_radio_tx()` 跳至 `hal_esmt_radio.c:267` 的實作。

切換方式：

- `<leader>cb` 或 `:ClangdBuildSelect`：搜尋並選擇 `build/*`，記住後重啟 clangd。
- `:ClangdBuildInfo`：顯示目前選擇。
- `:ClangdBuildLatest`：明確切到最近更新的 build；不會在背景擅自切換。
- 選擇記錄放在 `stdpath("state")/clangd-builds.json`，不污染 source repo。

產 `compile_commands.json`：

- `bear` **不綁 make** —— 它攔截任何會 spawn compiler 的指令：
  `bear -- make` / `bear -- ninja` / `bear -- scons` / `bear -- ./build.sh`
  （Makefile 專案記得先 `make clean`，沒重編就攔不到）
- **Eclipse CDT / GNU MCU Eclipse managed build**：makefile 是實體檔案，產在 build config
  目錄（可能不叫 `Debug`，例如 wise_sdk 叫 `subg_soc_9006`）。
  `cd <config 目錄> && make clean && bear -- make all`
  **必須寫 `make all`** —— CDT 的 makefile 先 include subdir.mk，default goal 會變成
  某個 `.o`，bare `make` 只編一個檔就結束（產出 1 筆的 compile_commands.json，很像成功）。
  Eclipse 自己呼叫的就是 `make all`，所以 IDE 裡不會踩到。
- CMake：`-DCMAKE_EXPORT_COMPILE_COMMANDS=ON`，再 symlink 回根目錄
- Ninja：`ninja -t compdb > compile_commands.json`
- Meson：build dir 自動產生
- Eclipse CDT managed build：`Debug/` 底下有自動產的 makefile → `bear -- make -C Debug`

新 build 會自動出現在 `:ClangdBuildSelect`；選取時會自動執行 LSP restart。

**實測結果（2026-08-05，clangd 22.1.8，測試碼含 `#include <stdint.h>`）**

| 設定 | 解析出的 triple | system include |
|---|---|---|
| `compile_flags.txt`（只有 `-xc -Iinc`） | `x86_64-pc-linux-gnu` ❌ | `/usr/include`（host 的）❌ |
| `.clangd` 設 `Compiler: <tc>/bin/arm-none-eabi-gcc` | `thumbv7em-unknown-none-eabi` ✅ | `arm-none-eabi/include` ✅ |
| 同上但拿掉 `--query-driver` | `thumbv7em-unknown-none-eabi` ✅ | `arm-none-eabi/include` ✅ |

兩個結論：

1. **`compile_flags.txt` 對交叉編譯不夠用** —— 它沒地方指定 compiler，clangd 會退回
   host x86_64 target 配 `/usr/include`。簡單檔案照樣 0 error（假象），但一碰到
   CMSIS `core_cm4.h`、`__ARM_ARCH`、ARM intrinsic 就爆。交叉編譯要用 `.clangd` 的
   `CompileFlags.Compiler`。
2. **`--query-driver` 在這個 toolchain 上不是必要的** —— clangd 22 只要 `Compiler:` 給
   絕對路徑，自己的 GCC toolchain 偵測就能找到 `arm-none-eabi/include`。
   （原本以為必要，實測推翻。）保留 query-driver 是為了 layout 特殊或有 `-specs=` /
   自訂 sysroot 的情況，留著無害。

**wise_sdk 副本陷阱**：`compile_commands.json` 裡是絕對路徑——在哪一份跑 bear，
clangd 就只認那一份。跳轉跳到別的副本代表 bear 跑錯地方了。
