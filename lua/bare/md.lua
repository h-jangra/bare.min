local M = {}

function M.setup()
  vim.g.markdown_fenced_languages = {
    "html", "python", "bash=sh", "lua", "javascript", "typescript", "json", "yaml", "go", "cpp", "c", "java"
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
      hl(0, "markdownH1", { fg = "#ff6767", bold = true })
      hl(0, "markdownH2", { fg = "#ffaa55", bold = true })
      hl(0, "markdownH3", { fg = "#d4b86e", bold = true })
      hl(0, "markdownH4", { fg = "#7dd485", bold = true })

      -- Emphasis
      hl(0, "markdownBold", { bold = true, fg = "#e0e0e0" })
      hl(0, "markdownItalic", { italic = true, fg = "#d0d0d0" })
      hl(0, "markdownBoldItalic", { bold = true, italic = true, fg = "#ffffff" })

      -- Code blocks
      hl(0, "markdownCodeBlock", { fg = "#f8f8f2", bg = "#282a36" })
      hl(0, "markdownCodeDelimiter", { fg = "#6272a4" })
      hl(0, "markdownCode", { fg = "#8be9fd", bg = "#2a2d3a" })

      -- Links
      hl(0, "markdownLinkText", { fg = "#61afef", underline = true })
      hl(0, "markdownUrl", { fg = "#52a0ff", underline = true })

      -- Lists
      hl(0, "markdownListMarker", { fg = "#bd93f9" })
      hl(0, "markdownOrderedListMarker", { fg = "#bd93f9" })

      -- Blockquotes
      hl(0, "markdownBlockquote", { fg = "#7a88a0", italic = true })

      -- Horizontal rule
      hl(0, "markdownRule", { fg = "#555555" })
    end,
  })
end

return M
