local M = {}

local c = {
  text = "#cdd6f4",
  muted = "#7f849c",

  blue = "#89b4fa",
  green = "#a6e3a1",
  yellow = "#f9e2af",
  mauve = "#cba6f7",
  peach = "#fab387",
  red = "#f38ba8",

  surface0 = "#313244",
  surface1 = "#45475a",
  mantle = "#181825",
}

local function hl(name, opts)
  vim.api.nvim_set_hl(0, name, opts)
end

local function setup_highlights()
  local headings = {
    markdownH1 = c.red,
    markdownH2 = c.peach,
    markdownH3 = c.yellow,
    markdownH4 = c.green,
    markdownH5 = c.blue,
    markdownH6 = c.mauve,
  }

  for group, color in pairs(headings) do
    hl(group, {
      fg = color,
      bold = true,
    })
  end

  hl("markdownHeadingDelimiter", { fg = c.muted, bold = true, })
  hl("markdownBold", { bold = true, fg = c.text, })
  hl("markdownItalic", { italic = true, fg = c.text, })
  hl("markdownBoldItalic", { bold = true, italic = true, fg = c.text, })
  hl("markdownCode", { fg = c.green, bg = c.surface0, })
  hl("markdownCodeBlock", { bg = c.mantle, })
  hl("markdownCodeDelimiter", { fg = c.muted, })
  hl("markdownBlockquote", { fg = c.muted, italic = true, })
  hl("markdownListMarker", { fg = c.blue, bold = true, })
  hl("markdownOrderedListMarker", { fg = c.peach, bold = true, })
  hl("markdownRule", { fg = c.surface1, })
  hl("markdownLinkText", { fg = c.blue, underline = true, })
  hl("markdownUrl", { fg = c.green, underline = true, })
  hl("@markup.raw.markdown_inline", { link = "markdownCode", })
  hl("@markup.link.markdown_inline", { link = "markdownLinkText", })
end

function M.setup()
  vim.g.markdown_fenced_languages = { "bash=sh", "c", "cpp", "css", "go", "html",
    "java", "javascript", "json", "lua", "python", "rust", "sql", "toml", "typescript",
    "typst", "vim", "yaml", }

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = vim.api.nvim_create_augroup("MiniMarkdown", { clear = true }),
    callback = function()
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.breakindent = true
      vim.opt_local.showbreak = "↪ "

      vim.opt_local.conceallevel = 2
      vim.opt_local.concealcursor = "nc"

      setup_highlights()
    end,
  })
end

return M
