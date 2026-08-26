-- clangd 針對 ARM 交叉編譯（arm-none-eabi-gcc）的調校。
-- 基礎設定來自 lazyvim.plugins.extras.lang.clangd，這裡只疊加需要的部分。
local selector = require("config.clangd_build")
local project_root = "/home/stephen/00-Project/wise_sdk_zephyr"

selector.setup({
  defaults = {
    -- 第一次沿用已驗證的 p18；使用 picker 切換後，以記住的選擇優先。
    [project_root] = project_root .. "/build/p18_coap_led_csma",
  },
})

local clangd_cmd = selector.clangd_cmd({
  "clangd",
  "--background-index",
  "--clang-tidy",
  "--header-insertion=iwyu",
  "--completion-style=detailed",
  "--function-arg-placeholders",
  "--fallback-style=llvm",
  -- 讓 clangd 去問 cross toolchain 內建的 include path，
  -- 否則會找不到 stdint.h 之類的 freestanding header。
  -- 允許這台機器已安裝的 ARM GNU toolchain 版本；各專案的
  -- compile_commands.json 仍決定實際要使用哪一版 compiler。
  "--query-driver=" .. vim.fn.expand("~")
    .. "/01-Tools/dev_tools_eclipse/arm-gnu-toolchain-*/bin/arm-none-eabi-*",
}, selector.project_root(vim.fn.getcwd()))

return {
  {
    "neovim/nvim-lspconfig",
    keys = {
      {
        "<leader>cb",
        function()
          selector.select()
        end,
        desc = "選擇 clangd build",
      },
    },
    opts = {
      servers = {
        clangd = {
          cmd = clangd_cmd,
        },
      },
    },
  },
}
