# Neovim Configuration

基於 [LazyVim](https://www.lazyvim.org/) 的個人 Neovim 配置。

## 特色

- LazyVim 作為基礎框架
- Markdown 終端渲染 (render-markdown.nvim)
- Markdown 瀏覽器即時預覽 (markdown-preview.nvim)

## 安裝

### 前置需求

- Neovim >= 0.9.0
- Git
- [Nerd Font](https://www.nerdfonts.com/) (推薦)
- Node.js (Markdown 預覽需要)

### 安裝步驟

```bash
# 備份現有配置
mv ~/.config/nvim ~/.config/nvim.bak

# Clone 此 repo
git clone https://github.com/Stephenchouchou/nvim-config.git ~/.config/nvim

# 開啟 Neovim，插件會自動安裝
nvim
```

## 自訂快捷鍵

| 快捷鍵 | 說明 |
|--------|------|
| `<leader>cp` | 開啟/關閉 Markdown 瀏覽器預覽 |

> `<leader>` 預設是空白鍵

## 目錄結構

```
~/.config/nvim/
├── init.lua
├── lua/
│   ├── config/
│   │   ├── autocmds.lua
│   │   ├── keymaps.lua
│   │   ├── lazy.lua
│   │   └── options.lua
│   └── plugins/
│       └── markdown_view.lua
└── lazy-lock.json
```

## 自訂設定

- `lua/config/options.lua` - Vim 選項 (conceallevel 等)
- `lua/plugins/` - 自訂插件配置

## 參考

- [LazyVim 文件](https://www.lazyvim.org/)
- [usage.md](./usage.md) - 詳細使用說明與快捷鍵列表
