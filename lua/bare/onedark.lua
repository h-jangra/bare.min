local M = {}

local colors = {
  -- Base colors (OneDark inspired)
  base = "#282c34",
  mantle = "#21252b",
  crust = "#1a1e24",

  -- Text colors
  text = "#abb2bf",
  subtext1 = "#828997",
  subtext0 = "#5c6370",

  -- Accent colors (OneDark palette)
  red = "#e06c75",
  dark_red = "#be5046",
  green = "#98c379",
  yellow = "#e5c07b",
  blue = "#61afef",
  purple = "#c678dd",
  cyan = "#56b6c2",
  white = "#dcdfe4",
  black = "#282c34",
  orange = "#d19a66",
  pink = "#e06c75",

  -- UI colors
  comment_grey = "#5c6370",
  gutter_fg_grey = "#4b5263",
  cursor_grey = "#2c323c",
  visual_grey = "#3e4452",
  menu_grey = "#3e4452",
  special_grey = "#3b4048",
  vertsplit = "#3e4452",
}

function M.setup()
  vim.cmd("hi clear")
  if vim.fn.exists("syntax_on") then
    vim.cmd("syntax reset")
  end

  vim.o.background = "dark"
  vim.o.termguicolors = true

  local highlights = {
    -- Core UI
    Normal = { fg = colors.text, bg = colors.base },
    NormalFloat = { fg = colors.text, bg = colors.mantle },
    FloatBorder = { fg = colors.visual_grey, bg = colors.mantle },

    -- Line numbers
    LineNr = { fg = colors.gutter_fg_grey },
    CursorLineNr = { fg = colors.yellow, bold = true },
    CursorLine = { bg = colors.cursor_grey },

    -- Status and tabs
    StatusLine = { fg = colors.text, bg = colors.visual_grey },
    StatusLineNC = { fg = colors.comment_grey, bg = colors.visual_grey },
    TabLine = { fg = colors.comment_grey, bg = colors.visual_grey },
    TabLineSel = { fg = colors.yellow, bg = colors.base, bold = true },

    -- Visual elements
    Visual = { bg = colors.visual_grey },
    Search = { fg = colors.base, bg = colors.yellow },
    IncSearch = { fg = colors.base, bg = colors.orange },
    MatchParen = { fg = colors.cyan, bold = true, underline = true },

    -- Pmenu (completion menu)
    Pmenu = { fg = colors.text, bg = colors.menu_grey },
    PmenuSel = { fg = colors.text, bg = colors.subtext0, bold = true },
    PmenuBorder = { fg = colors.visual_grey, bg = colors.menu_grey },
    PmenuSbar = { bg = colors.cursor_grey },
    PmenuThumb = { bg = colors.comment_grey },

    -- Pmenu kinds and extras
    PmenuKind = { fg = colors.cyan, bg = colors.menu_grey },
    PmenuExtra = { fg = colors.comment_grey, bg = colors.menu_grey, italic = true },
    PmenuMatch = { fg = colors.green, bg = colors.menu_grey, bold = true },

    PmenuKindSel = { fg = colors.cyan, bg = colors.subtext0, bold = true },
    PmenuExtraSel = { fg = colors.base, bg = colors.subtext0, italic = true },
    PmenuMatchSel = { fg = colors.green, bg = colors.subtext0, bold = true },

    -- Syntax
    Comment = { fg = colors.comment_grey, italic = true },
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.orange },
    Boolean = { fg = colors.orange },
    Float = { fg = colors.orange },

    Function = { fg = colors.blue },
    Identifier = { fg = colors.text },
    Keyword = { fg = colors.purple },
    Statement = { fg = colors.purple },
    Conditional = { fg = colors.purple },
    Repeat = { fg = colors.purple },
    Operator = { fg = colors.cyan },

    Type = { fg = colors.yellow },
    StorageClass = { fg = colors.purple },
    Special = { fg = colors.cyan },
    Tag = { fg = colors.orange },
    Delimiter = { fg = colors.text },

    Error = { fg = colors.red },
    Todo = { fg = colors.purple, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.blue },
    DiagnosticHint = { fg = colors.cyan },

    -- Tree-sitter (OneDark style)
    ["@function"] = { fg = colors.blue },
    ["@function.builtin"] = { fg = colors.yellow },
    ["@method"] = { fg = colors.blue },
    ["@constructor"] = { fg = colors.yellow },

    ["@variable"] = { fg = colors.text },
    ["@variable.builtin"] = { fg = colors.orange },
    ["@parameter"] = { fg = colors.orange },
    ["@field"] = { fg = colors.orange },
    ["@property"] = { fg = colors.orange },

    ["@keyword"] = { fg = colors.purple },
    ["@keyword.function"] = { fg = colors.purple },
    ["@conditional"] = { fg = colors.purple },
    ["@repeat"] = { fg = colors.purple },

    ["@string"] = { fg = colors.green },
    ["@string.escape"] = { fg = colors.cyan },
    ["@number"] = { fg = colors.orange },
    ["@boolean"] = { fg = colors.orange },
    ["@constant"] = { fg = colors.orange },
    ["@constant.builtin"] = { fg = colors.orange },

    ["@type"] = { fg = colors.yellow },
    ["@type.builtin"] = { fg = colors.yellow },

    ["@comment"] = { fg = colors.comment_grey, italic = true },
    ["@punctuation.delimiter"] = { fg = colors.text },
    ["@punctuation.bracket"] = { fg = colors.text },

    -- Git
    DiffAdd = { fg = colors.green },
    DiffChange = { fg = colors.yellow },
    DiffDelete = { fg = colors.red },

    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.yellow },
    GitSignsDelete = { fg = colors.red },

    -- UI extras
    VertSplit = { fg = colors.vertsplit },
    WinSeparator = { fg = colors.vertsplit },
    Folded = { fg = colors.comment_grey, bg = colors.mantle },
    SignColumn = { bg = colors.base },

    -- OneDark specific
    SpecialKey = { fg = colors.cyan },
    NonText = { fg = colors.special_grey },
    Whitespace = { fg = colors.special_grey },
    Question = { fg = colors.purple },
    Title = { fg = colors.orange },
  }

  -- Apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
