local M = {}
function M.setup()
  vim.g.markdown_fenced_languages = {
    "html", "python", "typst", "bash=sh", "lua", "javascript", "typescript",
    "json", "yaml", "go", "cpp", "c", "java", "rust", "toml"
  }

  local group = vim.api.nvim_create_augroup("MiniMarkdown", { clear = true })
  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = group,
    callback = function()
      vim.wo.conceallevel = 2
      vim.wo.concealcursor = "nc"
      vim.wo.wrap = true
      vim.wo.linebreak = true
      vim.wo.breakindent = true
      vim.wo.showbreak = "↪ "

      local colors = {
        text = "#cdd6f4",
        subtext1 = "#bac2de",
        subtext0 = "#a6adc8",
        overlay2 = "#9399b2",
        overlay1 = "#7f849c",
        overlay0 = "#6c7086",
        surface2 = "#585b70",
        surface1 = "#45475a",
        surface0 = "#313244",
        base = "#1e1e2e",
        mantle = "#181825",
        crust = "#11111b",
        rosewater = "#f5e0dc",
        flamingo = "#f2cdcd",
        pink = "#f5c2e7",
        mauve = "#cba6f7",
        red = "#f38ba8",
        maroon = "#eba0ac",
        peach = "#fab387",
        yellow = "#f9e2af",
        green = "#a6e3a1",
        teal = "#94e2d5",
        sky = "#89dceb",
        sapphire = "#74c7ec",
        blue = "#89b4fa",
        lavender = "#b4befe",
      }

      local hl = vim.api.nvim_set_hl
      -- Headings
      hl(0, "markdownH1", { fg = colors.peach, bold = true, underline = true })
      hl(0, "markdownH2", { fg = colors.blue, bold = true })
      hl(0, "markdownH3", { fg = colors.green, bold = true })
      hl(0, "markdownH4", { fg = colors.yellow, bold = true })
      hl(0, "markdownH5", { fg = colors.mauve, bold = true })
      hl(0, "markdownH6", { fg = colors.teal, bold = true })
      -- Emphasis
      hl(0, "markdownBold", { bold = true, fg = colors.text })
      hl(0, "markdownItalic", { italic = true, fg = colors.subtext1 })
      hl(0, "markdownBoldItalic", { bold = true, italic = true, fg = colors.lavender })
      -- Code blocks
      hl(0, "markdownCodeBlock", { fg = colors.text, bg = colors.surface0 })
      hl(0, "markdownCodeDelimiter", { fg = colors.overlay2 })
      hl(0, "markdownCode", { fg = colors.sky, bg = colors.surface0 })
      -- Inline code
      hl(0, "markdownInlineCode", { fg = colors.peach, bg = colors.surface1 })
      -- Links
      hl(0, "markdownLinkText", { fg = colors.blue, underline = true })
      hl(0, "markdownUrl", { fg = colors.sapphire, underline = true })
      -- Lists
      hl(0, "markdownListMarker", { fg = colors.mauve })
      hl(0, "markdownOrderedListMarker", { fg = colors.mauve })
      -- Blockquotes
      hl(0, "markdownBlockquote", { fg = colors.overlay0, bg = colors.mantle, italic = true })
      -- Horizontal rule
      hl(0, "markdownRule", { fg = colors.surface2 })
      -- Tables
      hl(0, "markdownTable", { fg = colors.text })
      hl(0, "markdownTableHead", { fg = colors.text, bold = true })
      hl(0, "markdownTableDelim", { fg = colors.overlay2 })
    end,
  })
end

return M
