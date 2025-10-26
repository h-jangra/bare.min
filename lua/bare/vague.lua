-- lua/vague/theme.lua
local M = {}

local colors = {
  -- Base (muted, desaturated)
  base = "#1e1e24",
  mantle = "#19191e",
  crust = "#121216",

  -- Text (soft, low contrast)
  text = "#c8ccd4",
  subtext1 = "#b4b8c0",
  subtext0 = "#9fa3ab",

  -- Accents (muted pastels)
  rosewater = "#e8d8d4",
  flamingo = "#e0d0d0",
  pink = "#e8d0e0",
  mauve = "#c0b0e0",
  red = "#d89ba8",
  maroon = "#d0a8b0",
  peach = "#e0c0a0",
  yellow = "#e0d8b0",
  green = "#b0d8a8",
  teal = "#a8d8d0",
  sky = "#a8d8e8",
  sapphire = "#a0c8e8",
  blue = "#a8c0e8",
  lavender = "#c0c8f0",

  -- UI (subdued)
  surface0 = "#2d2d35",
  surface1 = "#3d3d45",
  surface2 = "#4d4d55",
  overlay0 = "#5a5a65",
  overlay1 = "#6a6a75",
  overlay2 = "#7a7a85"
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
    FloatBorder = { fg = colors.overlay0, bg = colors.mantle },

    -- Line numbers
    LineNr = { fg = colors.overlay0 },
    CursorLineNr = { fg = colors.lavender },
    CursorLine = { bg = colors.surface0 },

    -- Status and tabs
    StatusLine = { fg = colors.text, bg = colors.surface0 },
    StatusLineNC = { fg = colors.overlay0, bg = colors.surface0 },
    TabLine = { fg = colors.overlay0, bg = colors.surface0 },
    TabLineSel = { fg = colors.lavender, bg = colors.base },

    -- Visual elements
    Visual = { bg = colors.surface1 },
    Search = { fg = colors.base, bg = colors.yellow },
    IncSearch = { fg = colors.base, bg = colors.peach },
    MatchParen = { fg = colors.green, bold = true },

    -- Pmenu (completion menu)
    Pmenu = { fg = colors.text, bg = colors.surface1 },
    PmenuSel = { fg = colors.base, bg = colors.overlay1, bold = true },
    PmenuBorder = { fg = colors.overlay0, bg = colors.surface1 },
    PmenuSbar = { bg = colors.surface0 },
    PmenuThumb = { bg = colors.overlay1 },

    -- Pmenu kinds and extras
    PmenuKind = { fg = colors.sky, bg = colors.surface1 },
    PmenuExtra = { fg = colors.overlay0, bg = colors.surface1, italic = true },
    PmenuMatch = { fg = colors.green, bg = colors.surface1, bold = true },

    PmenuKindSel = { fg = colors.sky, bg = colors.overlay1, bold = true },
    PmenuExtraSel = { fg = colors.subtext0, bg = colors.overlay1, italic = true },
    PmenuMatchSel = { fg = colors.green, bg = colors.overlay1, bold = true },

    -- Syntax
    Comment = { fg = colors.overlay0, italic = true },
    String = { fg = colors.green },
    Character = { fg = colors.green },
    Number = { fg = colors.peach },
    Boolean = { fg = colors.peach },
    Float = { fg = colors.peach },

    Function = { fg = colors.blue },
    Identifier = { fg = colors.text },
    Keyword = { fg = colors.mauve },
    Statement = { fg = colors.mauve },
    Conditional = { fg = colors.mauve },
    Repeat = { fg = colors.mauve },
    Operator = { fg = colors.sky },

    Type = { fg = colors.blue },
    StorageClass = { fg = colors.mauve },
    Special = { fg = colors.yellow },
    Tag = { fg = colors.peach },
    Delimiter = { fg = colors.subtext0 },

    Error = { fg = colors.red },
    Todo = { fg = colors.mauve, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.blue },
    DiagnosticHint = { fg = colors.teal },

    -- Tree-sitter
    ["@function"] = { fg = colors.blue },
    ["@function.builtin"] = { fg = colors.lavender },
    ["@method"] = { fg = colors.blue },
    ["@constructor"] = { fg = colors.sapphire },

    ["@variable"] = { fg = colors.text },
    ["@variable.builtin"] = { fg = colors.peach },
    ["@parameter"] = { fg = colors.maroon },
    ["@field"] = { fg = colors.lavender },
    ["@property"] = { fg = colors.lavender },

    ["@keyword"] = { fg = colors.mauve },
    ["@keyword.function"] = { fg = colors.mauve },
    ["@conditional"] = { fg = colors.mauve },
    ["@repeat"] = { fg = colors.mauve },

    ["@string"] = { fg = colors.green },
    ["@string.escape"] = { fg = colors.teal },
    ["@number"] = { fg = colors.peach },
    ["@boolean"] = { fg = colors.peach },
    ["@constant"] = { fg = colors.yellow },
    ["@constant.builtin"] = { fg = colors.peach },

    ["@type"] = { fg = colors.blue },
    ["@type.builtin"] = { fg = colors.sapphire },

    ["@comment"] = { fg = colors.overlay0, italic = true },
    ["@punctuation.delimiter"] = { fg = colors.subtext0 },
    ["@punctuation.bracket"] = { fg = colors.subtext0 },

    -- Git
    DiffAdd = { fg = colors.green },
    DiffChange = { fg = colors.yellow },
    DiffDelete = { fg = colors.red },

    GitSignsAdd = { fg = colors.green },
    GitSignsChange = { fg = colors.yellow },
    GitSignsDelete = { fg = colors.red },

    -- UI extras
    VertSplit = { fg = colors.surface0 },
    WinSeparator = { fg = colors.surface0 },
    Folded = { fg = colors.overlay0, bg = colors.mantle },
    SignColumn = { bg = colors.base },
  }

  -- Apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
