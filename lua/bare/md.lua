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
      hl(0, "markdownH1", { fg = "#ff6f61", bold = true })
      hl(0, "markdownH2", { fg = "#ffa657", bold = true })
      hl(0, "markdownH3", { fg = "#f0c674", bold = true })
      hl(0, "markdownH4", { fg = "#7fd5b1", bold = true })

      -- Emphasis
      hl(0, "markdownBold", { bold = true, fg = "#ffffff" })
      hl(0, "markdownItalic", { italic = true, fg = "#cfcfcf" })
      hl(0, "markdownBoldItalic", { bold = true, italic = true, fg = "#ffffff" })

      -- Code blocks
      hl(0, "markdownCodeBlock", { fg = "#f8f8f2", bg = "#2c2f3e" })
      hl(0, "markdownCodeDelimiter", { fg = "#8a8fbc" })
      hl(0, "markdownCode", { fg = "#8be9fd", bg = "#2a2d3a" })

      -- Links
      hl(0, "markdownLinkText", { fg = "#61afef", underline = true })
      hl(0, "markdownUrl", { fg = "#52a0ff", underline = true })

      -- Lists
      hl(0, "markdownListMarker", { fg = "#bd93f9" })
      hl(0, "markdownOrderedListMarker", { fg = "#bd93f9" })

      -- Blockquotes
      hl(0, "markdownBlockquote", { fg = "#8b95a9", italic = true })

      -- Horizontal rule
      hl(0, "markdownRule", { fg = "#666666" })
    end,
  })
end

return M
