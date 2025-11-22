local M = {}

local colors = {
  text = "#cdd6f4",
  subtext1 = "#bac2de",
  overlay0 = "#6c7086",
  overlay2 = "#9399b2",
  surface0 = "#313244",
  surface1 = "#45475a",
  surface2 = "#585b70",
  mantle = "#181825",
  peach = "#fab387",
  blue = "#89b4fa",
  green = "#a6e3a1",
  yellow = "#f9e2af",
  mauve = "#cba6f7",
  teal = "#94e2d5",
  sky = "#89dceb",
  sapphire = "#74c7ec",
  lavender = "#b4befe",
  red = "#f38ba8",
  flamingo = "#f2cdcd",
  pink = "#f5c2e7",
  maroon = "#eba0ac",
}

local function setup_highlights()
  local hl = vim.api.nvim_set_hl

  local headings = {
    { "markdownH1", colors.peach,  { bold = true, underline = true } },
    { "markdownH2", colors.blue,   { bold = true } },
    { "markdownH3", colors.green,  { bold = true } },
    { "markdownH4", colors.yellow, { bold = true } },
    { "markdownH5", colors.mauve,  { bold = true } },
    { "markdownH6", colors.teal,   { bold = true } },
  }

  for _, heading in ipairs(headings) do
    hl(0, heading[1], { fg = heading[2], bold = heading[3].bold, underline = heading[3].underline })
  end

  local styles = {
    markdownBold = { fg = colors.text, bold = true },
    markdownItalic = { fg = colors.lavender, italic = true },
    markdownBoldItalic = { fg = colors.pink, bold = true, italic = true },
    markdownStrike = { fg = colors.overlay0, strikethrough = true },
    markdownCode = { fg = colors.sapphire, bg = colors.surface0, italic = true },
    markdownCodeDelimiter = { fg = colors.overlay2, bold = true },
    markdownCodeBlock = { fg = colors.text, bg = colors.mantle },
    markdownInlineCode = { fg = colors.peach, bg = colors.surface0 },
    markdownLinkText = { fg = colors.blue, underline = true },
    markdownUrl = { fg = colors.sapphire, underline = true },
    markdownId = { fg = colors.teal },
    markdownIdDeclaration = { fg = colors.green, bold = true },
    markdownListMarker = { fg = colors.mauve, bold = true },
    markdownOrderedListMarker = { fg = colors.yellow, bold = true },
    markdownRule = { fg = colors.surface2, bold = true },
    markdownHeadingRule = { fg = colors.blue, bold = true },
    markdownBlockquote = { fg = colors.overlay2, bg = colors.mantle, italic = true },
    markdownTable = { fg = colors.text, bg = colors.surface0 },
    markdownTableHead = { fg = colors.blue, bold = true, bg = colors.surface1 },
    markdownTableDelimiter = { fg = colors.overlay2, bold = true },
  }

  for name, opts in pairs(styles) do
    hl(0, name, opts)
  end

  hl(0, "@text.literal.markdown", { link = "markdownCode" })
  hl(0, "@text.uri.markdown", { link = "markdownUrl" })
  hl(0, "@text.reference.markdown", { link = "markdownLinkText" })
  hl(0, "@text.title.markdown", { link = "markdownH1" })
end

function M.setup()
  vim.g.markdown_fenced_languages = {
    "html", "python", "typst", "bash=sh", "lua", "javascript",
    "typescript", "json", "yaml", "go", "cpp", "c", "java",
    "rust", "toml", "css", "sql", "vim"
  }

  vim.api.nvim_create_autocmd("FileType", {
    pattern = "markdown",
    group = vim.api.nvim_create_augroup("MiniMarkdown", { clear = true }),
    callback = function()
      vim.opt_local.conceallevel = 2
      vim.opt_local.concealcursor = "nc"
      vim.opt_local.wrap = true
      vim.opt_local.linebreak = true
      vim.opt_local.breakindent = true
      vim.opt_local.showbreak = "↪ "
      -- vim.opt_local.spell = true
      -- vim.opt_local.spelllang = "en"
      setup_highlights()
    end,
  })

  vim.keymap.set('n', '<leader>bh', function()
    local orig = vim.fn.expand('%')
    local html = vim.fn.expand('%:r') .. '.html'
    vim.cmd('TOhtml | w! ' .. html .. ' | bd! | e ' .. orig)
    vim.notify('Blog HTML: ' .. html, vim.log.levels.INFO)
  end, { desc = "Convert to blog HTML" })
end

return M
