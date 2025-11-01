local M = {}

function M.setup()
  vim.g.markdown_fenced_languages = {
    "html", "python", "typst", "bash=sh", "lua", "javascript", "typescript", "json", "yaml", "go", "cpp", "c", "java"
  }

  local group = vim.api.nvim_create_augroup("MiniMarkdown", { clear = true })

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = group,
    callback = function()
      vim.wo.conceallevel = 1
      vim.wo.concealcursor = "n"
      vim.wo.wrap = true
      vim.wo.linebreak = true

      local hl = vim.api.nvim_set_hl

      -- Headings
      hl(0, "markdownH1", { fg = "#f38ba8", bold = true })
      hl(0, "markdownH2", { fg = "#fab387", bold = true })
      hl(0, "markdownH3", { fg = "#f9e2af", bold = true })
      hl(0, "markdownH4", { fg = "#a6e3a1", bold = true })

      -- Emphasis
      hl(0, "markdownBold", { bold = true, fg = "#cdd6f4" })
      hl(0, "markdownItalic", { italic = true, fg = "#bac2de" })
      hl(0, "markdownBoldItalic", { bold = true, italic = true, fg = "#ffffff" })

      -- Code blocks
      hl(0, "markdownCodeBlock", { fg = "#cdd6f4", bg = "#313244" })
      hl(0, "markdownCodeDelimiter", { fg = "#a6adc8" })
      hl(0, "markdownCode", { fg = "#89dceb", bg = "#313244" })

      -- Links
      hl(0, "markdownLinkText", { fg = "#74c7ec", underline = true })
      hl(0, "markdownUrl", { fg = "#89b4fa", underline = true })

      -- Lists
      hl(0, "markdownListMarker", { fg = "#cba6f7" })
      hl(0, "markdownOrderedListMarker", { fg = "#cba6f7" })

      -- Blockquotes
      hl(0, "markdownBlockquote", { fg = "#9399b2", italic = true })

      -- Horizontal rule
      hl(0, "markdownRule", { fg = "#6c7086" })
    end,
  })
end

return M
