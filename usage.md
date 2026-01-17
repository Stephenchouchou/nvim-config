# Neovim 配置使用說明

基於 [LazyVim](https://www.lazyvim.org/) 的個人配置。

## 自訂設定

### Options (`lua/config/options.lua`)

| 設定 | 值 | 說明 |
|------|-----|------|
| `conceallevel` | 2 | 隱藏 Markdown 標記符號，讓渲染效果更好 |

### 自訂插件

#### render-markdown.nvim (`lua/plugins/markdown_view.lua`)

在終端機內渲染 Markdown，讓標題、程式碼區塊、checkbox 等有視覺效果。

- 程式碼區塊有背景色
- 隱藏 `##` 符號，直接顯示為標題樣式
- 支援 checkbox 渲染

#### markdown-preview.nvim (`lua/plugins/markdown_view.lua`)

在瀏覽器中即時預覽 Markdown。

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>cp` | 開啟/關閉瀏覽器預覽 |

---

## LazyVim 常用快捷鍵

> `<leader>` 預設是 `空白鍵 (Space)`

### 一般操作

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>` | 顯示快捷鍵選單 (which-key) |
| `<leader>qq` | 離開 Neovim |
| `<leader>l` | 開啟 Lazy 插件管理器 |

### 檔案與搜尋 (Telescope)

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>ff` | 搜尋檔案 |
| `<leader>fg` | 全域文字搜尋 (grep) |
| `<leader>fb` | 搜尋已開啟的 buffer |
| `<leader>fr` | 最近開啟的檔案 |
| `<leader><leader>` | 搜尋檔案 (同 `<leader>ff`) |
| `<leader>/` | 在當前 buffer 搜尋 |

### 檔案總管 (Neo-tree)

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>e` | 開啟/關閉檔案總管 |
| `<leader>E` | 開啟檔案總管 (當前檔案位置) |

### Buffer 操作

| 快捷鍵 | 說明 |
|--------|------|
| `<S-h>` | 上一個 buffer |
| `<S-l>` | 下一個 buffer |
| `<leader>bd` | 刪除當前 buffer |
| `<leader>bo` | 刪除其他 buffer |

### 視窗操作

| 快捷鍵 | 說明 |
|--------|------|
| `<C-h/j/k/l>` | 切換視窗 (左/下/上/右) |
| `<leader>-` | 水平分割視窗 |
| `<leader>\|` | 垂直分割視窗 |

### 程式碼 (LSP)

| 快捷鍵 | 說明 |
|--------|------|
| `gd` | 跳到定義 |
| `gr` | 查看引用 |
| `K` | 顯示文件說明 (hover) |
| `<leader>ca` | 程式碼動作 (Code Action) |
| `<leader>cr` | 重新命名 |
| `<leader>cf` | 格式化程式碼 |

### 診斷與問題

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>xx` | 開啟 Trouble (問題列表) |
| `]d` | 下一個診斷訊息 |
| `[d` | 上一個診斷訊息 |

### Git

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>gg` | 開啟 LazyGit |
| `<leader>gf` | 搜尋 Git 檔案 |
| `<leader>gc` | 搜尋 Git commits |
| `]h` | 下一個 hunk (變更區塊) |
| `[h` | 上一個 hunk |

### 終端機

| 快捷鍵 | 說明 |
|--------|------|
| `<C-/>` | 開啟/關閉終端機 |
| `<leader>ft` | 開啟浮動終端機 |

### 其他實用功能

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>sn` | Noice 訊息歷史 |
| `<leader>un` | 關閉搜尋高亮 |
| `<leader>ur` | 重新繪製畫面 |

---

## 常用指令

| 指令 | 說明 |
|------|------|
| `:Lazy` | 開啟插件管理器 |
| `:LazyExtras` | 管理 LazyVim extras |
| `:Mason` | 開啟 LSP/工具安裝器 |
| `:checkhealth` | 檢查 Neovim 健康狀態 |
| `:MarkdownPreview` | 開啟 Markdown 瀏覽器預覽 |
| `:MarkdownPreviewStop` | 關閉 Markdown 預覽 |

---

## 目錄結構

```
~/.config/nvim/
├── init.lua              # 入口，載入 lazy.nvim
├── lazy-lock.json        # 插件版本鎖定檔
├── lazyvim.json          # LazyVim extras 設定
└── lua/
    ├── config/
    │   ├── autocmds.lua  # 自動指令
    │   ├── keymaps.lua   # 自訂快捷鍵
    │   ├── lazy.lua      # lazy.nvim 設定
    │   └── options.lua   # Vim 選項設定
    └── plugins/
        └── markdown_view.lua # Markdown 渲染與預覽設定
```

---

## 參考資源

- [LazyVim 官方文件](https://www.lazyvim.org/)
- [LazyVim Keymaps](https://www.lazyvim.org/keymaps)
- [lazy.nvim 文件](https://lazy.folke.io/)
