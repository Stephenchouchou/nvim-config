-- Markdown to PDF export using pandoc
-- Requires: pandoc and a PDF engine (texlive or wkhtmltopdf)
-- Install on Arch: sudo pacman -S pandoc texlive-core
-- Or for lighter option: sudo pacman -S pandoc wkhtmltopdf

return {
  "arminveres/md-pdf.nvim",
  keys = {
    {
      "<leader>mp",
      function()
        require("md-pdf").convert_md_to_pdf()
      end,
      desc = "Markdown to PDF",
    },
  },
  opts = {
    -- Use tectonic as default engine (lighter than texlive)
    -- Options: "tectonic", "pdflatex", "xelatex", "lualatex", "context", "pdfroff", "wkhtmltopdf", "prince", "weasyprint", "pagedjs-cli"
    pandoc_user_args = {
      "-V", "geometry:margin=1in",
      "-V", "fontsize=12pt",
    },
    -- Ignore errors from pandoc (useful if you have some unsupported syntax)
    ignore_viewer_state = false,
    -- Open PDF after conversion
    preview = true,
  },
}
