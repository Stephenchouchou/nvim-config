-- Markdown to PDF export using pandoc + tectonic
--
-- Features:
--   - Export current Markdown file to PDF
--   - Support Chinese characters (CJK fonts)
--   - Support Mermaid diagrams
--   - Auto open PDF after export
--
-- Keybinding: <leader>mp
--
-- Output: PDF will be saved in the same directory as the Markdown file
--
-- Dependencies (Arch Linux):
--   sudo pacman -S pandoc tectonic noto-fonts-cjk
--   npm install -g mermaid-filter

return {
  "nvim-lua/plenary.nvim",
  keys = {
    {
      "<leader>mp",
      function()
        local file = vim.fn.expand("%:p")
        local output = vim.fn.expand("%:p:r") .. ".pdf"
        local cmd = string.format(
          'pandoc "%s" -o "%s" --pdf-engine=tectonic -V "CJKmainfont=Noto Sans CJK TC" -V geometry:margin=1in -F mermaid-filter',
          file,
          output
        )
        vim.fn.jobstart(cmd, {
          on_exit = function(_, code)
            if code == 0 then
              vim.notify("PDF exported: " .. output, vim.log.levels.INFO)
              -- Open PDF
              vim.fn.jobstart({ "xdg-open", output })
            else
              vim.notify("PDF export failed", vim.log.levels.ERROR)
            end
          end,
        })
        vim.notify("Exporting to PDF...", vim.log.levels.INFO)
      end,
      desc = "Markdown to PDF",
    },
  },
}
