-- lua/serene/theme.lua
local M = {}

local colors = {
  -- Base (cool blue tones)
  base = "#1a1e2a",
  mantle = "#151822",
  crust = "#10121a",

  -- Text (soft blues and grays)
  text = "#d0d8e8",
  subtext1 = "#b8c2d8",
  subtext0 = "#a0acc8",

  -- Accents (cool, serene palette)
  rosewater = "#e0d4d8",
  flamingo = "#d8ccd0",
  pink = "#d8c8d8",
  mauve = "#a8a0e0",
  red = "#d87a90",
  maroon = "#d090a0",
  peach = "#e0b890",
  yellow = "#e0d890",
  green = "#90d890",
  teal = "#80d8d0",
  sky = "#80d0e8",
  sapphire = "#70c0e8",
  blue = "#80b0f0",
  lavender = "#a8b0f8",

  -- UI (blue-toned surfaces)
  surface0 = "#2a3240",
  surface1 = "#3a4250",
  surface2 = "#4a5260",
  overlay0 = "#586070",
  overlay1 = "#687080",
  overlay2 = "#788090"
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
    FloatBorder = { fg = colors.overlay0, bg = colors.base },

    -- Line numbers
    LineNr = { fg = colors.overlay0 },
    CursorLineNr = { fg = colors.lavender, bold = true },
    CursorLine = { bg = colors.surface0 },

    -- Status and tabs
    StatusLine = { fg = colors.text, bg = colors.surface0 },
    StatusLineNC = { fg = colors.overlay0, bg = colors.surface0 },
    TabLine = { fg = colors.overlay0, bg = colors.surface0 },
    TabLineSel = { fg = colors.lavender, bg = colors.base, bold = true },

    -- Visual elements
    Visual = { bg = colors.surface1 },
    Search = { fg = colors.base, bg = colors.yellow },
    IncSearch = { fg = colors.base, bg = colors.peach },
    MatchParen = { fg = colors.teal, bold = true },

    -- Pmenu (completion menu)
    Pmenu = { fg = colors.text, bg = colors.surface1 },
    PmenuSel = { fg = colors.text, bg = colors.overlay1, bold = true },
    PmenuBorder = { fg = colors.overlay0, bg = colors.surface1 },
    PmenuSbar = { bg = colors.surface0 },
    PmenuThumb = { bg = colors.overlay1 },

    -- Pmenu kinds and extras
    PmenuKind = { fg = colors.teal, bg = colors.surface1 },
    PmenuExtra = { fg = colors.overlay0, bg = colors.surface1, italic = true },
    PmenuMatch = { fg = colors.green, bg = colors.surface1, bold = true },

    PmenuKindSel = { fg = colors.teal, bg = colors.overlay1, bold = true },
    PmenuExtraSel = { fg = colors.subtext0, bg = colors.overlay1, italic = true },
    PmenuMatchSel = { fg = colors.green, bg = colors.overlay1, bold = true },

    Comment = { fg = colors.overlay0, italic = true },
    String = { fg = colors.teal },
    Character = { fg = colors.teal },
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

    Type = { fg = colors.sapphire },
    StorageClass = { fg = colors.mauve },
    Special = { fg = colors.yellow },
    Tag = { fg = colors.peach },
    Delimiter = { fg = colors.subtext0 },

    Error = { fg = colors.red },
    Todo = { fg = colors.mauve, bold = true },

    -- Diagnostics
    DiagnosticError = { fg = colors.red },
    DiagnosticWarn = { fg = colors.yellow },
    DiagnosticInfo = { fg = colors.sapphire },
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

    ["@string"] = { fg = colors.teal },
    ["@string.escape"] = { fg = colors.sky },
    ["@number"] = { fg = colors.peach },
    ["@boolean"] = { fg = colors.peach },
    ["@constant"] = { fg = colors.yellow },
    ["@constant.builtin"] = { fg = colors.peach },

    ["@type"] = { fg = colors.sapphire },
    ["@type.builtin"] = { fg = colors.blue },

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

    -- Special serene touches
    SpecialKey = { fg = colors.sky },
    NonText = { fg = colors.surface0 },
    Whitespace = { fg = colors.surface0 },
  }

  -- Apply highlights
  for group, opts in pairs(highlights) do
    vim.api.nvim_set_hl(0, group, opts)
  end
end

return M
